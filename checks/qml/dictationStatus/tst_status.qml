import QtQuick
import QtTest
import qs.Common

TestCase {
    id: tc
    name: "DictationStatus"
    width: 200
    height: 200
    visible: true
    when: windowShown

    readonly property string pluginUrl: Qt.resolvedUrl("../../../modules/home/dank/plugins/dictationStatus/DictationStatus.qml")
    readonly property var argv: ["/store/voxtype", "status", "--follow", "--format", "json"]

    // What voxtype prints for a state (the real binary's format, from its source and a run).
    function line(alt) {
        return '{"text": "x", "alt": "' + alt + '", "class": "' + alt + '", "tooltip": "t"}';
    }

    property var plugin: null
    property var proc: null

    function make(data) {
        const component = Qt.createComponent(pluginUrl);
        compare(component.status, Component.Ready, component.errorString());
        const item = component.createObject(tc, { pluginData: data, retryInterval: 50 });
        verify(item !== null, "plugin did not load");
        return item;
    }
    function processOf(item) {
        for (let i = 0; i < item.data.length; i++)
            if (item.data[i].isProcessStub)
                return item.data[i];
        return null;
    }
    function init() {
        plugin = make({ statusCommand: argv });
        proc = processOf(plugin);
        verify(proc !== null, "no process in the plugin");
    }
    function cleanup() {
        plugin.destroy();
        plugin = null;
        proc = null;
    }
    function color(c) { return String(c); }

    function test_starts_the_command_once_loaded() {
        compare(proc.running, true);
        compare(proc.starts, 1);
        compare(proc.startedWith, argv);
        // DMS's own Component.onCompleted and the plugin's both ran.
        compare(plugin.baseCompleted, true);
        compare(plugin.visibilityOverride, true);
    }

    function test_nothing_to_follow_hides_the_widget() {
        const empty = make({});
        compare(processOf(empty).starts, 0);
        compare(processOf(empty).running, false);
        compare(empty.visibilityOverride, false);
        empty.destroy();
    }

    function test_command_arriving_after_creation_starts_it() {
        const late = make({});
        compare(processOf(late).starts, 0);
        late.pluginData = { statusCommand: argv };
        compare(processOf(late).starts, 1);
        compare(late.visibilityOverride, true);
        late.destroy();
    }

    function test_rereading_the_same_settings_does_not_restart() {
        plugin.pluginData = { statusCommand: argv.slice() };
        plugin.pluginData = { statusCommand: argv.slice() };
        compare(proc.starts, 1);
        compare(proc.running, true);
    }

    function test_each_state_has_its_own_look() {
        const cases = [
            { alt: "idle", icon: "mic", colour: Theme.surfaceVariantText, recording: false },
            { alt: "recording", icon: "mic", colour: Theme.error, recording: true },
            { alt: "streaming", icon: "mic", colour: Theme.error, recording: true },
            { alt: "transcribing", icon: "graphic_eq", colour: Theme.primary, recording: false },
            { alt: "stopped", icon: "mic_off", colour: Theme.warning, recording: false },
        ];
        const icon = plugin.horizontalBarPill.createObject(tc);
        for (const c of cases) {
            proc.emit(line(c.alt));
            compare(plugin.phase, c.alt);
            compare(plugin.recording, c.recording, c.alt);
            // The pill follows the plugin, it is not a snapshot.
            compare(icon.name, c.icon, c.alt);
            compare(color(icon.color), color(c.colour), c.alt);
        }
        icon.destroy();
    }

    function test_the_vertical_bar_shows_the_same_icon() {
        proc.emit(line("transcribing"));
        const icon = plugin.verticalBarPill.createObject(tc);
        compare(icon.name, "graphic_eq");
        compare(icon.size, plugin.barThickness - 4);
        icon.destroy();
    }

    function test_lines_that_say_nothing_are_ignored() {
        proc.emit(line("recording"));
        // voxtype can read its state file between the daemon truncating and writing it
        // (seen in a real run), which prints an empty state.
        proc.emit(line(""));
        compare(plugin.phase, "recording");
        proc.emit("not json at all");
        proc.emit("");
        proc.emit("{}");
        proc.emit('{"alt": 7}');
        compare(plugin.phase, "recording");
    }

    function test_an_unknown_state_looks_idle() {
        // voxtype draws a state it does not know with the idle icon; so does the widget.
        proc.emit(line("paused"));
        compare(plugin.recording, false);
        compare(plugin.iconName, "mic");
        compare(color(plugin.iconColor), color(Theme.surfaceVariantText));
    }

    function test_the_command_exiting_shows_stopped_and_starts_it_again() {
        proc.emit(line("recording"));
        proc.die(1);
        compare(plugin.phase, "stopped");
        compare(proc.running, false);
        tryVerify(() => proc.starts === 2, 2000, "the command was not started again");
        compare(proc.running, true);
        // And it works again: the next line replaces "stopped".
        proc.emit(line("idle"));
        compare(plugin.phase, "idle");
    }

    function test_it_keeps_retrying_while_the_command_keeps_failing() {
        proc.die(127);
        tryVerify(() => proc.starts === 2, 2000);
        proc.die(127);
        tryVerify(() => proc.starts === 3, 2000);
        compare(plugin.phase, "stopped");
    }

    function test_the_icon_pulses_while_recording_and_ends_fully_opaque() {
        const icon = plugin.horizontalBarPill.createObject(tc);
        compare(icon.opacity, 1);
        proc.emit(line("recording"));
        tryVerify(() => icon.opacity < 0.9, 1500, "the icon did not dim while recording");
        proc.emit(line("transcribing"));
        // The cycle in progress runs to its end (1.4 s at most), then nothing moves.
        tryVerify(() => icon.opacity === 1, 3000, "the icon was left dimmed");
        wait(200);
        compare(icon.opacity, 1);
        icon.destroy();
    }
}
