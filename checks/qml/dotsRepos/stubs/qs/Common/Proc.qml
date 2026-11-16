pragma Singleton
import QtQuick
// Records every call; the status command answers with `statusOut`, anything
// else completes with `nextExit` and `nextOut`.
QtObject {
    property var calls: []
    property int nextExit: 0
    property string nextOut: ""
    property string statusOut: ""
    function runCommand(id, command, callback, debounceMs, timeoutMs, owner) {
        calls = calls.concat([{ id: id, command: command, timeout: timeoutMs }]);
        if (id === "dotsRepos.status")
            callback(statusOut, 0);
        else
            callback(nextOut, nextExit);
    }
    function reset() { calls = []; nextExit = 0; nextOut = ""; }
}
