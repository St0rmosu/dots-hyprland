pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import Quickshell
import Quickshell.Hyprland

LockScreen {
    id: root

    // Monitor name -> workspace id to restore on unlock (set when locking)
    property var savedWorkspaces: ({})
    property string savedFocusedMonitor: ""

    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            var monToFocus = root.savedFocusedMonitor !== "" ? root.savedFocusedMonitor : (Quickshell.screens[0]?.name ?? "")
            var batch = "POS=$(hyprctl cursorpos 2>/dev/null); "
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var monName = Quickshell.screens[j].name
                var wsId = root.savedWorkspaces[monName]
                if (wsId !== undefined) {
                    batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${monName}"})'; hyprctl dispatch 'hl.dsp.focus({workspace=${wsId}})';`
                }
            }
            if (monToFocus !== "") {
                batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${monToFocus}"})';`
            }
            batch += `if [ -n "$POS" ]; then CUR_X=$(echo "$POS" | cut -d',' -f1 | tr -d ' '); CUR_Y=$(echo "$POS" | cut -d',' -f2 | tr -d ' '); hyprctl dispatch "hl.dsp.cursor.move({ x = $CUR_X, y = $CUR_Y })"; fi;`
            if (batch.length > 0) {
                Quickshell.execDetached(["bash", "-c", batch])
            }
        }
    }

    lockSurface: LockSurface {
        context: root.context
    }

    // Single batch for lock and unlock so we don't race multiple hyprctl calls
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Lock: save workspace per monitor and move all to temp workspace in one batch
                var next = {}
                var initialFocusedMon = HyprlandData.monitors.find(m => m.focused)?.name ?? Quickshell.screens[0]?.name ?? ""
                root.savedFocusedMonitor = initialFocusedMon
                var batch = "POS=$(hyprctl cursorpos 2>/dev/null); keyword animation workspaces,1,7,menu_decel,slidevert; "
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var mon = Quickshell.screens[i].name
                    var mData = HyprlandData.monitors.find(m => m.name === mon)
                    if (mData?.activeWorkspace == undefined) {
                        return;
                    }
                    var ws = (mData?.activeWorkspace?.id ?? 1)
                    next[mon] = ws
                    batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${mon}"})'; hyprctl dispatch 'hl.dsp.focus({workspace=${2147483647 - ws}})';`
                }
                if (initialFocusedMon !== "") {
                    batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${initialFocusedMon}"})';`
                }
                batch += `if [ -n "$POS" ]; then CUR_X=$(echo "$POS" | cut -d',' -f1 | tr -d ' '); CUR_Y=$(echo "$POS" | cut -d',' -f2 | tr -d ' '); hyprctl dispatch "hl.dsp.cursor.move({ x = $CUR_X, y = $CUR_Y })"; fi;`
                root.savedWorkspaces = next
                Quickshell.execDetached(["bash", "-c", batch])
            } else {
                restoreTimer.start()
            }
        }
    }

    // Push everything down (visual only; workspace switch is in Connections above)
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property ShellScreen modelData
            property bool shouldPush: GlobalStates.screenLocked
            property string targetMonitorName: modelData.name
            property int verticalMovementDistance: modelData.height
            property int horizontalSqueeze: modelData.width * 0.2
        }
    }
}
