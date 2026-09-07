pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple to-do list manager with Google Tasks 2-way sync support.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    readonly property string syncScriptPath: Quickshell.env("HOME") + "/.config/google-tasks-sync/sync.sh"

    function addItem(item) {
        list.push(item)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
        triggerSync()
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false,
        }
        addItem(item)
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
            triggerSync()
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
            triggerSync()
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
            triggerSync()
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    function triggerSync() {
        syncDebounce.restart()
    }

    Process {
        id: syncProc
        command: [root.syncScriptPath]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.refresh()
            }
        }
    }

    Timer {
        id: syncDebounce
        interval: 1000
        repeat: false
        onTriggered: {
            if (!syncProc.running) {
                syncProc.running = true
            }
        }
    }

    Timer {
        id: periodicSyncTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
            if (!syncProc.running) {
                syncProc.running = true
            }
        }
    }

    IpcHandler {
        target: "todoService"

        function update(): void {
            root.refresh()
        }

        function sync(): void {
            root.triggerSync()
        }
    }

    Component.onCompleted: {
        refresh()
        triggerSync()
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = todoFileView.text()
            root.list = JSON.parse(fileContents)
            console.log("[To Do] File loaded")
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.list = []
                todoFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[To Do] Error loading file: " + error)
            }
        }
    }
}
