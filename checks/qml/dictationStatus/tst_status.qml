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
    function color(c) { return String(Qt.color(c)); }

    function find(item, pred, out) {
        out = out || [];
        if (pred(item)) out.push(item);
        for (let i = 0; i < item.children.length; i++) find(item.children[i], pred, out);
        return out;
    }
    function iconOf(content) {
        const r = find(content, it => it.name !== undefined);
        verify(r.length === 1, "expected one icon in the pill, found " + r.length);
        return r[0];
    }
    function fillOf(content) {
        const r = find(content, it => it.objectName === "progressFill");
        verify(r.length === 1, "expected one progress fill in the pill, found " + r.length);
        return r[0];
    }
    // Builds the pill the way DMS's BasePill holds it: the content sits in a loader
    // that is centred in the item with the background, whose size is the pill's.
    // Returns { content, bar }.
    function inPill(which, width, height) {
        const bar = Qt.createQmlObject('import QtQuick; Item {}', tc);
        bar.width = width;
        bar.height = height;
        const loader = Qt.createQmlObject('import QtQuick; Item {}', bar);
        const content = plugin[which].createObject(loader);
        loader.width = content.implicitWidth;
        loader.height = content.implicitHeight;
        loader.x = (bar.width - loader.width) / 2;
        loader.y = (bar.height - loader.height) / 2;
        return { content: content, bar: bar };
    }
    // A plugin with a 60 s limit and a clock the test moves.
    property real now: 0
    function withLimit(secs) {
        now = 1000000;
        plugin.pluginData = { statusCommand: argv, maxDurationSecs: secs };
        plugin.clock = () => tc.now;
    }
    function advance(ms) {
        now += ms;
        plugin.tick();
    }

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
            { alt: "recording", icon: "mic", colour: "#ff4d4f", recording: true },
            { alt: "streaming", icon: "mic", colour: "#ff4d4f", recording: true },
            { alt: "transcribing", icon: "graphic_eq", colour: Theme.primary, recording: false },
            { alt: "stopped", icon: "mic_off", colour: Theme.warning, recording: false },
        ];
        const content = plugin.horizontalBarPill.createObject(tc);
        const icon = iconOf(content);
        for (const c of cases) {
            proc.emit(line(c.alt));
            compare(plugin.phase, c.alt);
            compare(plugin.recording, c.recording, c.alt);
            // The pill follows the plugin, it is not a snapshot.
            compare(icon.name, c.icon, c.alt);
            compare(color(icon.color), color(c.colour), c.alt);
        }
        content.destroy();
    }

    function test_the_vertical_bar_shows_the_same_icon() {
        proc.emit(line("transcribing"));
        const content = plugin.verticalBarPill.createObject(tc);
        const icon = iconOf(content);
        compare(icon.name, "graphic_eq");
        compare(icon.size, plugin.barThickness - 4);
        content.destroy();
    }

    function test_progress_follows_the_clock() {
        withLimit(60);
        compare(plugin.progress, 0);
        proc.emit(line("recording"));
        compare(plugin.progress, 0);
        advance(15000);
        compare(plugin.progress, 0.25);
        advance(30000);
        compare(plugin.progress, 0.75);
        advance(90000);
        // Past the limit (the daemon is about to change state): full, not beyond.
        compare(plugin.progress, 1);
    }

    function test_no_limit_known_means_no_progress() {
        // The settings of a plugin set up before the limit was passed on.
        plugin.pluginData = { statusCommand: argv };
        now = 5;
        plugin.clock = () => tc.now;
        proc.emit(line("recording"));
        advance(30000);
        compare(plugin.maxDurationSecs, 0);
        compare(plugin.progress, 0);
        const content = plugin.horizontalBarPill.createObject(tc);
        compare(fillOf(content).visible, false);
        content.destroy();
    }

    function test_each_recording_starts_from_zero() {
        withLimit(60);
        proc.emit(line("recording"));
        advance(40000);
        compare(plugin.progress, 40 / 60);
        proc.emit(line("transcribing"));
        compare(plugin.progress, 0);
        advance(5000);
        compare(plugin.progress, 0);
        proc.emit(line("idle"));
        proc.emit(line("recording"));
        compare(plugin.progress, 0);
        advance(6000);
        compare(plugin.progress, 0.1);
    }

    function test_streaming_after_recording_does_not_restart_the_clock() {
        withLimit(60);
        proc.emit(line("recording"));
        advance(30000);
        proc.emit(line("streaming"));
        advance(0);
        compare(plugin.progress, 0.5);
    }

    function test_the_last_stretch_changes_the_fill_colour() {
        withLimit(60);
        proc.emit(line("recording"));
        advance(44000);
        compare(plugin.nearingLimit, false);
        compare(color(plugin.fillColor), color(plugin.recordingColor));
        advance(2000);
        // 14 s left: inside the last 15 s.
        compare(plugin.nearingLimit, true);
        compare(color(plugin.fillColor), color(Theme.warning));
        // A short limit warns for a quarter of it, not 15 s of 20.
        withLimit(20);
        proc.emit(line("idle"));
        proc.emit(line("recording"));
        advance(14000);
        compare(plugin.nearingLimit, false);
        advance(2000);
        compare(plugin.nearingLimit, true);
    }

    function test_the_fill_covers_the_pill_from_the_left() {
        withLimit(60);
        const p = inPill("horizontalBarPill", 80, 30);
        const fill = fillOf(p.content);
        compare(fill.visible, false);
        proc.emit(line("recording"));
        advance(30000);
        compare(fill.visible, true);
        // Half of the pill's width, the pill's whole height, from the pill's own edge
        // (not the icon's): measured in the pill's coordinates.
        const origin = fill.mapToItem(p.bar, 0, 0);
        compare(origin.x, 0);
        compare(origin.y, 0);
        compare(fill.width, 40);
        compare(fill.height, 30);
        advance(15000);
        compare(fill.width, 60);
        proc.emit(line("transcribing"));
        compare(fill.visible, false);
        p.bar.destroy();
    }

    function test_the_fill_covers_a_vertical_pill_from_the_top() {
        withLimit(60);
        plugin.isVertical = true;
        const p = inPill("verticalBarPill", 30, 50);
        const fill = fillOf(p.content);
        proc.emit(line("recording"));
        advance(30000);
        const origin = fill.mapToItem(p.bar, 0, 0);
        compare(origin.x, 0);
        compare(origin.y, 0);
        compare(fill.width, 30);
        compare(fill.height, 25);
        p.bar.destroy();
    }

    function test_without_a_pill_to_measure_there_is_no_fill() {
        withLimit(60);
        proc.emit(line("recording"));
        advance(30000);
        // Not held by anything like DMS's pill: nothing to size the fill from.
        const content = plugin.horizontalBarPill.createObject(null);
        compare(fillOf(content).visible, false);
        content.destroy();
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
        const content = plugin.horizontalBarPill.createObject(tc);
        const icon = iconOf(content);
        compare(icon.opacity, 1);
        proc.emit(line("recording"));
        tryVerify(() => icon.opacity < 0.9, 1500, "the icon did not dim while recording");
        proc.emit(line("transcribing"));
        // The cycle in progress runs to its end (1.4 s at most), then nothing moves.
        tryVerify(() => icon.opacity === 1, 3000, "the icon was left dimmed");
        wait(200);
        compare(icon.opacity, 1);
        content.destroy();
    }
}
