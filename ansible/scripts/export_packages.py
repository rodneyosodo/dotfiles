#!/usr/bin/env python3
"""
Collect `go install` / `cargo install` commands from shell histories and
atuin, merge them with the playbook's current list, and rewrite that list.

Usage:
    python3 scripts/export_packages.py go    playbooks/go.yaml
    python3 scripts/export_packages.py cargo playbooks/rust.yaml

The playbooks keep their tools in a vars list (`go_tools`, `cargo_tools`)
installed by a looped task, so only that list is rewritten. Every entry is
validated: history lines are free text, and anything after a shell operator
(`;`, `&&`, `|`, ...) or that isn't a plain crate name, module path or https
git URL is dropped rather than written into a playbook.
"""

import re
import shlex
import subprocess
import sys
from pathlib import Path

# ---- history sources ----


def _atuin(prefix: str) -> list[str]:
    try:
        out = subprocess.check_output(
            ["atuin", "search", "--format", "{command}", prefix],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []
    return out.splitlines()


def _zsh_history(prefix: str) -> list[str]:
    path = Path.home() / ".zsh_history"
    if not path.exists():
        return []
    lines = []
    for raw in path.read_text(errors="replace").splitlines():
        # strip zsh extended_history timestamp prefix  `: 1234567890:0;`
        cmd = re.sub(r"^:[^;]*;", "", raw)
        idx = cmd.find(prefix)
        if idx != -1:
            lines.append(cmd[idx:])
    return lines


def _bash_history(prefix: str) -> list[str]:
    path = Path.home() / ".bash_history"
    if not path.exists():
        return []
    return [
        l for l in path.read_text(errors="replace").splitlines() if prefix in l
    ]


def history(prefix: str) -> list[str]:
    lines = _atuin(prefix) + _zsh_history(prefix) + _bash_history(prefix)
    out = []
    for line in lines:
        idx = line.find(prefix)
        if idx != -1:
            out.append(line[idx:].rstrip("\\").strip())
    return out


# ---- tokenising ----

SHELL_STOP = {";", "&&", "||", "|", "&", ">", ">>", "<", "2>", "2>&1", "#"}


def tokens(line: str) -> list[str]:
    """Words of the first command on the line, quotes resolved."""
    try:
        lexer = shlex.shlex(line, posix=True, punctuation_chars=";&|<>")
        lexer.whitespace_split = True
        lexer.commenters = "#"
        words = list(lexer)
    except ValueError:  # unbalanced quotes
        return []
    out = []
    for w in words:
        if w in SHELL_STOP or w.startswith(("$", "`")):
            break
        out.append(w)
    return out


# ---- cargo ----

CRATE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$")
GIT_URL_RE = re.compile(r"^https://[A-Za-z0-9.-]+(/[A-Za-z0-9._~-]+)+?(\.git)?$")

# Flags that take a value; the next word is that value, not a crate.
CARGO_VALUE_FLAGS = {
    "--version", "--vers", "--git", "--branch", "--tag", "--rev", "--path",
    "--root", "--index", "--registry", "--features", "-F", "--bin",
    "--example", "--profile", "--target", "--target-dir", "--jobs", "-j",
    "--config", "-Z", "--color", "--message-format",
}

# Crates that turned out not to be tools: `rustc` doesn't exist on crates.io,
# and `dua` is an unrelated crate whose `dua` binary clashes with dua-cli's.
# amdgpu_top comes from the official repos (amd.yaml) instead.
CARGO_EXCLUDE = {"rustc", "dua", "amdgpu_top"}


def parse_cargo(line: str) -> list[str]:
    """Playbook entries (`crate` or `--git URL crate`) from one command."""
    words = tokens(line)
    if words[:2] != ["cargo", "install"]:
        return []
    git, crates = "", []
    i = 2
    while i < len(words):
        w = words[i]
        if "=" in w and w.startswith("--"):
            flag, _, value = w.partition("=")
            if flag == "--git":
                git = value
            i += 1
        elif w in CARGO_VALUE_FLAGS:
            if w == "--git" and i + 1 < len(words):
                git = words[i + 1]
            i += 2
        elif w.startswith("-"):
            i += 1  # boolean flag: --force, --locked, ...
        else:
            crates.append(w)
            i += 1

    if any(c in ("--list", "--help") for c in words):
        return []
    if git:
        if not GIT_URL_RE.match(git):
            return []
        # A git source names at most one crate; without one cargo picks the
        # only crate in the repo.
        crate = crates[0] if crates and CRATE_RE.match(crates[0]) else ""
        git = re.sub(r"(\.git)?/?$", "", git)
        return [f"--git {git} {crate}".strip()]
    return [c for c in crates if CRATE_RE.match(c) and c not in CARGO_EXCLUDE]


# ---- go ----

MODULE_RE = re.compile(r"^[a-z0-9.-]+\.[a-z]{2,}(/[A-Za-z0-9._~-]+)*@[A-Za-z0-9._+-]+$")
GO_FLAG_RE = re.compile(r"^-[a-z]+(=[A-Za-z0-9._,=/ -]*)?$")
GO_VALUE_FLAGS = {"-ldflags", "-tags", "-gcflags", "-asmflags", "-mod", "-modfile", "-o"}
SAFE_VALUE_RE = re.compile(r"^[A-Za-z0-9._,=/ -]*$")
GO_NOISE_FLAGS = {"-v", "-x", "-n", "-a", "-work"}


def parse_go(line: str) -> list[str]:
    words = tokens(line)
    if words[:2] != ["go", "install"] or len(words) < 3:
        return []
    module = words[-1]
    if "@" not in module:
        module += "@latest"
    module = re.sub(r"@[^@]+$", "@latest", module)
    if not MODULE_RE.match(module):
        return []
    flags: list[str] = []
    i = 2
    while i < len(words) - 1:
        w = words[i]
        if w in GO_VALUE_FLAGS and i + 1 < len(words) - 1:
            value = words[i + 1]
            if not SAFE_VALUE_RE.match(value):
                return []
            flags.append(f'{w} "{value}"' if " " in value else f"{w} {value}")
            i += 2
        elif w in GO_NOISE_FLAGS:
            i += 1  # verbosity: not part of what gets installed
        elif GO_FLAG_RE.match(w):
            flags.append(w)
            i += 1
        else:
            return []  # not a single module install
    return [" ".join(flags + [module])]


# ---- playbook list ----


def list_block(text: str, var: str) -> re.Match:
    m = re.search(rf"(?m)^([ ]*){re.escape(var)}:\n((?:\1  (?:#.*|- .*)\n)*)", text)
    if not m:
        print(f"ERROR: could not find the `{var}:` list", file=sys.stderr)
        sys.exit(1)
    return m


def yaml_item(raw: str) -> str:
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "'\"":
        return raw[1:-1]
    return raw


def yaml_scalar(entry: str) -> str:
    if re.match(r"^[A-Za-z0-9][A-Za-z0-9._/@-]*$", entry):
        return entry
    if "'" not in entry:
        return f"'{entry}'"
    return '"' + entry.replace("\\", "\\\\").replace('"', '\\"') + '"'


def update(yaml_path: Path, var: str, parse, prefix: str) -> None:
    text = yaml_path.read_text()
    m = list_block(text, var)
    indent = m.group(1) + "  "
    current = [
        yaml_item(l.strip()[2:])
        for l in m.group(2).splitlines()
        if l.strip().startswith("- ")
    ]
    comments = [l for l in m.group(2).splitlines() if l.strip().startswith("#")]

    # One entry per tool: keyed by git URL or module path (the last word for
    # go, the source for cargo git entries), so the same tool seen with and
    # without a crate name or flags is listed once. The playbook's current
    # entry wins; otherwise the most specific (longest) one.
    def key(entry: str) -> str:
        if entry.startswith("--git "):
            return entry.split()[1]
        return entry.split()[-1]

    chosen: dict[str, str] = {}
    for entry in current:
        chosen.setdefault(key(entry), entry)
    pinned = set(chosen)
    for line in history(prefix):
        for entry in parse(line):
            k = key(entry)
            if k in pinned:
                continue
            if len(entry) > len(chosen.get(k, "")):
                chosen[k] = entry

    # git sources first, then by name.
    ordered = sorted(chosen.values(), key=lambda e: (not e.startswith("--git"), e.lower()))
    body = "".join(f"{l}\n" for l in comments)
    body += "".join(f"{indent}- {yaml_scalar(e)}\n" for e in ordered)
    yaml_path.write_text(text[: m.start(2)] + body + text[m.end(2):])

    added = sorted(set(ordered) - set(current))
    print(f"{len(ordered)} entries in {yaml_path} ({len(added)} new)")
    for e in added:
        print(f"  + {e}")


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <go|cargo> <yaml_path>", file=sys.stderr)
        sys.exit(1)
    mode, yaml_path = sys.argv[1], Path(sys.argv[2])
    if mode == "go":
        update(yaml_path, "go_tools", parse_go, "go install")
    elif mode == "cargo":
        update(yaml_path, "cargo_tools", parse_cargo, "cargo install")
    else:
        print(f"Unknown mode: {mode}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
