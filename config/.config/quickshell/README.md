# Quickshell bar

The top bar, replacing waybar. Hyprland starts it with `qs -n` (see `hypr/hyprland.lua`).

Restart it after editing a file here. Hot reload doesn't follow the stow symlink reliably:

```bash
qs kill; hyprctl dispatch 'hl.dsp.exec_cmd("qs -n")'
```

Launch it through Hyprland as above rather than from a terminal, so it gets Hyprland's environment, including `~/.cargo/bin` on `PATH` for `dusk`. Errors go to `qs log`.

## Layout

| Section | Items                                                                                 |
| ------- | ------------------------------------------------------------------------------------- |
| Left    | Launcher (Vicinae), notifications (Hokum), workspaces, focused window title           |
| Centre  | Clock, with a calendar and time-zone popup                                            |
| Right   | CPU, memory, disk, volume, Bluetooth, network, battery, keep-awake, power menu (dusk) |

Hover any item for a tooltip with details and what its clicks do.

| Item           | Left click         | Right click        | Scroll     |
| -------------- | ------------------ | ------------------ | ---------- |
| Launcher       | Vicinae            | Terminal           |            |
| Bell           | Hokum              | Do not disturb     |            |
| Clock          | Calendar and zones | Cycle label format |            |
| CPU, mem, disk | btop               |                    |            |
| Volume         | pavucontrol        | Mute               | Volume ±5% |
| Network        | nmtui              |                    |            |
| Keep awake     | Toggle             |                    |            |
| Power          | dusk               |                    |            |

Audio goes through `pactl`: this machine runs PulseAudio, which Quickshell's PipeWire service can't see.

## Keep awake

The coffee cup stops hypridle from dimming, locking, turning the screen off and suspending. It's off by default and resets to off when the bar restarts. Lock-before-suspend keeps working either way.

- Bar: click the cup, or `SUPER+SHIFT+L`
- Terminal: `qs ipc call idle toggle`, `on`, `off` or `status`

The idle timers themselves are in `hypr/hypridle.conf`.

## Clock popup

Click the clock, or run `qs ipc call clock toggle` (`open`, `close`). Click outside it or press Esc to close.

### Calendar

| Action | Month   | Year                       |
| ------ | ------- | -------------------------- |
| Arrows | `‹` `›` | `«` `»`                    |
| Scroll | Wheel   | Shift + wheel              |
| Keys   | ← →     | ↑ ↓ or Page Up / Page Down |

- Click the month name or the year in the title to pick from a grid. The year picker shows twelve years at a time; picking one moves on to its months.
- `↺ TODAY` (top right), `T` or Home goes back to the current month.
- Week numbers are ISO; weeks start on Monday.

### Time zones

Edit `zones.json` here. It's a list of IANA zone names, optionally with a label. Changes apply without a restart.

```json
[{ "zone": "America/Los_Angeles", "label": "San Francisco" }, "Europe/London"]
```

Your own zone is added automatically from `timedatectl` and marked "home", so don't list it. Unknown names are shown in red in the popup. Zone names are the paths under `/usr/share/zoneinfo`, e.g. `timedatectl list-timezones`.

Drag the slider under the zones to shift every row by up to ±12 hours (it snaps to whole hours; scroll moves an hour). Double-click it, press Esc or click the shift shown right of ZONES (e.g. `+3H · NOW`) to go back to now.

### Google Calendar (and other calendars)

Read-only: events appear as dots on the days and in an agenda for the day you click, with a **join** button for Meet, Zoom and Teams links. Nothing can be created or edited from the popup.

1. In Google Calendar on the web, open **Settings**, pick the calendar under _Settings for my calendars_, then **Integrate calendar**.
2. Copy **Secret address in iCal format**.
3. Put it in `~/.config/quickshell-calendars.json`:

   ```json
   [
     {
       "name": "Google",
       "url": "https://calendar.google.com/calendar/ical/.../basic.ics",
       "color": "#89b4fa",
       "enabled": true
     }
   ]
   ```

4. Save. The popup syncs straight away; there's nothing to restart.

Add one entry per calendar, each with its own colour. `"enabled": false` turns one off without deleting it. Other sources work the same way: any `https://` or `webcal://` iCal link (iCloud public calendar, Outlook published calendar, Proton, Nextcloud, Fastmail) or a path to a local `.ics` file.

**Keep the link private.** Anyone with the secret address can read the calendar, which is why the file lives outside these dotfiles and should never be committed. Create it readable only by you:

```bash
install -m 600 /dev/null ~/.config/quickshell-calendars.json
```

If the link leaks, reset it in the same Google settings page; the old one stops working.

Sync runs when the bar starts, every 15 minutes, when the file is saved, and when the popup opens if the last sync is over 5 minutes old. The time in the agenda header is the last sync; click it to sync now. A calendar that fails shows its name and the error there, in amber, and keeps showing the events it last fetched.

Google updates its iCal feed on its own schedule, so changes made on the web can take a while to show up.

Under the hood: `scripts/calendar-sync.py` (Python standard library only) fetches the feeds and prints the events from two months back to about a year ahead. Its offline copy is `~/.cache/quickshell/calendar.json`, which holds event details but not the links. To check a feed by hand:

```bash
python3 -I ~/.config/quickshell/scripts/calendar-sync.py | python3 -m json.tool | head -40
```

## Files

| File                                                                   | What                                            |
| ---------------------------------------------------------------------- | ----------------------------------------------- |
| `shell.qml`                                                            | Entry point: one bar per monitor                |
| `Bar.qml`                                                              | Layout                                          |
| `Theme.qml`                                                            | Colours (Catppuccin Mocha), fonts, sizes, icons |
| `Widget.qml`, `Pill.qml`, `Tooltip.qml`                                | Shared building blocks                          |
| `ClockItem.qml`, `ClockPopup.qml`, `ClockState.qml`                    | Clock, popup, zone offsets                      |
| `CalendarState.qml`, `scripts/calendar-sync.py`                        | Calendar sync                                   |
| `zones.json`                                                           | Time zones for the popup                        |
| `Idle.qml`                                                             | Keep-awake toggle                               |
| Other `*Item.qml`, `SysInfo.qml`, `Workspaces.qml`, `ActiveWindow.qml` | Bar items                                       |

Icons are Nerd Font codepoints in `Theme.qml`, written as numbers because literal glyphs get lost when files are copied around.
