pragma Singleton
import QtQuick
// Records every call; the status command answers with a fixed table, anything
// else completes with `nextExit`.
QtObject {
    property var calls: []
    property int nextExit: 0
    property string statusOut: "tailscale up\ngp down\nmc up\n"
    function runCommand(id, command, callback, debounceMs, timeoutMs, owner) {
        calls = calls.concat([{ id: id, command: command, timeout: timeoutMs }]);
        if (id === "dotsServices.status")
            callback(statusOut, 0);
        else
            callback("", nextExit);
    }
    function reset() { calls = []; nextExit = 0; }
}
