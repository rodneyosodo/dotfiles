#!/usr/bin/env python3
"""Fetch iCalendar feeds and print their events as JSON for the clock popup.

Read-only and standard library only. Feeds are listed in
~/.config/quickshell-calendars.json (outside the dotfiles, because a private
iCal address is a credential):

    [
      { "name": "Personal", "url": "https://calendar.google.com/...basic.ics",
        "color": "#89b4fa", "enabled": true }
    ]

`url` may be https://, webcal:// or a local file path. Prints:

    { "updated": "...", "configured": N,
      "feeds": [{ "name", "color", "ok", "error", "count" }],
      "events": [{ "calendar", "color", "title", "start", "end", "allDay",
                   "location", "link" }] }

Times are local wall-clock "YYYY-MM-DDTHH:MM"; all-day events use
"YYYY-MM-DD" with an exclusive end. A feed that fails to download falls back
to the events it last returned, kept in ~/.cache/quickshell/calendar.json.

Recurrence covers what calendar apps write in practice: FREQ DAILY, WEEKLY,
MONTHLY and YEARLY with INTERVAL, COUNT, UNTIL, BYDAY (with ordinals),
BYMONTHDAY, BYMONTH, BYSETPOS and WKST, plus RDATE, EXDATE and edited
instances (RECURRENCE-ID).
"""

import datetime as dt
import hashlib
import json
import os
import re
import sys
import tempfile
import urllib.error
import urllib.request
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

CONFIG = os.path.expanduser(
    os.environ.get("QS_CALENDARS", "~/.config/quickshell-calendars.json"))
CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "quickshell", "calendar.json")

MAX_BYTES = 20 * 1024 * 1024
TIMEOUT = 20
PAST_DAYS = 62
FUTURE_DAYS = 400
MAX_SPAN_DAYS = 366 * 30  # how far a rule is walked from its start

WEEKDAYS = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
UTC = dt.timezone.utc

MEETING = re.compile(
    r"https://(?:meet\.google\.com/[a-z0-9-]+"
    r"|[\w.-]*zoom\.us/(?:j|my|w)/[^\s\"'<>\\]+"
    r"|teams\.microsoft\.com/l/meetup-join/[^\s\"'<>\\]+"
    r"|teams\.live\.com/meet/[^\s\"'<>\\]+)",
    re.IGNORECASE)


def local_zone():
    try:
        target = os.path.realpath("/etc/localtime")
        if "zoneinfo/" in target:
            return ZoneInfo(target.split("zoneinfo/", 1)[1])
    except (OSError, ZoneInfoNotFoundError, ValueError):
        pass
    return dt.datetime.now().astimezone().tzinfo


LOCAL = local_zone()


# ---- iCalendar reading ----

def unfold(text):
    lines = []
    for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines


def split_unquoted(text, sep):
    parts, current, quoted = [], [], False
    for ch in text:
        if ch == '"':
            quoted = not quoted
        if ch == sep and not quoted:
            parts.append("".join(current))
            current = []
        else:
            current.append(ch)
    parts.append("".join(current))
    return parts


def parse_line(line):
    quoted = False
    for i, ch in enumerate(line):
        if ch == '"':
            quoted = not quoted
        elif ch == ":" and not quoted:
            head, value = line[:i], line[i + 1:]
            break
    else:
        return None
    parts = split_unquoted(head, ";")
    params = {}
    for p in parts[1:]:
        key, _, val = p.partition("=")
        params[key.upper()] = val.strip('"')
    return parts[0].upper(), params, value


def unescape(value):
    out, i = [], 0
    while i < len(value):
        ch = value[i]
        if ch == "\\" and i + 1 < len(value):
            nxt = value[i + 1]
            out.append("\n" if nxt in "nN" else nxt)
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def read_events(text):
    """VEVENTs as dicts of NAME -> list of (params, value)."""
    events, current, depth = [], None, 0
    for line in unfold(text):
        parsed = parse_line(line)
        if not parsed:
            continue
        name, params, value = parsed
        if name == "BEGIN":
            if value.upper() == "VEVENT" and current is None:
                current, depth = {}, 0
            elif current is not None:
                depth += 1  # VALARM and friends
            continue
        if name == "END":
            if current is not None:
                if depth:
                    depth -= 1
                elif value.upper() == "VEVENT":
                    events.append(current)
                    current = None
            continue
        if current is not None and not depth:
            current.setdefault(name, []).append((params, value))
    return events


def first(event, name, default=""):
    values = event.get(name)
    return values[0][1] if values else default


def first_params(event, name):
    values = event.get(name)
    return values[0][0] if values else {}


# ---- dates ----

