import QtQuick
import Quickshell
import Quickshell.Wayland

// Calendar and time-zone converter, dropped from the bar clock.
//
// Calendar: month grid with ISO week numbers; arrows, the wheel or the
// pickers in the title change month and year.
// Zones: one row per zone in zones.json plus this machine's own, each with a
// 24-hour day/night rail. Drag the scrubber to see what a time quoted in one
// zone is in the others; it snaps to whole hours, and double-click, Escape
// or clicking "now" resets it.
//
// A layer-shell panel like the bar, rather than an xdg popup under a Hyprland
// focus grab: clicks inside never reached the popup that way. Anchored to the
// top edge only, so it sits centred under the clock. A transparent full-screen
// layer behind it closes it on a click anywhere else.
PanelWindow {
    id: root

    anchors.top: true
    margins.top: Theme.barHeight + 4
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clock"
    // Keyboard while open, for Escape and the arrow keys.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 2 * pad
    color: "transparent"

    readonly property int pad: 14
    readonly property color dim: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.45)
    readonly property color faint: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.10)
    readonly property color day: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.28)

    // Scrubber offset in minutes, -720 to +720.
    property int scrub: 0

    // Month on show; reset to today whenever the popup opens.
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()

    readonly property var now: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // What the grid area shows: the days of a month, a month picker, or a
    // page of twelve years.
    property string pickMode: "days"
    property int yearPage: 0

    readonly property bool onToday: pickMode === "days"
        && viewYear === now.getFullYear() && viewMonth === now.getMonth()

    onVisibleChanged: {
        if (visible) {
            scrub = 0;
            goToday();
            keys.forceActiveFocus();
            CalendarState.refreshIfOld();
        }
    }

    function goToday() {
        viewYear = now.getFullYear();
        viewMonth = now.getMonth();
        pickMode = "days";
        selectedDate = now;
    }

    // Day whose agenda is shown, with calendar sync on.
    property var selectedDate: new Date()

    function formatTime(date) {
        return Qt.formatTime(date, "HH:mm");
    }

    function agendaTime(ev) {
        if (ev.allDay) return "all day";
        // Continues from an earlier day: say so rather than show its start.
        if (!sameDay(ev.startDate, selectedDate)) return "cont.";
        return formatTime(ev.startDate);
    }

    // ‹ › and the wheel: a month in the day grid, a year in the month picker,
    // a page in the year picker.
    function step(delta) {
        if (pickMode === "days") shiftMonth(delta);
        else if (pickMode === "months") viewYear += delta;
        else yearPage += 12 * delta;
    }

    function showYears() {
        yearPage = viewYear - 4;
        pickMode = "years";
    }

    // Click-away catcher: covers the screen, bar included, below the popup.
    // Clicking the clock while open lands here too, so it still closes.
    PanelWindow {
        screen: root.screen
        visible: root.visible
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-clock-scrim"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: ClockState.open = false
        }
    }

    // ---- date helpers ----

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 3 - ((t.getUTCDay() + 6) % 7));
        const jan4 = new Date(Date.UTC(t.getUTCFullYear(), 0, 4));
        return 1 + Math.round(((t - jan4) / 86400000 - 3 + ((jan4.getUTCDay() + 6) % 7)) / 7);
    }

    // 42 days, Monday first, covering the month on show.
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(viewYear, viewMonth, 1 - lead + i));
        return out;
    }

    readonly property real yearProgress: {
        const start = new Date(now.getFullYear(), 0, 1);
        const end = new Date(now.getFullYear() + 1, 0, 1);
        return (now - start) / (end - start);
    }

    // ---- zone helpers ----

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    // Wall-clock time in a zone, as a Date whose UTC fields hold that time.
    function zoneTime(offset) {
        return new Date(now.getTime() + scrub * 60000 + offset * 60000);
    }

    function dayIndex(offset) {
        return Math.floor((now.getTime() + scrub * 60000 + offset * 60000) / 86400000);
    }

    function relative(minutes) {
        if (minutes === 0) return "";
        const sign = minutes > 0 ? "+" : "-";
        const m = Math.abs(minutes);
        const h = Math.floor(m / 60);
        const rest = m % 60;
        return rest ? `${sign}${h}h${pad2(rest)}` : `${sign}${h}h`;
    }

    // ---- view ----

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.tooltipBg
        border.width: 1
        border.color: Theme.tooltipBorder
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: {
            if (root.scrub !== 0) root.scrub = 0;
            else ClockState.open = false;
        }
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onUpPressed: root.shiftMonth(-12)
        Keys.onDownPressed: root.shiftMonth(12)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_PageUp) root.shiftMonth(-12);
            else if (event.key === Qt.Key_PageDown) root.shiftMonth(12);
            else if (event.key === Qt.Key_Home || event.key === Qt.Key_T) root.goToday();
        }
    }

    // A dim label that brightens on hover and reports clicks.
    component Link: Text {
        id: link
        signal clicked
        property bool active: true
        property color restColor: root.dim
        color: active && area.containsMouse ? Theme.foreground : restColor
        font.family: Theme.fontFamily

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            enabled: link.active
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.clicked()
        }
    }

    Column {
        id: content
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: 10

        // Header: weekday over the date.
        Column {
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: weekday.implicitHeight

                Text {
                    id: weekday
                    text: Qt.formatDate(root.now, "dddd").toUpperCase()
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.5
                }

                // Back to this month, shown only when looking elsewhere.
                Link {
                    anchors.right: parent.right
                    visible: !root.onToday
                    text: "↺ TODAY"
                    restColor: Theme.accent
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                    onClicked: root.goToday()
                }
            }

            Text {
                text: Qt.formatDate(root.now, "MMMM d")
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 26
                font.bold: true
            }
        }

        // Year progress.
        Row {
            width: parent.width
            spacing: 10

            Text {
                id: yearLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.now.getFullYear()
                color: root.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - yearLabel.width - percentLabel.width - 2 * parent.spacing
                height: 4
                radius: 2
                color: root.faint

                Rectangle {
                    width: parent.width * root.yearProgress
                    height: parent.height
                    radius: 2
                    color: Theme.foreground
                }
            }

            Text {
                id: percentLabel
                anchors.verticalCenter: parent.verticalCenter
                text: Math.floor(root.yearProgress * 100) + "%"
                color: root.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        // Navigation: « year, ‹ month (or year / page in the pickers), and a
        // title whose month and year open their pickers.
        Item {
            width: parent.width
            height: 24

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Link {
                    text: "«"
                    font.pixelSize: 20
                    visible: root.pickMode === "days"
                    onClicked: root.shiftMonth(-12)
                }

                Link {
                    text: "‹"
                    font.pixelSize: 20
                    onClicked: root.step(-1)
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Link {
                    visible: root.pickMode !== "years"
                    text: Qt.locale().standaloneMonthName(root.viewMonth, Locale.LongFormat).toUpperCase()
                    restColor: root.pickMode === "months" ? Theme.accent : root.dim
                    font.pixelSize: 12
                    font.letterSpacing: 1.5
                    onClicked: root.pickMode = root.pickMode === "months" ? "days" : "months"
                }

                Link {
                    text: root.pickMode === "years"
                        ? `${root.yearPage} – ${root.yearPage + 11}`
                        : root.viewYear
                    restColor: root.pickMode === "years" ? Theme.accent : root.dim
                    font.pixelSize: 12
                    font.letterSpacing: 1.5
                    onClicked: root.pickMode === "years" ? root.pickMode = "days" : root.showYears()
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Link {
                    text: "›"
                    font.pixelSize: 20
                    onClicked: root.step(1)
                }

                Link {
                    text: "»"
                    font.pixelSize: 20
                    visible: root.pickMode === "days"
                    onClicked: root.shiftMonth(12)
                }
            }
        }

        // Grid area: days, months or years, all the same height so the
        // popup doesn't jump when switching.
        Item {
            width: parent.width
            height: grid.implicitHeight

            // Wheel: month (Shift: year) on the days; year or page on the pickers.
            // A notch (120) is one step; touchpad deltas add up to the same.
            // Shift turns vertical scrolling horizontal, hence summing both axes.
            WheelHandler {
                property real acc: 0
                acceptedModifiers: Qt.KeyboardModifierMask
                onWheel: event => {
                    acc += event.angleDelta.y + event.angleDelta.x;
                    const steps = Math.trunc(acc / 120);
                    if (steps === 0) return;
                    acc -= steps * 120;
                    const delta = -steps;
                    if (root.pickMode === "days" && (event.modifiers & Qt.ShiftModifier))
                        root.shiftMonth(12 * delta);
                    else
                        root.step(delta);
                }
            }

            // Months of the year on show.
            Grid {
                visible: root.pickMode === "months"
                anchors.fill: parent
                columns: 3

                Repeater {
                    model: 12

                    Item {
                        readonly property bool current: index === root.now.getMonth()
                            && root.viewYear === root.now.getFullYear()
                        readonly property bool selected: index === root.viewMonth

                        width: parent.width / 3
                        height: parent.height / 4

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: monthArea.containsMouse ? root.faint : "transparent"
                            border.width: parent.current ? 1 : 0
                            border.color: Theme.accent
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Qt.locale().standaloneMonthName(index, Locale.ShortFormat).toUpperCase()
                            color: parent.current ? Theme.accent : Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: parent.selected
                            font.letterSpacing: 1
                        }

                        MouseArea {
                            id: monthArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.viewMonth = index;
                                root.pickMode = "days";
                            }
                        }
                    }
                }
            }

            // A page of twelve years; picking one moves on to its months.
            Grid {
                visible: root.pickMode === "years"
                anchors.fill: parent
                columns: 3

                Repeater {
                    model: 12

                    Item {
                        readonly property int year: root.yearPage + index
                        readonly property bool current: year === root.now.getFullYear()

                        width: parent.width / 3
                        height: parent.height / 4

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: yearArea.containsMouse ? root.faint : "transparent"
                            border.width: parent.current ? 1 : 0
                            border.color: Theme.accent
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.year
                            color: parent.current ? Theme.accent : Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: parent.year === root.viewYear
                        }

                        MouseArea {
                            id: yearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.viewYear = parent.year;
                                root.pickMode = "months";
                            }
                        }
                    }
                }
            }

            // Month grid: week number column, then Monday to Sunday.
            Grid {
                id: grid
                visible: root.pickMode === "days"
                columns: 8
                width: parent.width

                readonly property real cellW: width / 8
                readonly property int cellH: 26

                Repeater {
                    model: ["W", "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

                    Text {
                        width: grid.cellW
                        height: 18
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index === 0 ? root.faint : root.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                }

                Repeater {
                    model: 48

                    Item {
                        readonly property int week: Math.floor(index / 8)
                        readonly property bool weekCell: index % 8 === 0
                        readonly property var date: weekCell ? null : root.cells[week * 7 + index % 8 - 1]
                        readonly property bool inMonth: !weekCell && date.getMonth() === root.viewMonth
                        readonly property bool today: !weekCell && root.sameDay(date, root.now)
                        readonly property bool weekend: index % 8 >= 6
                        readonly property bool selected: !weekCell && CalendarState.enabled
                            && root.sameDay(date, root.selectedDate)
                        // One dot per calendar with something on, at most three.
                        readonly property var dots: {
                            if (weekCell || !CalendarState.enabled) return [];
                            const seen = [];
                            for (const ev of CalendarState.eventsOn(date))
                                if (seen.indexOf(ev.color) < 0) seen.push(ev.color);
                            return seen.slice(0, 3);
                        }

                        width: grid.cellW
                        height: grid.cellH

                        Rectangle {
                            anchors.centerIn: parent
                            width: 30
                            height: 24
                            radius: 8
                            visible: parent.today || parent.selected || dayArea.containsMouse
                            color: parent.today
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                : root.faint
                            border.width: parent.today || parent.selected ? 1 : 0
                            border.color: parent.today ? Theme.accent : root.dim
                        }

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: parent.dots.length ? -3 : 0
                            text: parent.weekCell
                                ? root.isoWeek(root.cells[parent.week * 7 + 3])
                                : parent.date.getDate()
                            color: {
                                if (parent.weekCell) return root.dim;
                                if (parent.today) return Theme.accent;
                                if (!parent.inMonth) return root.day;
                                return parent.weekend ? root.dim : Theme.foreground;
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: parent.weekCell ? 10 : 13
                            font.bold: parent.today
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            spacing: 2

                            Repeater {
                                model: parent.parent.dots

                                Rectangle {
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: modelData
                                }
                            }
                        }

                        // Days are only clickable with sync on: picking one
                        // shows its agenda.
                        MouseArea {
                            id: dayArea
                            anchors.fill: parent
                            enabled: !parent.weekCell && CalendarState.enabled
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedDate = parent.date;
                                if (!parent.inMonth) {
                                    root.viewYear = parent.date.getFullYear();
                                    root.viewMonth = parent.date.getMonth();
                                }
                            }
                        }
                    }
                }

            }
        }

        // Agenda for the selected day, with calendar sync on.
        Column {
            id: agenda
            visible: CalendarState.enabled
            width: parent.width
            spacing: 6

            readonly property var events: CalendarState.eventsOn(root.selectedDate)
            readonly property int maxRows: 5

            Rectangle {
                width: parent.width
                height: 1
                color: root.faint
            }

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    text: root.sameDay(root.selectedDate, root.now)
                        ? "TODAY"
                        : Qt.formatDate(root.selectedDate, "ddd d MMM").toUpperCase()
                    color: root.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }

                // Sync state; click to sync now.
                Link {
                    anchors.right: parent.right
                    text: {
                        if (CalendarState.syncing) return "SYNCING…";
                        if (CalendarState.failed.length)
                            return `${CalendarState.failed.map(f => f.name).join(", ")}: ${CalendarState.failed[0].error}  ↻`.toUpperCase();
                        return CalendarState.updated ? `${CalendarState.updated.slice(11)}  ↻` : "↻";
                    }
                    restColor: CalendarState.failed.length ? Theme.warning : root.dim
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    active: !CalendarState.syncing
                    onClicked: CalendarState.refresh()
                }
            }

            Text {
                visible: agenda.events.length === 0
                text: "Nothing scheduled"
                color: root.dim
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Repeater {
                model: agenda.events.slice(0, agenda.maxRows)

                Item {
                    id: evRow
                    required property var modelData

                    width: agenda.width
                    height: 18

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 14
                        radius: 1.5
                        color: evRow.modelData.color
                    }

                    Text {
                        id: evTime
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 52
                        text: root.agendaTime(evRow.modelData)
                        color: root.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.left: evTime.right
                        anchors.right: joinLink.visible ? joinLink.left : parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: evRow.modelData.title
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        textFormat: Text.PlainText
                    }

                    // Meet, Zoom or Teams link found in the event.
                    Link {
                        id: joinLink
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: evRow.modelData.link !== ""
                        text: Theme.iconVideo + " join"
                        restColor: Theme.accent
                        font.pixelSize: 11
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", evRow.modelData.link]);
                            ClockState.open = false;
                        }
                    }
                }
            }

            Text {
                visible: agenda.events.length > agenda.maxRows
                text: `+${agenda.events.length - agenda.maxRows} more`
                color: root.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        // Divider.
        Rectangle {
            width: parent.width
            height: 1
            color: root.faint
        }

        // Zones header: what the scrubber is set to.
        Item {
            width: parent.width
            height: 16

            Text {
                anchors.left: parent.left
                text: "ZONES"
                color: root.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 1.5
            }

            Text {
                anchors.right: parent.right
                text: root.scrub === 0 ? "NOW" : root.relative(root.scrub).toUpperCase() + "  ·  NOW"
                color: root.scrub === 0 ? root.dim : (nowArea.containsMouse ? Theme.foreground : Theme.accent)
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.letterSpacing: 1.5

                MouseArea {
                    id: nowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.scrub !== 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.scrub = 0
                }
            }
        }

        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: ClockState.rows

                Column {
                    id: row

                    required property var modelData
                    readonly property var time: root.zoneTime(modelData.offset)
                    readonly property real hour: time.getUTCHours() + time.getUTCMinutes() / 60
                    readonly property bool daytime: hour >= 6 && hour < 18
                    readonly property int dayDelta: root.dayIndex(modelData.offset) - root.dayIndex(ClockState.homeOffset)

                    width: parent.width
                    spacing: 2

                    Item {
                        width: parent.width
                        height: 18

                        Text {
                            id: glyph
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            text: row.daytime ? Theme.iconSun : Theme.iconMoon
                            color: row.modelData.home ? Theme.accent : root.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.left: glyph.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                            color: row.modelData.home ? Theme.accent : Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: row.modelData.home

                            Text {
                                anchors.left: parent.right
                                anchors.leftMargin: 6
                                anchors.baseline: parent.baseline
                                text: row.modelData.abbr
                                color: root.dim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                anchors.baseline: timeLabel.baseline
                                visible: row.dayDelta !== 0
                                text: row.dayDelta > 0 ? `+${row.dayDelta}d` : `${row.dayDelta}d`
                                color: Theme.warning
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            Text {
                                id: timeLabel
                                text: `${root.pad2(row.time.getUTCHours())}:${root.pad2(row.time.getUTCMinutes())}`
                                color: row.modelData.home ? Theme.accent : Theme.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                anchors.baseline: timeLabel.baseline
                                width: 40
                                horizontalAlignment: Text.AlignRight
                                text: row.modelData.home ? "home" : root.relative(row.modelData.offset - ClockState.homeOffset)
                                color: root.dim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }

                    // 24-hour rail: midnight to midnight, daylight 06-18 lighter.
                    Item {
                        width: parent.width - 20
                        x: 20
                        height: 6

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 3
                            radius: 1.5
                            color: root.faint
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * 6 / 24
                            width: parent.width * 12 / 24
                            height: 3
                            color: root.day
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * row.hour / 24 - width / 2
                            width: 3
                            height: 10
                            radius: 1.5
                            color: row.modelData.home ? Theme.accent : Theme.foreground
                        }
                    }
                }
            }

            Text {
                visible: ClockState.invalid.length > 0
                width: parent.width
                wrapMode: Text.Wrap
                text: "Unknown zone in zones.json: " + ClockState.invalid.join(", ")
                color: Theme.urgent
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        // Scrubber: -12h to +12h, 15-minute steps, snapping to whole hours.
        Column {
            width: parent.width
            spacing: 4

            Item {
                id: scrubber
                width: parent.width
                height: 18

                function scrubAt(x) {
                    const f = Math.max(0, Math.min(1, x / width));
                    let minutes = Math.round((f * 24 - 12) * 4) * 15;
                    const nearest = Math.round(minutes / 60) * 60;
                    if (Math.abs(minutes - nearest) <= 15) minutes = nearest;
                    root.scrub = minutes;
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: 24

                        Rectangle {
                            readonly property real mid: (index + 0.5 - 12) * 60
                            width: (scrubber.width - 23 * 2) / 24
                            height: 4
                            radius: 1
                            color: (root.scrub > 0 && mid > 0 && mid < root.scrub)
                                || (root.scrub < 0 && mid < 0 && mid > root.scrub)
                                ? Theme.accent : root.faint
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: scrubber.width * (root.scrub + 720) / 1440 - width / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: root.scrub === 0 ? Theme.foreground : Theme.accent

                    Behavior on x {
                        enabled: !scrubArea.pressed
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: scrubArea
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    cursorShape: Qt.PointingHandCursor
                    onPressed: event => scrubber.scrubAt(event.x)
                    onPositionChanged: event => { if (pressed) scrubber.scrubAt(event.x); }
                    onDoubleClicked: root.scrub = 0
                    onWheel: event => {
                        const step = event.angleDelta.y > 0 ? 60 : -60;
                        root.scrub = Math.max(-720, Math.min(720, Math.round((root.scrub + step) / 60) * 60));
                    }
                }
            }

            Item {
                width: parent.width
                height: 12

                Text {
                    anchors.left: parent.left
                    text: "-12H"
                    color: root.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "NOW"
                    color: root.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                Text {
                    anchors.right: parent.right
                    text: "+12H"
                    color: root.dim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}
