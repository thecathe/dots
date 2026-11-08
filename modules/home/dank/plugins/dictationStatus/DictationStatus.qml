import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

// Bar indicator for voice dictation (dots.dictation). It keeps
// `voxtype status --follow --format json` running: voxtype prints one line when it
// starts and another whenever the daemon changes state. Only the state name (the
// "alt" field) is used: "idle", "recording", "transcribing", or "stopped" when the
// daemon is not running (voxtype works that out itself, so a crashed daemon does not
// leave the last state showing). The icon is a microphone that is dim while idle,
// pulses red while recording, becomes a waveform while the speech is turned into
// text, and turns into a warning when the daemon is down. It has no click action
// and no popout: starting and stopping is the niri bind.
PluginComponent {
    id: root

    // The command (an argv array) from this plugin's settings, set by
    // modules/home/dictation/default.nix. Kept as text: DMS re-reads the settings as
    // a fresh array now and then, which must not look like a change of command.
    readonly property string commandKey: JSON.stringify(pluginData.statusCommand || [])

    // The state voxtype last reported, "" until it has said anything.
    property string phase: ""
    readonly property bool recording: phase === "recording" || phase === "streaming"

    readonly property string iconName: {
        switch (phase) {
        case "transcribing":
            return "graphic_eq";
        case "stopped":
            return "mic_off";
        default:
            return "mic";
        }
    }

    // A fixed red, not Theme.error: that is a pastel in DMS's dark themes (#ffb4ab
    // in the live one), too close to the idle icon for the one state that means the
    // microphone is live.
    readonly property color recordingColor: "#ff4d4f"

    readonly property color iconColor: {
        if (recording)
            return recordingColor;
        if (phase === "transcribing")
            return Theme.primary;
        if (phase === "stopped")
            return Theme.warning;
        return Theme.surfaceVariantText;
    }

    function handleLine(line) {
        let message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            return;
        }
        // The daemon rewrites its state file in place, so voxtype can read it
        // between the truncation and the write and report an empty state a moment
        // before the real one. Ignore it rather than showing a flicker.
        if (typeof message.alt === "string" && message.alt !== "")
            phase = message.alt;
    }

    function start() {
        const argv = JSON.parse(commandKey);
        if (argv.length === 0 || follower.running)
            return;
        follower.command = argv;
        follower.running = true;
    }

    // Nothing to follow (the plugin enabled on a machine without dictation): hide.
    onCommandKeyChanged: {
        setVisibilityOverride(commandKey !== "[]");
        start();
    }

    Component.onCompleted: {
        setVisibilityOverride(commandKey !== "[]");
        start();
    }

    Process {
        id: follower

        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }

        // voxtype keeps running until it is killed, so an exit is unexpected (a
        // config it cannot read, or the binary gone after an update). Say so and
        // try again rather than leaving the last state on show.
        onExited: (exitCode, exitStatus) => {
            root.phase = "stopped";
            retry.restart();
        }
    }

    // How long to wait before running the command again after it exits (ms).
    property int retryInterval: 5000

    Timer {
        id: retry
        interval: root.retryInterval
        onTriggered: root.start()
    }

    Component {
        id: pill

        DankIcon {
            name: root.iconName
            size: Theme.barIconSize(root.barThickness, -4)
            color: root.iconColor

            // A slow pulse while recording. alwaysRunToEnd lets the cycle in
            // progress finish when recording stops, so the icon never stays dimmed.
            SequentialAnimation on opacity {
                running: root.recording
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation {
                    to: 0.45
                    duration: 700
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1
                    duration: 700
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    horizontalBarPill: pill
    verticalBarPill: pill
}