def zone_for(tzid):
    if not tzid:
        return LOCAL  # floating time: the reader's own clock
    candidates = [tzid, tzid.strip("/")]
    m = re.search(r"([A-Za-z]+/[A-Za-z_+-]+(?:/[A-Za-z_+-]+)?)$", tzid)
    if m:
        candidates.append(m.group(1))
    for c in candidates:
        try:
            return ZoneInfo(c)
        except (ZoneInfoNotFoundError, ValueError):
            continue
    return LOCAL


def parse_when(value, params):
    """A date (all day) or an aware datetime, or None."""
    value = value.strip()
    m = re.fullmatch(r"(\d{4})(\d\d)(\d\d)", value)
    if m:
        return dt.date(*map(int, m.groups()))
    m = re.fullmatch(r"(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z?)", value)
    if not m:
        return None
    naive = dt.datetime(*map(int, m.groups()[:6]))
    tz = UTC if m.group(7) else zone_for(params.get("TZID"))
    return naive.replace(tzinfo=tz)


def parse_duration(value):
    m = re.fullmatch(
        r"([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?",
        value.strip())
    if not m:
        return None
    sign = -1 if m.group(1) == "-" else 1
    w, d, h, mi, s = (int(x or 0) for x in m.groups()[1:])
    return sign * dt.timedelta(weeks=w, days=d, hours=h, minutes=mi, seconds=s)


def is_all_day(when):
    return not isinstance(when, dt.datetime)


def day_of(when):
    return when if is_all_day(when) else when.date()


def identity(when):
    """Comparable key for matching EXDATE and RECURRENCE-ID to instances."""
    if is_all_day(when):
        return when.isoformat()
    return when.astimezone(UTC).strftime("%Y%m%dT%H%M%S")


def at_day(start, day):
    """`start`'s wall-clock time, on another day, in its own zone."""
    if is_all_day(start):
        return day
    return dt.datetime.combine(day, start.time().replace(tzinfo=None), tzinfo=start.tzinfo)


def days_in_month(year, month):
    nxt = dt.date(year + (month == 12), month % 12 + 1, 1)
    return (nxt - dt.date(year, month, 1)).days


# ---- recurrence ----

def parse_rule(value):
    rule = {}
    for part in value.split(";"):
        key, _, val = part.partition("=")
        if key:
            rule[key.upper()] = val.upper()
    return rule


def ints(value):
    out = []
    for p in (value or "").split(","):
        try:
            out.append(int(p))
        except ValueError:
            pass
    return out


def bydays(value):
    out = []
    for p in (value or "").split(","):
        m = re.fullmatch(r"([+-]?\d+)?(MO|TU|WE|TH|FR|SA|SU)", p.strip())
        if m:
            out.append((int(m.group(1)) if m.group(1) else None, WEEKDAYS.index(m.group(2))))
    return out


def monthday_ok(day, wanted):
    last = days_in_month(day.year, day.month)
    return any(day.day == (n if n > 0 else last + n + 1) for n in wanted)


def weekday_in_month_ok(day, wanted):
    last = days_in_month(day.year, day.month)
    for ordinal, weekday in wanted:
        if day.weekday() != weekday:
            continue
        if ordinal is None:
            return True
        if ordinal > 0 and (day.day - 1) // 7 + 1 == ordinal:
            return True
        if ordinal < 0 and (last - day.day) // 7 + 1 == -ordinal:
            return True
    return False


