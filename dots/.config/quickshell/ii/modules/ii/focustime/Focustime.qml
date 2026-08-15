import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.shapes
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Window
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common/widgets/shapes/shapes/rounded-polygon.js" as RoundedPolygon
import "../../common/widgets/shapes/shapes/corner-rounding.js" as CornerRounding
import "../../common/widgets/shapes/geometry/offset.js" as Offset

Scope {
    id: root

    Loader {
        id: focustimeLoader
        active: false

        sourceComponent: PanelWindow {
            id: focustimeRoot
            visible: focustimeLoader.active

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            function hide() {
                focustimeLoader.active = false;
            }

            // Forwarded so the ilyamiro UI can keep its original bare intro* references
            property real introMain: window.introMain
            property real introHeader: window.introHeader
            property real introStats: window.introStats
            property real introMidLeft: window.introMidLeft
            property real introMidRight: window.introMidRight
            property real introBottom: window.introBottom
            property real introAppBars: window.introAppBars

            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:focustime"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            mask: Region {
                item: window
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(focustimeRoot);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(focustimeRoot);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    focustimeRoot.hide();
                }
            }

            StyledRectangularShadow {
                target: window
            }

            // Click on the dimmed area outside the card closes the popup
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                    let tl = window.mapToItem(focustimeRoot, 0, 0);
                    if (mouse.x < tl.x || mouse.x > tl.x + window.width ||
                        mouse.y < tl.y || mouse.y > tl.y + window.height) {
                        focustimeRoot.hide();
                    }
                }
            }

            // -----------------------------------------------------------------
            // ilyamiro FocusTimePopup faithful port
            // Original: https://github.com/ilyamiro/nixos-configuration
            // -----------------------------------------------------------------
            Item {
                id: window
                width: window.s(900)
                height: window.s(700)
                anchors.centerIn: parent

                readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/focustime"
                readonly property string stateFilePath: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell/focustime/focustime_state.json"
                readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/focustime"

                // --- Responsive Scaling Logic (Scaler.qml port) ---
                property real currentWidth: Screen.width
                property real currentHeight: Screen.height
                property real uiScale: 1.0
                property real baseScale: {
                    let rw = currentWidth / 1920.0;
                    let rh = currentHeight / 1080.0;
                    let r = Math.min(rw, rh);
                    let bs = 1.0;
                    if (r <= 1.0) {
                        bs = Math.max(0.35, Math.pow(r, 0.85));
                    } else {
                        bs = Math.pow(r, 0.5);
                    }
                    return bs * uiScale;
                }

                function s(val) {
                    return Math.round(val * baseScale);
                }

                // Stretched Material 3 squircle filling the whole card
                function squirclePolygon(w, h) {
                    const cr = new CornerRounding.CornerRounding(Math.max(w, h) * 0.035, 2)
                    return RoundedPolygon.RoundedPolygon.rectangle(w, h, cr)
                        .transformed((x, y) => new Offset.Offset(x + w / 2, y + h / 2))
                }

                Process {
                    id: scaleReader
                    command: ["cat", Quickshell.env("HOME") + "/.config/hypr/settings.json"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            try {
                                if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                                    let parsed = JSON.parse(this.text);
                                    if (parsed.uiScale !== undefined && window.uiScale !== parsed.uiScale) {
                                        window.uiScale = parsed.uiScale;
                                    }
                                }
                            } catch (e) {}
                        }
                    }
                }

                // -----------------------------------------------------------------
                // COLORS (Illogical Impulse theme - Appearance.m3colors)
                // The ilyamiro palette keys are derived from the shell's dynamic
                // matugen (M3) colors so the popup always matches the rest of the UI.
                // -----------------------------------------------------------------
                Item {
                    id: _theme
                    visible: false

                    // Card / popup surfaces
                    property color base: Appearance.m3colors.m3surfaceContainer
                    property color mantle: Appearance.m3colors.m3surfaceContainerLow
                    property color crust: Appearance.m3colors.m3background
                    // Text
                    property color text: Appearance.m3colors.m3onSurface
                    property color subtext0: Appearance.m3colors.m3onSurfaceVariant
                    property color subtext1: Appearance.m3colors.m3onSurfaceVariant
                    property color overlay0: Appearance.colors.colSubtext
                    property color overlay1: Appearance.colors.colSubtext
                    property color overlay2: Appearance.m3colors.m3onSurfaceVariant
                    // Surfaces / borders
                    property color surface0: Appearance.m3colors.m3surfaceContainerHigh
                    property color surface1: Appearance.m3colors.m3outlineVariant
                    property color surface2: Appearance.m3colors.m3surfaceContainerHighest
                    // Accents
                    property color blue: Appearance.m3colors.m3primary
                    property color sapphire: Appearance.m3colors.m3tertiary
                    property color peach: Appearance.m3colors.m3secondary
                    property color green: Appearance.m3colors.m3success
                    property color red: Appearance.m3colors.m3error
                    property color mauve: Appearance.m3colors.m3tertiary
                    property color pink: Appearance.m3colors.m3tertiary
                    property color yellow: Appearance.m3colors.m3secondary
                    property color maroon: Appearance.m3colors.m3errorContainer
                    property color teal: Appearance.m3colors.m3successContainer
                }

                readonly property color base: _theme.base
                readonly property color mantle: _theme.mantle
                readonly property color crust: _theme.crust
                readonly property color text: _theme.text
                readonly property color subtext0: _theme.subtext0
                readonly property color overlay0: _theme.overlay0
                readonly property color surface0: _theme.surface0
                readonly property color surface1: _theme.surface1
                readonly property color surface2: _theme.surface2

                readonly property color mauve: _theme.mauve
                readonly property color pink: _theme.pink
                readonly property color red: _theme.red
                readonly property color peach: _theme.peach
                readonly property color yellow: _theme.yellow
                readonly property color green: _theme.green
                readonly property color sapphire: _theme.sapphire
                readonly property color blue: _theme.blue

                readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

                // -----------------------------------------------------------------
                // STATE & POLLING PATHS
                // -----------------------------------------------------------------
                property var globalDate: new Date()
                property var appDate: new Date()
                readonly property var activeDate: window.selectedAppClass === "" ? window.globalDate : window.appDate

                property string selectedDateStr: ""
                property string selectedAppClass: ""
                property string selectedAppName: ""
                property string selectedAppIcon: ""
                property int totalSeconds: 0
                property int averageSeconds: 0
                property int yesterdaySeconds: 0
                property string weekRangeStr: ""
                property string liveActiveApp: "Desktop"

                property bool isWeekView: false

                property var topApps: []
                property var weekData: []
                property real maxWeekTotal: 1
                property var monthData: []
                property real maxMonthTotal: 1

                property var weekAppsData: []
                property var weekHeatmapData: [[],[],[],[],[],[],[]]
                property real maxWeekHour: 1
                property string peakUsageHours: "N/A"

                property var hourlyData: new Array(48).fill(0)
                property real maxHourlyTotal: 1

                property real animatedTotalSeconds: 0
                Behavior on animatedTotalSeconds {
                    NumberAnimation { duration: 850; easing.type: Easing.OutQuint }
                }
                onTotalSecondsChanged: {
                    animatedTotalSeconds = totalSeconds;
                }

                property real weekViewFocus: window.isWeekView ? 1.0 : 0.0
                Behavior on weekViewFocus {
                    NumberAnimation { duration: 550; easing.type: Easing.OutExpo }
                }

                property real appViewFocus: window.selectedAppClass !== "" ? 1.0 : 0.0
                Behavior on appViewFocus {
                    NumberAnimation { duration: 550; easing.type: Easing.OutExpo }
                }

                property bool isFirstLoad: true
                readonly property bool isTodaySelected: window.selectedDateStr === getIsoDate(new Date())

                // --- CHOREOGRAPHED STARTUP STATES ---
                property real introMain: 0.0
                property real introHeader: 0.0
                property real introStats: 0.0
                property real introMidLeft: 0.0
                property real introMidRight: 0.0
                property real introBottom: 0.0
                property real introAppBars: 0.0

                ParallelAnimation {
                    running: true

                    NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutQuart }

                    SequentialAnimation {
                        PauseAnimation { duration: 100 }
                        NumberAnimation { target: window; property: "introHeader"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
                    }

                    SequentialAnimation {
                        PauseAnimation { duration: 250 }
                        NumberAnimation { target: window; property: "introStats"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    }

                    SequentialAnimation {
                        PauseAnimation { duration: 350 }
                        NumberAnimation { target: window; property: "introMidLeft"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart }
                    }

                    SequentialAnimation {
                        PauseAnimation { duration: 300 }
                        NumberAnimation { target: window; property: "introAppBars"; from: 0; to: 1.0; duration: 1300; easing.type: Easing.OutQuart }
                    }

                    SequentialAnimation {
                        PauseAnimation { duration: 450 }
                        NumberAnimation { target: window; property: "introMidRight"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart }
                    }

                    SequentialAnimation {
                        PauseAnimation { duration: 550 }
                        NumberAnimation { target: window; property: "introBottom"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutExpo }
                    }
                }

                Component.onCompleted: {
                    requestDataUpdate();
                }

                ParallelAnimation {
                    id: exitAnim
                    NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
                    NumberAnimation { target: window; property: "introHeader"; to: 0; duration: 300; easing.type: Easing.InQuart }
                    NumberAnimation { target: window; property: "introStats"; to: 0; duration: 350; easing.type: Easing.InQuart }
                    NumberAnimation { target: window; property: "introMidLeft"; to: 0; duration: 250; easing.type: Easing.InQuart }
                    NumberAnimation { target: window; property: "introMidRight"; to: 0; duration: 200; easing.type: Easing.InQuart }
                    NumberAnimation { target: window; property: "introBottom"; to: 0; duration: 150; easing.type: Easing.InQuart }
                    NumberAnimation { target: window; property: "introAppBars"; to: 0; duration: 250; easing.type: Easing.InQuart }
                }

                property real globalOrbitAngle: 0
                NumberAnimation on globalOrbitAngle {
                    from: 0; to: Math.PI * 2; duration: 120000; loops: Animation.Infinite; running: true
                }

                // --- SHARED DATA INGESTION ---
                function updateFromData(data) {
                    window.selectedDateStr = data.selected_date;
                    window.totalSeconds = data.total || 0;
                    window.averageSeconds = data.average || 0;
                    window.yesterdaySeconds = data.yesterday || 0;
                    window.weekRangeStr = data.week_range || "";
                    window.liveActiveApp = data.current || "Unknown";

                    if (window.isFirstLoad) firstLoadTimer.start();

                    window.topApps = data.apps || [];
                    syncAppsModel();

                    window.weekAppsData = data.week_apps || [];
                    syncWeekAppsModel();

                    window.weekHeatmapData = data.week_heatmap || [[],[],[],[],[],[],[]];
                    let mwh = 1;
                    let hourSums = new Array(24).fill(0);

                    for (let i = 0; i < 7; i++) {
                        if (!window.weekHeatmapData[i]) continue;
                        for (let j = 0; j < 24; j++) {
                            if (window.weekHeatmapData[i][j] > mwh) mwh = window.weekHeatmapData[i][j];
                            hourSums[j] += window.weekHeatmapData[i][j];
                        }
                    }
                    window.maxWeekHour = mwh;

                    let max2HourVal = -1;
                    let peakStart = 0;
                    for (let h = 0; h < 23; h++) {
                        let current2H = hourSums[h] + hourSums[h+1];
                        if (current2H > max2HourVal) {
                            max2HourVal = current2H;
                            peakStart = h;
                        }
                    }

                    function formatAMPM(hour) {
                        let ampm = hour >= 12 ? 'PM' : 'AM';
                        let h12 = hour % 12;
                        h12 = h12 ? h12 : 12;
                        return h12 + ' ' + ampm;
                    }

                    if (max2HourVal > 0) {
                        window.peakUsageHours = formatAMPM(peakStart) + " - " + formatAMPM(peakStart + 2);
                    } else {
                        window.peakUsageHours = "N/A";
                    }

                    let parsedWeek = data.week || [];
                    if (JSON.stringify(window.weekData) !== JSON.stringify(parsedWeek)) {
                        window.weekData = parsedWeek;
                        syncWeekModel();
                    }

                    let parsedMonth = data.month || [];
                    if (JSON.stringify(window.monthData) !== JSON.stringify(parsedMonth)) {
                        window.monthData = parsedMonth;
                        syncMonthModel();
                    }

                    window.hourlyData = data.hourly || new Array(48).fill(0);
                    let currentMaxHour = 1;
                    for(let i=0; i<48; i++) {
                        if (window.hourlyData[i] > currentMaxHour) currentMaxHour = window.hourlyData[i];
                    }
                    window.maxHourlyTotal = currentMaxHour;
                }

                // --- DATA FETCHING ROUTING ---
                function requestDataUpdate() {
                    if (window.selectedAppClass === "" && getIsoDate(window.activeDate) === getIsoDate(new Date())) {
                        liveFileReader.running = true;
                    } else {
                        let cmd = ["python3", window.scriptsDir + "/get_stats.py", getIsoDate(window.activeDate)];
                        if (window.selectedAppClass !== "") {
                            cmd.push("--app");
                            cmd.push(window.selectedAppClass);
                        }
                        cmd.push("--db-dir");
                        cmd.push(window.stateDir);
                        statsPoller.command = cmd;
                        statsPoller.running = true;
                    }
                }

                // --- LIVE FILE READER (For Global Today) ---
                Process {
                    id: liveFileReader
                    command: ["cat", window.stateFilePath]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let raw = this.text.trim();
                            if (raw === "") return;
                            try {
                                let data = JSON.parse(raw);
                                window.updateFromData(data);
                            } catch(e) {}
                        }
                    }
                }

                Timer {
                    interval: 1000
                    running: window.isTodaySelected
                    repeat: true
                    onTriggered: window.requestDataUpdate()
                }

                // --- PYTHON STATS FETCHER (For History & Specific Apps) ---
                Process {
                    id: statsPoller
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let raw = this.text.trim();
                            if (raw === "") return;
                            try {
                                let data = JSON.parse(raw);
                                window.updateFromData(data);
                            } catch(e) {}
                        }
                    }
                }

                // --- DATE HELPERS ---
                function getIsoDate(d) {
                    let z = d.getTimezoneOffset() * 60000;
                    return (new Date(d - z)).toISOString().slice(0, 10);
                }

                function getFancyDate(d) {
                    let monthName = window.monthNames[d.getMonth()];
                    let dateNum = d.getDate();
                    let isToday = getIsoDate(d) === getIsoDate(new Date());
                    return isToday ? "Today" : `${monthName} ${dateNum}`;
                }

                function changeDay(offsetDays) {
                    let d = new Date(window.activeDate);
                    d.setDate(d.getDate() + offsetDays);
                    if (window.selectedAppClass === "") {
                        window.globalDate = d;
                    } else {
                        window.appDate = d;
                    }
                    window.isFirstLoad = true;
                    window.requestDataUpdate();
                }

                function changeToDate(clickedDateStr) {
                    if (!clickedDateStr) return;
                    let currentIso = getIsoDate(window.activeDate);
                    if (clickedDateStr === currentIso) return;
                    let dCurrent = new Date(currentIso + "T12:00:00");
                    let dClicked = new Date(clickedDateStr + "T12:00:00");
                    let diffDays = Math.round((dClicked - dCurrent) / (1000 * 60 * 60 * 24));
                    if (diffDays !== 0) changeDay(diffDays);
                }

                Timer {
                    id: firstLoadTimer
                    interval: 1000
                    onTriggered: window.isFirstLoad = false
                }

                ListModel { id: appListModel }
                ListModel { id: weekAppListModel }
                ListModel { id: weekListModel }
                ListModel { id: monthListModel }

                function syncAppsModel() {
                    for (let i = 0; i < window.topApps.length; i++) {
                        let app = window.topApps[i];
                        if (i < appListModel.count) {
                            appListModel.setProperty(i, "name", app.name);
                            appListModel.setProperty(i, "appClass", app.class);
                            appListModel.setProperty(i, "icon", app.icon || "");
                            appListModel.setProperty(i, "seconds", app.seconds);
                            appListModel.setProperty(i, "percent", app.percent);
                        } else {
                            appListModel.append({
                                name: app.name,
                                appClass: app.class,
                                icon: app.icon || "",
                                seconds: app.seconds,
                                percent: app.percent,
                                idx: i
                            });
                        }
                    }
                    while (appListModel.count > window.topApps.length) {
                        appListModel.remove(appListModel.count - 1);
                    }
                }

                function syncWeekAppsModel() {
                    for (let i = 0; i < window.weekAppsData.length; i++) {
                        let app = window.weekAppsData[i];
                        if (i < weekAppListModel.count) {
                            weekAppListModel.setProperty(i, "name", app.name);
                            weekAppListModel.setProperty(i, "appClass", app.class);
                            weekAppListModel.setProperty(i, "icon", app.icon || "");
                            weekAppListModel.setProperty(i, "seconds", app.seconds);
                            weekAppListModel.setProperty(i, "percent", app.percent);
                        } else {
                            weekAppListModel.append({
                                name: app.name,
                                appClass: app.class,
                                icon: app.icon || "",
                                seconds: app.seconds,
                                percent: app.percent,
                                idx: i
                            });
                        }
                    }
                    while (weekAppListModel.count > window.weekAppsData.length) {
                        weekAppListModel.remove(weekAppListModel.count - 1);
                    }
                }

                function syncWeekModel() {
                    let currentMax = 1;
                    for (let i = 0; i < window.weekData.length; i++) {
                        if (window.weekData[i].total > currentMax) currentMax = window.weekData[i].total;
                    }
                    window.maxWeekTotal = currentMax;

                    for (let i = 0; i < window.weekData.length; i++) {
                        let w = window.weekData[i];
                        if (i < weekListModel.count) {
                            weekListModel.setProperty(i, "dateStr", w.date);
                            weekListModel.setProperty(i, "dayName", w.day);
                            weekListModel.setProperty(i, "total", w.total);
                            weekListModel.setProperty(i, "isTarget", w.is_target);
                        } else {
                            weekListModel.append({
                                dateStr: w.date,
                                dayName: w.day,
                                total: w.total,
                                isTarget: w.is_target
                            });
                        }
                    }
                    while (weekListModel.count > window.weekData.length) {
                        weekListModel.remove(weekListModel.count - 1);
                    }
                }

                function syncMonthModel() {
                    let currentMax = 1;
                    for (let i = 0; i < window.monthData.length; i++) {
                        if (window.monthData[i].total > currentMax) currentMax = window.monthData[i].total;
                    }
                    window.maxMonthTotal = currentMax;

                    for (let i = 0; i < window.monthData.length; i++) {
                        let m = window.monthData[i];
                        if (i < monthListModel.count) {
                            monthListModel.setProperty(i, "dateStr", m.date);
                            monthListModel.setProperty(i, "total", m.total);
                            monthListModel.setProperty(i, "isTarget", m.is_target);
                        } else {
                            monthListModel.append({
                                dateStr: m.date,
                                total: m.total,
                                isTarget: m.is_target
                            });
                        }
                    }
                    while (monthListModel.count > window.monthData.length) {
                        monthListModel.remove(monthListModel.count - 1);
                    }
                }

                function formatTimeLarge(secs) {
                    let h = Math.floor(secs / 3600);
                    let m = Math.floor((secs % 3600) / 60);
                    if (h > 0) return h + "h " + m + "m";
                    return m + "m";
                }

                function formatTimeList(secs) {
                    let h = Math.floor(secs / 3600);
                    let m = Math.floor((secs % 3600) / 60);
                    if (h > 0) return h + "h " + m.toString().padStart(2, '0') + "m";
                    return m + "m";
                }

                // -----------------------------------------------------------------
                // KEYBOARD SHORTCUTS
                // -----------------------------------------------------------------
                Shortcut { sequence: "Left"; onActivated: window.changeDay(window.isWeekView ? -7 : -1) }
                Shortcut { sequence: "Right"; onActivated: window.changeDay(window.isWeekView ? 7 : 1) }
                Shortcut { sequence: "Home"; onActivated: window.changeDay(-7) }
                Shortcut { sequence: "End"; onActivated: window.changeDay(7) }

                Shortcut {
                    sequence: "Escape"
                    context: Qt.ApplicationShortcut
                    onActivated: {
                        if (window.selectedAppClass !== "") {
                            window.selectedAppClass = "";
                            window.selectedAppName = "";
                            window.selectedAppIcon = "";
                            window.requestDataUpdate();
                        } else if (window.isWeekView) {
                            window.isWeekView = false;
                        } else {
                            focustimeRoot.hide();
                        }
                    }
                }

                // -----------------------------------------------------------------
                // UI LAYOUT
                // -----------------------------------------------------------------
                Item {
                    anchors.fill: parent
                    scale: 0.97 + (0.03 * introMain)
                    opacity: introMain

                    Item {
                        anchors.fill: parent

                        ShapeCanvas {
                            id: cardShapeCanvas
                            anchors.fill: parent
                            polygonIsNormalized: false
                            color: window.crust
                            borderWidth: 1
                            borderColor: Qt.alpha(window.surface1, 0.2)
                            roundedPolygon: window.squirclePolygon(parent.width, parent.height)
                            onWidthChanged: roundedPolygon = window.squirclePolygon(parent.width, parent.height)
                            onHeightChanged: roundedPolygon = window.squirclePolygon(parent.width, parent.height)
                        }

                        Item {
                            id: cardContent
                            anchors.fill: parent
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: OpacityMask {
                                maskSource: ShapeCanvas {
                                    id: cardMask
                                    polygonIsNormalized: false
                                    width: cardContent.width
                                    height: cardContent.height
                                    color: "white"
                                    roundedPolygon: window.squirclePolygon(width, height)
                                    onWidthChanged: roundedPolygon = window.squirclePolygon(width, height)
                                    onHeightChanged: roundedPolygon = window.squirclePolygon(width, height)
                                }
                            }

                            Rectangle {
                                width: parent.width * 1.2; height: width; radius: width / 2
                                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
                                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
                                opacity: 0.015
                                color: window.mauve
                            }
                            Rectangle {
                                width: parent.width * 1.1; height: width; radius: width / 2
                                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
                                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
                                opacity: 0.010
                                color: window.blue
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: window.s(24)
                                spacing: window.s(16)

                            // ==========================================
                            // 1. HEADER
                            // ==========================================
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: window.s(4)
                                Layout.preferredHeight: window.s(40)

                                opacity: introHeader
                                transform: Translate { y: window.s(-20) * (1 - introHeader) }

                                RowLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: window.s(4)

                                    Item {
                                        Layout.preferredWidth: window.s(40)
                                        Layout.preferredHeight: window.s(40)

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: window.s(20)
                                            color: backMa.containsMouse ? window.surface0 : "transparent"
                                            opacity: (window.selectedAppClass !== "" || window.isWeekView) ? 1.0 : 0.0
                                            visible: opacity > 0
                                            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰁍"; color: window.text; font.pixelSize: window.s(18) }
                                            MouseArea {
                                                id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor;
                                                onClicked: {
                                                    if (window.selectedAppClass !== "") {
                                                        window.selectedAppClass = "";
                                                        window.selectedAppName = "";
                                                        window.selectedAppIcon = "";
                                                        window.requestDataUpdate();
                                                    } else if (window.isWeekView) {
                                                        window.isWeekView = false;
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: window.s(20)
                                            color: weekMa.containsMouse ? window.surface0 : "transparent"
                                            opacity: (window.selectedAppClass === "" && !window.isWeekView) ? 1.0 : 0.0
                                            visible: opacity > 0
                                            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰃭"; color: window.text; font.pixelSize: window.s(18) }
                                            MouseArea {
                                                id: weekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor;
                                                onClicked: window.isWeekView = true
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: window.s(40)
                                        Layout.preferredHeight: window.s(40)
                                        radius: window.s(20)
                                        color: prevWeekMa.containsMouse ? window.surface0 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰅁"; color: window.text; font.pixelSize: window.s(18) }
                                        MouseArea { id: prevWeekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: changeDay(window.isWeekView ? -7 : -1) }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: window.s(8)

                                    Item { Layout.fillWidth: true }

                                    Image {
                                        property bool active: window.selectedAppClass !== "" && window.selectedAppIcon !== "" && !window.isWeekView
                                        property real animWidth: active ? window.s(20) : 0
                                        Behavior on animWidth { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

                                        source: window.selectedAppIcon.startsWith("/") ? "file://" + window.selectedAppIcon : "image://icon/" + window.selectedAppIcon
                                        sourceSize: Qt.size(window.s(20), window.s(20))
                                        Layout.preferredWidth: animWidth
                                        Layout.preferredHeight: window.s(20)
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.rightMargin: active ? window.s(8) : 0
                                        opacity: animWidth / window.s(20.0)
                                        visible: animWidth > 0
                                        fillMode: Image.PreserveAspectFit
                                        clip: true
                                    }

                                    Text {
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                        font.pixelSize: window.s(18)
                                        color: window.text
                                        text: window.isWeekView ? (window.weekRangeStr !== "" ? window.weekRangeStr : "Week Overview") : (window.selectedAppClass !== "" ? `${window.selectedAppName} - ${window.getFancyDate(window.activeDate)}` : window.getFancyDate(window.activeDate))
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                Rectangle {
                                    Layout.preferredWidth: window.s(40)
                                    Layout.preferredHeight: window.s(40)
                                    radius: window.s(20)
                                    color: nextWeekMa.containsMouse ? window.surface0 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰅂"; color: window.text; font.pixelSize: window.s(18) }
                                    MouseArea { id: nextWeekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: changeDay(window.isWeekView ? 7 : 1) }
                                }
                            }

                            // ==========================================
                            // MASTER VIEW CONTAINER
                            // ==========================================
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // ==========================================
                                // NORMAL DAILY & APP VIEW WRAPPER
                                // ==========================================
                                ColumnLayout {
                                    id: dailyViewWrapper
                                    anchors.fill: parent
                                    spacing: window.s(16)

                                    opacity: 1.0 - window.weekViewFocus
                                    visible: opacity > 0
                                    transform: Translate { x: window.s(-40) * window.weekViewFocus }
                                    scale: 0.95 + (0.05 * (1.0 - window.weekViewFocus))

                                    // ==========================================
                                    // 1.5 TOTAL TIME DISPLAY + AVERAGES (3 BOXES)
                                    // ==========================================
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: window.s(90)
                                        Layout.maximumHeight: window.s(90)
                                        Layout.minimumHeight: window.s(90)
                                        spacing: window.s(16)

                                        opacity: introStats
                                        transform: Translate { y: window.s(30) * (1 - introStats) }

                                        // LEFT: Daily Average
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: window.s(200)
                                            radius: window.s(14)
                                            color: window.base
                                            border.color: Qt.alpha(window.surface1, 0.3)
                                            border.width: 1

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: window.s(2)
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.DemiBold
                                                    font.pixelSize: window.s(14)
                                                    color: window.subtext0
                                                    text: "Daily average"
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: window.s(20)
                                                    color: window.text
                                                    text: window.formatTimeList(window.averageSeconds)
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Medium
                                                    font.pixelSize: window.s(12)
                                                    color: window.overlay0
                                                    text: window.weekRangeStr
                                                    visible: window.weekRangeStr !== ""
                                                }
                                            }
                                        }

                                        // CENTER: Usage Time
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: window.s(300)
                                            radius: window.s(14)
                                            color: window.base
                                            border.color: Qt.alpha(window.surface1, 0.3)
                                            border.width: 1

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 0
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Black
                                                    font.pixelSize: window.s(36)
                                                    color: window.text
                                                    text: window.formatTimeLarge(window.animatedTotalSeconds)
                                                }
                                            }
                                        }

                                        // RIGHT: vs Yesterday Increase
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: window.s(200)
                                            radius: window.s(14)
                                            color: window.base
                                            border.color: Qt.alpha(window.surface1, 0.3)
                                            border.width: 1

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: window.s(8)

                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    spacing: window.s(8)
                                                    visible: !(window.totalSeconds === 0 && window.yesterdaySeconds === 0) && window.totalSeconds !== window.yesterdaySeconds

                                                    Text {
                                                        font.family: "JetBrains Mono"
                                                        font.weight: Font.Black
                                                        font.pixelSize: window.s(28)
                                                        color: {
                                                            let diff = window.totalSeconds - window.yesterdaySeconds;
                                                            return diff > 0 ? window.peach : window.green;
                                                        }
                                                        text: (window.totalSeconds - window.yesterdaySeconds) > 0 ? "↑" : "↓"
                                                    }

                                                    Text {
                                                        font.family: "JetBrains Mono"
                                                        font.weight: Font.Bold
                                                        font.pixelSize: window.s(28)
                                                        color: {
                                                            let diff = window.totalSeconds - window.yesterdaySeconds;
                                                            return diff > 0 ? window.peach : window.green;
                                                        }
                                                        text: {
                                                            let diff = window.totalSeconds - window.yesterdaySeconds;
                                                            return window.formatTimeList(Math.abs(diff));
                                                        }
                                                    }
                                                }

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.DemiBold
                                                    font.pixelSize: window.s(15)
                                                    color: window.overlay0
                                                    text: (window.totalSeconds === 0 && window.yesterdaySeconds === 0) ? "No data" : "Same time"
                                                    visible: (window.totalSeconds === 0 && window.yesterdaySeconds === 0) || window.totalSeconds === window.yesterdaySeconds
                                                }
                                            }
                                        }
                                    }

                                    // ==========================================
                                    // 2. MIDDLE CHARTS (Week + Heatmap)
                                    // ==========================================
                                    RowLayout {
                                        id: middleSection
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: window.s(160)
                                        Layout.fillHeight: false
                                        spacing: window.s(16)

                                        // LEFT: Weekly Bar Chart
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: window.s(400)
                                            radius: window.s(14)
                                            color: window.base
                                            border.color: Qt.alpha(window.surface1, 0.3)
                                            border.width: 1

                                            opacity: introMidLeft
                                            transform: Translate { x: window.s(-30) * (1 - introMidLeft) }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                height: parent.height - window.s(32)
                                                spacing: window.s(12)

                                                Repeater {
                                                    model: weekListModel
                                                    delegate: Item {
                                                        Layout.fillHeight: true
                                                        Layout.preferredWidth: window.s(45)

                                                        MouseArea {
                                                            id: barMa
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                window.changeToDate(model.dateStr);
                                                            }
                                                        }

                                                        Item {
                                                            anchors.bottom: dayLbl.top
                                                            anchors.bottomMargin: window.s(8)
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            width: window.s(45)
                                                            height: Math.max(window.s(4), (parent.height - window.s(25)) * (model.total / Math.max(window.maxWeekTotal, 1)) * window.introAppBars)
                                                            Behavior on height {
                                                                enabled: window.introAppBars === 1.0
                                                                NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
                                                            }

                                                            Rectangle {
                                                                anchors.fill: parent
                                                                radius: window.s(4)
                                                                color: window.surface0
                                                                visible: !model.isTarget
                                                                opacity: barMa.containsMouse ? 0.7 : 1.0
                                                                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                                            }

                                                            Rectangle {
                                                                anchors.fill: parent
                                                                radius: window.s(4)
                                                                visible: model.isTarget
                                                                opacity: barMa.containsMouse ? 0.7 : 1.0
                                                                gradient: Gradient {
                                                                    GradientStop { position: 0.0; color: window.mauve }
                                                                    GradientStop { position: 1.0; color: window.blue }
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            id: dayLbl
                                                            anchors.bottom: parent.bottom
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.DemiBold
                                                            font.pixelSize: window.s(12)
                                                            color: model.isTarget ? window.text : window.overlay0
                                                            text: model.dayName
                                                            Behavior on color { ColorAnimation { duration: 400 } }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // RIGHT: Calendar Month Heatmap
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: window.s(300)
                                            radius: window.s(14)
                                            color: window.base
                                            border.color: Qt.alpha(window.surface1, 0.3)
                                            border.width: 1

                                            opacity: introMidRight
                                            transform: Translate { x: window.s(30) * (1 - introMidRight) }

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: window.s(12)
                                                spacing: window.s(8)

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.DemiBold
                                                    font.pixelSize: window.s(14)
                                                    color: window.text
                                                    text: window.monthNames[window.activeDate.getMonth()]
                                                }

                                                Grid {
                                                    Layout.alignment: Qt.AlignCenter
                                                    columns: 7
                                                    flow: Grid.LeftToRight
                                                    spacing: window.s(6)

                                                    Repeater {
                                                        model: monthListModel
                                                        delegate: Rectangle {
                                                            width: window.s(18)
                                                            height: window.s(18)
                                                            radius: window.s(4)
                                                            color: model.total === -1 ? "transparent" : (model.total === 0 ? window.surface0 : Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, Math.min(1.0, 0.3 + 0.7 * (model.total / window.maxMonthTotal))))
                                                            Behavior on color { ColorAnimation { duration: 700; easing.type: Easing.OutQuint } }

                                                            border.color: model.isTarget ? window.text : "transparent"
                                                            border.width: model.isTarget ? 1 : 0
                                                            Behavior on border.color { ColorAnimation { duration: 300 } }

                                                            visible: model.total !== -1

                                                            scale: 0.7 + (0.3 * introMidRight)

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                enabled: model.total !== -1
                                                                onClicked: {
                                                                    if (model.total !== -1) {
                                                                        window.changeToDate(model.dateStr);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ==========================================
                                    // 3. BOTTOM CARD (App List OR Hourly Chart)
                                    // ==========================================
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: window.s(14)
                                        color: window.base
                                        border.color: Qt.alpha(window.surface1, 0.3)
                                        border.width: 1

                                        opacity: introBottom
                                        transform: Translate { y: window.s(30) * (1 - introBottom) }

                                        Item {
                                            anchors.fill: parent

                                            // --- VIEW A: App List ---
                                            ListView {
                                                id: appList
                                                anchors.fill: parent
                                                anchors.margins: window.s(8)
                                                anchors.topMargin: window.s(12)
                                                anchors.bottomMargin: window.s(12)

                                                opacity: 1.0 - window.appViewFocus
                                                visible: opacity > 0
                                                transform: Translate { x: window.s(-30) * window.appViewFocus }
                                                scale: 0.95 + (0.05 * (1.0 - window.appViewFocus))

                                                model: appListModel
                                                interactive: true
                                                clip: true
                                                spacing: window.s(2)

                                                move: Transition { NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutQuint } }

                                                ScrollBar.vertical: ScrollBar {
                                                    active: appList.moving || appList.movingVertically
                                                    width: window.s(4)
                                                    policy: ScrollBar.AsNeeded
                                                    contentItem: Rectangle { implicitWidth: window.s(4); radius: window.s(2); color: window.surface2 }
                                                }

                                                delegate: Rectangle {
                                                    width: ListView.view.width
                                                    height: window.s(58)
                                                    color: "transparent"
                                                    radius: window.s(10)

                                                    opacity: introBottom
                                                    transform: Translate { y: (index * window.s(12)) * (1 - introBottom) }

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: window.s(10)
                                                        color: rowMa.containsMouse ? window.surface0 : "transparent"
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                    }

                                                    MouseArea {
                                                        id: rowMa
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            window.selectedAppClass = model.appClass;
                                                            window.selectedAppName = model.name;
                                                            window.selectedAppIcon = model.icon;
                                                            window.appDate = new Date();
                                                            window.requestDataUpdate();
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: window.s(16)
                                                        anchors.rightMargin: window.s(16)
                                                        anchors.topMargin: window.s(10)
                                                        anchors.bottomMargin: window.s(10)
                                                        spacing: window.s(6)

                                                        RowLayout {
                                                            Layout.fillWidth: true

                                                            Image {
                                                                visible: model.icon !== ""
                                                                source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                                                sourceSize: Qt.size(window.s(20), window.s(20))
                                                                Layout.preferredWidth: window.s(20)
                                                                Layout.preferredHeight: window.s(20)
                                                                Layout.alignment: Qt.AlignVCenter
                                                                Layout.rightMargin: window.s(8)
                                                                fillMode: Image.PreserveAspectFit
                                                            }

                                                            Text {
                                                                Layout.fillWidth: true
                                                                font.family: "JetBrains Mono"
                                                                font.weight: Font.DemiBold
                                                                font.pixelSize: window.s(15)
                                                                color: window.text
                                                                text: model.name
                                                                elide: Text.ElideRight
                                                            }
                                                            Text {
                                                                font.family: "JetBrains Mono"
                                                                font.weight: Font.Medium
                                                                font.pixelSize: window.s(14)
                                                                color: window.subtext0
                                                                text: window.formatTimeList(model.seconds)
                                                            }
                                                        }

                                                        Item {
                                                            Layout.fillWidth: true
                                                            height: window.s(10)
                                                            Rectangle { anchors.fill: parent; radius: window.s(5); color: window.crust }
                                                            Rectangle {
                                                                height: parent.height
                                                                width: Math.max(window.s(10), parent.width * (model.percent / 100.0) * window.introAppBars)
                                                                radius: window.s(5)
                                                                gradient: Gradient {
                                                                    orientation: Gradient.Horizontal
                                                                    GradientStop { position: 0.0; color: window.mauve }
                                                                    GradientStop { position: 1.0; color: window.blue }
                                                                }
                                                                Behavior on width {
                                                                    enabled: window.introAppBars === 1.0
                                                                    NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // --- VIEW B: 24-Hour App Activity Chart (48 chunks / 30 mins) ---
                                            ColumnLayout {
                                                id: appChartWrapper
                                                anchors.fill: parent
                                                anchors.margins: window.s(16)
                                                spacing: window.s(12)

                                                opacity: window.appViewFocus
                                                visible: opacity > 0
                                                transform: Translate { x: window.s(30) * (1 - window.appViewFocus) }
                                                scale: 0.95 + (0.05 * window.appViewFocus)

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.DemiBold
                                                    font.pixelSize: window.s(14)
                                                    color: window.text
                                                    text: "Daily usage"
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    spacing: window.s(4)

                                                    Repeater {
                                                        model: 48
                                                        delegate: Item {
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true

                                                            Rectangle {
                                                                anchors.bottom: parent.bottom
                                                                width: parent.width
                                                                height: Math.max(window.s(4), parent.height * (window.hourlyData[index] / Math.max(window.maxHourlyTotal, 1)) * window.introAppBars)
                                                                radius: window.s(2)
                                                                color: window.hourlyData[index] > 0 ? window.blue : window.surface0

                                                                Behavior on height {
                                                                    enabled: window.introAppBars === 1.0
                                                                    NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
                                                                }
                                                                Behavior on color { ColorAnimation { duration: 400 } }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    onEntered: { parent.opacity = 0.7 }
                                                                    onExited: { parent.opacity = 1.0 }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "00:00" }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "06:00" }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "12:00" }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "18:00" }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "23:00" }
                                                }
                                            }
                                        }
                                    }
                                } // End of Daily View Wrapper

                                // ==========================================
                                // WEEK VIEW WRAPPER
                                // ==========================================
                                ColumnLayout {
                                    id: weekViewWrapper
                                    anchors.fill: parent
                                    spacing: window.s(16)

                                    opacity: window.weekViewFocus
                                    visible: opacity > 0
                                    transform: Translate { x: window.s(40) * (1 - window.weekViewFocus) }
                                    scale: 0.95 + (0.05 * window.weekViewFocus)

                                    // Week Heatmap Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: window.s(260)
                                        radius: window.s(14)
                                        color: window.base
                                        border.color: Qt.alpha(window.surface1, 0.3)
                                        border.width: 1

                                        opacity: introMidLeft
                                        transform: Translate { y: window.s(20) * (1 - introMidLeft) }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: window.s(16)
                                            spacing: window.s(16)

                                            // LEFT SIDE: Heatmap + X-Axis
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                spacing: window.s(6)

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    spacing: window.s(4)

                                                    Repeater {
                                                        model: 7
                                                        delegate: RowLayout {
                                                            property int dayIndex: index
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            spacing: window.s(8)

                                                            opacity: introMidLeft
                                                            transform: Translate { x: window.s(-20) * (1 - introMidLeft) + (dayIndex * window.s(5) * (1 - introMidLeft)) }

                                                            Text {
                                                                text: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][dayIndex]
                                                                font.family: "JetBrains Mono"
                                                                font.weight: Font.Normal
                                                                font.pixelSize: window.s(12)
                                                                color: window.subtext0
                                                                Layout.preferredWidth: window.s(75)
                                                                verticalAlignment: Text.AlignVCenter
                                                            }

                                                            Rectangle {
                                                                Layout.fillWidth: true
                                                                Layout.fillHeight: true
                                                                radius: window.s(10)
                                                                color: "transparent"
                                                                clip: true

                                                                RowLayout {
                                                                    anchors.fill: parent
                                                                    spacing: 0

                                                                    Repeater {
                                                                        model: 24
                                                                        delegate: Rectangle {
                                                                            Layout.fillWidth: true
                                                                            Layout.fillHeight: true
                                                                            radius: 0

                                                                            property real val: (window.weekHeatmapData[dayIndex] && window.weekHeatmapData[dayIndex][index]) ? window.weekHeatmapData[dayIndex][index] : 0
                                                                            property real intensity: Math.min(1.0, 0.2 + 0.8 * (val / Math.max(window.maxWeekHour, 1)))
                                                                            color: val === 0 ? window.surface0 : Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, intensity)

                                                                            scale: window.isWeekView ? 1.0 : 0.5
                                                                            Behavior on scale {
                                                                                NumberAnimation {
                                                                                    duration: 400 + (dayIndex * 30) + (index * 10)
                                                                                    easing.type: Easing.OutBack
                                                                                }
                                                                            }
                                                                            Behavior on color { ColorAnimation { duration: 600; easing.type: Easing.OutQuint } }

                                                                            MouseArea {
                                                                                anchors.fill: parent
                                                                                hoverEnabled: true
                                                                                onEntered: parent.opacity = 0.7
                                                                                onExited: parent.opacity = 1.0
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // X-axis labels
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 0

                                                    Item { Layout.preferredWidth: window.s(75 + 8) }

                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "00:00"; Layout.alignment: Qt.AlignLeft }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "06:00"; Layout.alignment: Qt.AlignHCenter }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "12:00"; Layout.alignment: Qt.AlignHCenter }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "18:00"; Layout.alignment: Qt.AlignHCenter }
                                                    Item { Layout.fillWidth: true }
                                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: window.s(11); color: window.overlay0; text: "23:00"; Layout.alignment: Qt.AlignRight }
                                                }
                                            }

                                            // RIGHT SIDE: Stats Column
                                            ColumnLayout {
                                                Layout.preferredWidth: window.s(120)
                                                Layout.fillHeight: true
                                                spacing: window.s(12)

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: window.s(10)
                                                    color: window.surface0

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: window.s(4)
                                                        Text {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.Medium
                                                            font.pixelSize: window.s(12)
                                                            color: window.subtext0
                                                            text: "Daily average"
                                                        }
                                                        Text {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.Bold
                                                            font.pixelSize: window.s(18)
                                                            color: window.text
                                                            text: window.formatTimeList(window.averageSeconds)
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: window.s(10)
                                                    color: window.surface0

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: window.s(4)
                                                        Text {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.Medium
                                                            font.pixelSize: window.s(12)
                                                            color: window.subtext0
                                                            text: "Peak hours"
                                                        }
                                                        Text {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.Bold
                                                            font.pixelSize: window.s(14)
                                                            color: window.text
                                                            text: window.peakUsageHours
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Week Top Apps Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: window.s(14)
                                        color: window.base
                                        border.color: Qt.alpha(window.surface1, 0.3)
                                        border.width: 1

                                        opacity: introBottom
                                        transform: Translate { y: window.s(30) * (1 - introBottom) }

                                        ListView {
                                            id: weekAppList
                                            anchors.fill: parent
                                            anchors.margins: window.s(8)
                                            anchors.topMargin: window.s(12)
                                            anchors.bottomMargin: window.s(12)
                                            model: weekAppListModel
                                            interactive: true
                                            clip: true
                                            spacing: window.s(2)

                                            move: Transition { NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutQuint } }

                                            ScrollBar.vertical: ScrollBar {
                                                active: weekAppList.moving || weekAppList.movingVertically
                                                width: window.s(4)
                                                policy: ScrollBar.AsNeeded
                                                contentItem: Rectangle { implicitWidth: window.s(4); radius: window.s(2); color: window.surface2 }
                                            }

                                            delegate: Rectangle {
                                                width: ListView.view.width
                                                height: window.s(58)
                                                color: "transparent"
                                                radius: window.s(10)

                                                opacity: introBottom
                                                transform: Translate { y: (index * window.s(12)) * (1 - introBottom) }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: window.s(10)
                                                    color: weekRowMa.containsMouse ? window.surface0 : "transparent"
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }

                                                MouseArea {
                                                    id: weekRowMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        window.selectedAppClass = model.appClass;
                                                        window.selectedAppName = model.name;
                                                        window.selectedAppIcon = model.icon;
                                                        window.appDate = new Date();
                                                        window.isWeekView = false;
                                                        window.requestDataUpdate();
                                                    }
                                                }

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: window.s(16)
                                                    anchors.rightMargin: window.s(16)
                                                    anchors.topMargin: window.s(10)
                                                    anchors.bottomMargin: window.s(10)
                                                    spacing: window.s(6)

                                                    RowLayout {
                                                        Layout.fillWidth: true

                                                        Image {
                                                            visible: model.icon !== ""
                                                            source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                                            sourceSize: Qt.size(window.s(20), window.s(20))
                                                            Layout.preferredWidth: window.s(20)
                                                            Layout.preferredHeight: window.s(20)
                                                            Layout.alignment: Qt.AlignVCenter
                                                            Layout.rightMargin: window.s(8)
                                                            fillMode: Image.PreserveAspectFit
                                                        }

                                                        Text {
                                                            Layout.fillWidth: true
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.DemiBold
                                                            font.pixelSize: window.s(15)
                                                            color: window.text
                                                            text: model.name
                                                            elide: Text.ElideRight
                                                        }
                                                        Text {
                                                            font.family: "JetBrains Mono"
                                                            font.weight: Font.Medium
                                                            font.pixelSize: window.s(14)
                                                            color: window.subtext0
                                                            text: window.formatTimeList(model.seconds)
                                                        }
                                                    }

                                                    Item {
                                                        Layout.fillWidth: true
                                                        height: window.s(10)
                                                        Rectangle { anchors.fill: parent; radius: window.s(5); color: window.crust }
                                                        Rectangle {
                                                            height: parent.height
                                                            width: Math.max(window.s(10), parent.width * (model.percent / 100.0) * window.introAppBars)
                                                            radius: window.s(5)
                                                            gradient: Gradient {
                                                                orientation: Gradient.Horizontal
                                                                GradientStop { position: 0.0; color: window.mauve }
                                                                GradientStop { position: 1.0; color: window.blue }
                                                            }
                                                            Behavior on width {
                                                                enabled: window.introAppBars === 1.0
                                                                NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } // End Week View Wrapper
                            } // End Container Item
                                }
                            } // close cardContent Item
                        } // close card container Item
                    }
                }
            }
        }

    IpcHandler {
        target: "focustime"

        function toggle(): void {
            focustimeLoader.active = !focustimeLoader.active;
        }

        function close(): void {
            focustimeLoader.active = false;
        }

        function open(): void {
            focustimeLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "focustimeToggle"
        description: "Toggles focustime on press"

        onPressed: {
            focustimeLoader.active = !focustimeLoader.active;
        }
    }

    GlobalShortcut {
        name: "focustimeOpen"
        description: "Opens focustime on press"

        onPressed: {
            focustimeLoader.active = true;
        }
    }

    GlobalShortcut {
        name: "focustimeClose"
        description: "Closes focustime on press"

        onPressed: {
            focustimeLoader.active = false;
        }
    }
}
