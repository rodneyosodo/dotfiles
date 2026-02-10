#!/usr/bin/env python3
"""
Collect `go install` / `cargo install` commands from shell histories and
atuin, then surgically update the ansible.builtin.shell block in the
corresponding playbook YAML file.

Usage:
    python3 scripts/export_packages.py go    playbooks/go.yaml
    python3 scripts/export_packages.py cargo playbooks/rust.yaml
"""

import re
import subprocess
import sys
from pathlib import Path


def _atuin(prefix: str) -> list[str]:
    try:
        out = subprocess.check_output(
            ["atuin", "search", prefix],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []
    lines = []
    for line in out.splitlines():
        parts = line.split("\t", 2)
        if len(parts) >= 2:
            lines.append(parts[1])
    return lines


def _zsh_history(prefix: str) -> list[str]:
    path = Path.home() / ".zsh_history"
    if not path.exists():
        return []
    lines = []
    for raw in path.read_text(errors="replace").splitlines():
        # strip zsh extended_history timestamp prefix  `: 1234567890:0;`
        cmd = re.sub(r"^:[^;]*;", "", raw)
        # find the first occurrence of the prefix command in the line
        idx = cmd.find(prefix)
        if idx != -1:
            lines.append(cmd[idx:])
    return lines


def _bash_history(prefix: str) -> list[str]:
    path = Path.home() / ".bash_history"
    if not path.exists():
        return []
    return [
        l for l in path.read_text(errors="replace").splitlines() if l.startswith(prefix)
    ]


def _existing_yaml(yaml_path: Path, prefix: str) -> list[str]:
    if not yaml_path.exists():
        return []
    return [
        l.strip()
        for l in yaml_path.read_text().splitlines()
        if l.strip().startswith(prefix)
    ]


def collect_raw(prefix: str, yaml_path: Path) -> list[str]:
    raw: list[str] = []
    raw += _existing_yaml(yaml_path, prefix)
    raw += _atuin(prefix)
    raw += _zsh_history(prefix)
    raw += _bash_history(prefix)
    cleaned = []
    for line in raw:
        line = line.rstrip("\\").rstrip().strip('"')
        if line.startswith(prefix):
            cleaned.append(line)
    return cleaned


_GO_HOST_RE = re.compile(r"^[a-zA-Z0-9_-]+\.[a-zA-Z]")


def parse_go_install(line: str) -> str | None:
    """
    Normalise a `go install` line to `@latest`, preserve flags like -tags.
    Returns None if the line doesn't look like a valid Go module install.
    """
    parts = line.split()
    # parts[0]='go', parts[1]='install', parts[2..n-1]=flags, parts[n]=pkg
    if len(parts) < 3:
        return None
    pkg = parts[-1]
    if not _GO_HOST_RE.match(pkg):
        return None
    # normalise version
    pkg = re.sub(r"@[^@]+$", "@latest", pkg)
    # collect flags (everything between 'install' and the package)
    flags: list[str] = []
    i = 2
    while i < len(parts) - 1:
        if parts[i].startswith("-"):
            flags.append(parts[i])
            # include the flag value if next token isn't a flag or a module path
            if (
                i + 1 < len(parts) - 1
                and not parts[i + 1].startswith("-")
                and not _GO_HOST_RE.match(parts[i + 1])
            ):
                i += 1
                flags.append(parts[i])
        i += 1
    flag_str = (" " + " ".join(flags)) if flags else ""
    return f"go install{flag_str} {pkg}"


def collect_go(yaml_path: Path) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for raw in collect_raw("go install", yaml_path):
        parsed = parse_go_install(raw)
        if parsed and parsed not in seen:
            seen.add(parsed)
            result.append(parsed)
    return sorted(result)


def parse_cargo_install(line: str) -> list[dict]:
    """
    Parse a `cargo install` line into a list of canonical install descriptors:
      {'type': 'git',    'url': ..., 'bin': ...}
      {'type': 'locked', 'pkg': ...}
      {'type': 'force',  'pkg': ...}
    Multi-package lines (e.g. `cargo install a b c --force`) are expanded.
    """
    parts = line.split()
    if len(parts) < 3:
        return []

    git_url = ""
    git_bin = ""
    locked = False
    pkgs: list[str] = []

    i = 2
    while i < len(parts):
        t = parts[i]
        if t == "--git" and i + 1 < len(parts):
            git_url = parts[i + 1]
            i += 2
            if i < len(parts) and not parts[i].startswith("-"):
                git_bin = parts[i]
                i += 1
        elif t == "--locked":
            locked = True
            i += 1
        elif t.startswith("-"):
            i += 1
            # skip flag value
            if i < len(parts) and not parts[i].startswith("-"):
                i += 1
        else:
            pkgs.append(t)
            i += 1

    if git_url:
        return [{"type": "git", "url": git_url, "bin": git_bin}]

    results = []
    for pkg in pkgs:
        if not pkg or pkg == "install":
            continue
        results.append({"type": "locked" if locked else "force", "pkg": pkg})
    return results


def collect_cargo(yaml_path: Path) -> list[str]:
    # keyed by package name; locked > force > plain
    force: dict[str, bool] = {}  # pkg -> True
    locked: set[str] = set()
    git: set[str] = set()

    for raw in collect_raw("cargo install", yaml_path):
        if "--list" in raw:
            continue
        for item in parse_cargo_install(raw):
            if item["type"] == "git":
                entry = f"cargo install --git {item['url']}"
                if item["bin"]:
                    entry += f" {item['bin']}"
                git.add(entry)
            elif item["type"] == "locked":
                locked.add(item["pkg"])
                force.pop(item["pkg"], None)
            elif item["type"] == "force":
                if item["pkg"] not in locked:
                    force[item["pkg"]] = True

    result: list[str] = []
    result += sorted(git)
    result += [f"cargo install --locked {p}" for p in sorted(locked)]
    result += [f"cargo install --force {p}" for p in sorted(force)]
    return result


def update_yaml(yaml_path: Path, task_name: str, new_lines: list[str]) -> None:
    text = yaml_path.read_text()
    indent = "        "
    new_body = "".join(f"{indent}{l}\n" for l in new_lines)

    pattern_block = (
        rf"(?m)(    - name: {re.escape(task_name)}\n"
        rf"      ansible\.builtin\.shell: \|\n)"
        rf"((?:{indent}[^\n]*\n)*)"
    )
    # Match dict form:  ansible.builtin.shell:\n        cmd: ...\n        executable: ...
    pattern_dict = (
        rf"(?m)(    - name: {re.escape(task_name)}\n)"
        rf"      ansible\.builtin\.shell:\n"
        rf"        cmd:.*\n"
        rf"        executable: /bin/bash\n"
    )

    if re.search(pattern_block, text):
        result = re.sub(pattern_block, lambda m: m.group(1) + new_body, text)
    elif re.search(pattern_dict, text):
        result = re.sub(
            pattern_dict,
            lambda m: (
                m.group(1)
                + "      ansible.builtin.shell: |\n"
                + new_body
                + "      args:\n        executable: /bin/bash\n"
            ),
            text,
        )
    else:
        print(
            f"ERROR: could not find task '{task_name}' in {yaml_path}", file=sys.stderr
        )
        sys.exit(1)

    yaml_path.write_text(result)


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <go|cargo> <yaml_path>", file=sys.stderr)
        sys.exit(1)

    mode = sys.argv[1]
    yaml_path = Path(sys.argv[2])

    if mode == "go":
        print(
            "Collecting go install commands from atuin, zsh_history and bash_history..."
        )
        lines = collect_go(yaml_path)
        update_yaml(yaml_path, "Install Golang Tools", lines)
    elif mode == "cargo":
        print(
            "Collecting cargo install commands from atuin, zsh_history and bash_history..."
        )
        lines = collect_cargo(yaml_path)
        update_yaml(yaml_path, "Install Cargo Tools", lines)
    else:
        print(f"Unknown mode: {mode}", file=sys.stderr)
        sys.exit(1)

    print(f"Written to {yaml_path}")


if __name__ == "__main__":
    main()