def make_matcher(rule, start_day):
    freq = rule.get("FREQ")
    interval = max(1, (ints(rule.get("INTERVAL")) or [1])[0])
    months = ints(rule.get("BYMONTH"))
    mdays = ints(rule.get("BYMONTHDAY"))
    wdays = bydays(rule.get("BYDAY"))
    plain_wdays = {w for _, w in wdays}
    setpos = ints(rule.get("BYSETPOS"))
    wkst = WEEKDAYS.index(rule.get("WKST")) if rule.get("WKST") in WEEKDAYS else 0

    def week_start(d):
        return d - dt.timedelta(days=(d.weekday() - wkst) % 7)

    def base(day):
        if months and day.month not in months:
            return False
        if freq == "DAILY":
            if (day - start_day).days % interval:
                return False
            if wdays and day.weekday() not in plain_wdays:
                return False
            return not mdays or monthday_ok(day, mdays)
        if freq == "WEEKLY":
            if ((week_start(day) - week_start(start_day)).days // 7) % interval:
                return False
            return day.weekday() in (plain_wdays or {start_day.weekday()})
        if freq == "MONTHLY":
            span = (day.year - start_day.year) * 12 + day.month - start_day.month
            if span % interval:
                return False
            if mdays:
                return monthday_ok(day, mdays) and (not wdays or day.weekday() in plain_wdays)
            if wdays:
                return weekday_in_month_ok(day, wdays)
            return day.day == start_day.day
        if freq == "YEARLY":
            if (day.year - start_day.year) % interval:
                return False
            if not months and day.month != start_day.month:
                return False
            if mdays:
                return monthday_ok(day, mdays)
            if wdays:
                return weekday_in_month_ok(day, wdays)
            return day.day == start_day.day
        return False

    if not setpos or freq not in ("MONTHLY", "YEARLY"):
        return base

    # BYSETPOS picks from each month's (or year's) candidates, e.g. the last
    # weekday of the month.
    cache = {}

    def chosen(day):
        key = (day.year, day.month) if freq == "MONTHLY" else day.year
        if key not in cache:
            if freq == "MONTHLY":
                first_day = dt.date(day.year, day.month, 1)
                count = days_in_month(day.year, day.month)
            else:
                first_day = dt.date(day.year, 1, 1)
                count = (dt.date(day.year + 1, 1, 1) - first_day).days
            candidates = [first_day + dt.timedelta(days=i) for i in range(count)]
            candidates = [d for d in candidates if base(d)]
            picked = set()
            for pos in setpos:
                index = pos - 1 if pos > 0 else len(candidates) + pos
                if 0 <= index < len(candidates):
                    picked.add(candidates[index])
            cache[key] = picked
        return day in cache[key]

    return chosen


def occurrences(start, rule, window_end):
    """Instance starts of a recurring event, in order, up to window_end."""
    start_day = day_of(start)
    matches = make_matcher(rule, start_day)
    count = (ints(rule.get("COUNT")) or [None])[0]

    until = None
    if rule.get("UNTIL"):
        until = parse_when(rule["UNTIL"], {})
        if until is not None and not is_all_day(until) and is_all_day(start):
            until = until.date()
        elif until is not None and is_all_day(until) and not is_all_day(start):
            until = dt.datetime.combine(until, dt.time(23, 59, 59), tzinfo=start.tzinfo)

    last_day = min(window_end, start_day + dt.timedelta(days=MAX_SPAN_DAYS))
    day, found = start_day, 0
    while day <= last_day:
        if day == start_day or matches(day):
            when = at_day(start, day)
            if until is not None and when > until:
                break
            yield when
            found += 1
            if count is not None and found >= count:
                break
        day += dt.timedelta(days=1)


# ---- events ----

def describe(event):
    text = " ".join(
        unescape(first(event, n)) for n in ("X-GOOGLE-CONFERENCE", "LOCATION", "URL", "DESCRIPTION"))
    m = MEETING.search(text)
    return m.group(0) if m else ""


def instance(event, start, end, feed):
    return {
        "calendar": feed["name"],
        "color": feed["color"],
        "title": unescape(first(event, "SUMMARY")).strip() or "(no title)",
        "start": start,
        "end": end,
        "location": unescape(first(event, "LOCATION")).strip(),
        "link": describe(event),
    }


def to_output(item, start, end):
    if is_all_day(start):
        item["allDay"] = True
        item["start"] = start.isoformat()
        item["end"] = (end if end > start else start + dt.timedelta(days=1)).isoformat()
    else:
        item["allDay"] = False
        item["start"] = start.astimezone(LOCAL).strftime("%Y-%m-%dT%H:%M")
        item["end"] = max(end, start).astimezone(LOCAL).strftime("%Y-%m-%dT%H:%M")
    return item


def span(event):
    start = parse_when(first(event, "DTSTART"), first_params(event, "DTSTART"))
    if start is None:
        return None, None
    end = None
    if event.get("DTEND"):
        end = parse_when(first(event, "DTEND"), first_params(event, "DTEND"))
    if end is None and event.get("DURATION"):
        duration = parse_duration(first(event, "DURATION"))
        if duration is not None:
            end = start + duration
    if end is None or type(end) is not type(start):
        end = start + dt.timedelta(days=1) if is_all_day(start) else start
    return start, end


def overlaps(start, end, window_start, window_end):
    first_day = day_of(start)
    last_day = day_of(end)
    return last_day >= window_start and first_day <= window_end


def expand(events, feed, window_start, window_end):
    out = []
    # Edited instances, by series UID and the start they replace.
    edits = {}
    for ev in events:
        if ev.get("RECURRENCE-ID"):
            rid = parse_when(first(ev, "RECURRENCE-ID"), first_params(ev, "RECURRENCE-ID"))
            if rid is not None:
                edits.setdefault(first(ev, "UID"), {})[identity(rid)] = ev

    for ev in events:
        if ev.get("RECURRENCE-ID"):
            continue
        start, end = span(ev)
        if start is None:
            continue
        cancelled = first(ev, "STATUS").upper() == "CANCELLED"
        rule = first(ev, "RRULE")

        if not rule and not ev.get("RDATE"):
            if not cancelled and overlaps(start, end, window_start, window_end):
                out.append(to_output(instance(ev, None, None, feed), start, end))
            continue
        if cancelled:
            continue

        duration = end - start
        excluded = set()
        for params, value in ev.get("EXDATE", []):
            for part in value.split(","):
                when = parse_when(part, params)
                if when is not None:
                    excluded.add(identity(when))

        starts = list(occurrences(start, parse_rule(rule), window_end)) if rule else [start]
        for params, value in ev.get("RDATE", []):
            for part in value.split(","):
                when = parse_when(part, params)
                if when is not None and type(when) is type(start):
                    starts.append(when)

        series_edits = edits.get(first(ev, "UID"), {})
        seen = set()
        for when in starts:
            key = identity(when)
            if key in excluded or key in seen:
                continue
            seen.add(key)
            edit = series_edits.pop(key, None)
            if edit is not None:
                if first(edit, "STATUS").upper() == "CANCELLED":
                    continue
                e_start, e_end = span(edit)
                if e_start is not None and overlaps(e_start, e_end, window_start, window_end):
                    out.append(to_output(instance(edit, None, None, feed), e_start, e_end))
                continue
            if overlaps(when, when + duration, window_start, window_end):
                out.append(to_output(instance(ev, None, None, feed), when, when + duration))

        # Edits whose original slot the rule no longer produces (moved
        # beyond UNTIL, say) still happened.
        for edit in series_edits.values():
            if first(edit, "STATUS").upper() == "CANCELLED":
                continue
            e_start, e_end = span(edit)
            if e_start is not None and overlaps(e_start, e_end, window_start, window_end):
                out.append(to_output(instance(edit, None, None, feed), e_start, e_end))
    return out


# ---- feeds ----

def fetch(url):
    url = url.strip()
    if url.startswith("file://"):
        url = url[len("file://"):]
    if url.startswith(("/", "~")):
        with open(os.path.expanduser(url), "rb") as fh:
            data = fh.read(MAX_BYTES + 1)
    else:
        if url.lower().startswith("webcal://"):
            url = "https://" + url[len("webcal://"):]
        if not url.lower().startswith(("https://", "http://")):
            raise ValueError("not an http(s), webcal or file address")
        req = urllib.request.Request(url, headers={"User-Agent": "quickshell-calendar/1"})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            data = resp.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("feed is larger than 20 MB")
    text = data.decode("utf-8", errors="replace")
    if "BEGIN:VCALENDAR" not in text[:4096].upper():
        raise ValueError("not an iCalendar feed")
    return text


def feed_key(url):
    # The cache is keyed by a hash, so it never holds the address itself.
    return hashlib.sha256(url.strip().encode()).hexdigest()[:16]


def load_json(path, default):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return default


def save_cache(cache):
    os.makedirs(os.path.dirname(CACHE), mode=0o700, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(CACHE), prefix=".calendar-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(cache, fh)
        os.chmod(tmp, 0o600)
        os.replace(tmp, CACHE)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def short_error(exc):
    # Never echo the URL: it is the credential.
    if isinstance(exc, urllib.error.HTTPError):
        return f"HTTP {exc.code}"
    if isinstance(exc, urllib.error.URLError):
        return "network error"
    if isinstance(exc, OSError):
        return exc.strerror or "could not read"
    return str(exc)[:80]


def main():
    feeds = load_json(CONFIG, [])
    if not isinstance(feeds, list):
        feeds = []
    today = dt.datetime.now(LOCAL).date()
    window_start = today - dt.timedelta(days=PAST_DAYS)
    window_end = today + dt.timedelta(days=FUTURE_DAYS)

    cache = load_json(CACHE, {})
    if not isinstance(cache, dict):
        cache = {}
    new_cache, report, events, configured = {}, [], [], 0

    for i, feed in enumerate(feeds):
        if not isinstance(feed, dict) or not str(feed.get("url", "")).strip():
            continue
        configured += 1
        info = {
            "name": str(feed.get("name") or f"Calendar {i + 1}"),
            "color": str(feed.get("color") or "#89b4fa"),
        }
        if feed.get("enabled", True) is False:
            continue
        key = feed_key(feed["url"])
        try:
            got = expand(read_events(fetch(feed["url"])), info, window_start, window_end)
            new_cache[key] = got
            report.append({**info, "ok": True, "error": "", "count": len(got)})
        except Exception as exc:  # one bad feed must not hide the others
            got = cache.get(key, [])
            if got:
                new_cache[key] = got
            report.append({**info, "ok": False, "error": short_error(exc), "count": len(got)})
        events.extend(got)

    save_cache(new_cache)
    events.sort(key=lambda e: (e["start"], not e["allDay"], e["title"].lower()))
    json.dump({
        "updated": dt.datetime.now(LOCAL).strftime("%Y-%m-%dT%H:%M"),
        "configured": configured,
        "feeds": report,
        "events": events,
    }, sys.stdout)


if __name__ == "__main__":
    main()
