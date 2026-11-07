import QtQuick
// Stands in for Quickshell's Process: nothing is run. The test feeds it lines and
// makes it exit.
QtObject {
    readonly property bool isProcessStub: true
    property var command: []
    property bool running: false
    property QtObject stdout: null
    property int starts: 0
    property var startedWith: []
    signal exited(int exitCode, int exitStatus)
    onRunningChanged: {
        if (running) {
            starts += 1;
            startedWith = command;
        }
    }
    function emit(line) { stdout.read(line); }
    function die(code) { running = false; exited(code, 0); }
}
