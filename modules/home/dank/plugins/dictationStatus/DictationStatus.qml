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
// text, and turns into a warning when the daemon is down. While recording, the pill's
// background fills from the left (from the top on a vertical bar) as the recording
// nears voxtype's length limit, and turns orange for the last stretch: at the limit
// voxtype stops the recording on its own and transcribes what it has. It has no click
// action and no popout: starting and stopping is the niri bind.
PluginComponent {
    id: root

    // The command (an argv array) from this plugin's settings, set by
    // modules/home/dictation/default.nix. Kept as text: DMS re-reads the settings as
    // a fresh array now and then, which must not look like a change of command.
    readonly property string commandKey: JSON.stringify(pluginData.statusCommand || [])

    // The state voxtype last reported, "" until it has said anything.
    property string phase: ""
    readonly property bool recording: phase === "recording" || phase === "streaming"

    // How long voxtype lets one recording run before it stops it and transcribes what it
    // has (audio.max_duration_secs), from this plugin's settings. 0 when not given: then
    // no progress is shown.
    readonly property real maxDurationSecs: Number(pluginData.maxDurationSecs) || 0

    // The clock, in ms; replaceable so a test can drive time.
    property var clock: Date.now
    // When this recording was first seen, and how far into it we are (ms). The widget
    // counts from the moment it sees the state change, a few tens of ms after the
    // daemon's own timer starts; a widget started mid-recording (the shell restarted)
    // counts from when it first saw it.
    property real recordingSince: 0
    property real elapsedMs: 0
    // How far through the limit: 0 when not recording or no limit is known.
    readonly property real progress: (recording && maxDurationSecs > 0) ? Math.min(1, elapsedMs / (maxDurationSecs * 1000)) : 0
    // The last stretch before the limit, when the fill changes colour: 15 s, or a
    // quarter of a short limit.
    readonly property real warnSecs: Math.min(15, maxDurationSecs * 0.25)
    readonly property bool nearingLimit: progress > 0 && (maxDurationSecs * 1000 - elapsedMs) <= warnSecs * 1000

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

    // The progress fill's colour, before its transparency.
    readonly property color fillColor: nearingLimit ? Theme.warning : recordingColor

    onRecordingChanged: {
        recordingSince = recording ? clock() : 0;
        elapsedMs = 0;
    }

    function tick() {
        if (recording)
            elapsedMs = clock() - recordingSince;
    }

    Timer {
        interval: 100
        repeat: true
        running: root.recording && root.maxDurationSecs > 0
        onTriggered: root.tick()
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

        Item {
            id: content

            implicitWidth: icon.implicitWidth
            implicitHeight: icon.implicitHeight

            // DMS draws the pill's background in an item that is this one's
            // grandparent (the content loader sits between), centred on this item. The
            // fill is sized from it, so it covers the whole pill, padding included,
            // however the bar is configured. Without it (a different DMS) no fill.
            readonly property Item bar: parent && parent.parent ? parent.parent : null
            readonly property bool filled: root.progress > 0 && bar !== null

            // Nothing clips this item, so the fill can reach past its edges to the
            // pill's. It sits below the icon (z) and above the pill's own background.
            Rectangle {
                id: fill

                objectName: "progressFill"
                z: -1
                visible: content.filled
                radius: Theme.cornerRadius
                color: Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b, 0.4)
                x: content.bar ? (content.width - content.bar.width) / 2 : 0
                y: content.bar ? (content.height - content.bar.height) / 2 : 0
                width: content.bar ? (root.isVertical ? content.bar.width : content.bar.width * root.progress) : 0
                height: content.bar ? (root.isVertical ? content.bar.height * root.progress : content.bar.height) : 0
            }

            DankIcon {
                id: icon

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
    }

    horizontalBarPill: pill
    verticalBarPill: pill
}
