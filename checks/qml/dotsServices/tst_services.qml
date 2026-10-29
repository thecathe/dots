import QtQuick
import QtTest
import qs.Common
import qs.Services

TestCase {
    id: tc
    name: "ServicesMenu"
    width: 400
    height: 700
    visible: true
    when: windowShown

    readonly property string pluginUrl: Qt.resolvedUrl("../../../modules/home/dank/plugins/dotsServices/ServicesMenu.qml")

    // tailscale: no actions. gp and mc: actions (gp has a terminal one, mc a background one).
    readonly property var data: ({
        statusCommand: "/bin/status",
        services: [
            { name: "tailscale", label: "Tailscale", icon: "vpn_lock", up: ["ts", "up"], down: ["ts", "down"], actions: [] },
            { name: "gp", label: "GlobalProtect", icon: "vpn_key", up: ["gp", "up"], down: ["gp", "down"],
              actions: [{ label: "Reattach", icon: "terminal", argv: ["kitty", "--detach", "gp", "attach"] }] },
            { name: "mc", label: "Minecraft", icon: "sports_esports", up: ["mc", "up"], down: ["mc", "down"],
              actions: [{ label: "Console", icon: "terminal", argv: ["mc", "console"] },
                        { label: "Backup", icon: "save", argv: ["mc", "backup"] }] }
        ]
    })

    property var plugin: null
    property var popout: null

    function all(item, pred, out) {
        out = out || [];
        if (pred(item)) out.push(item);
        for (let i = 0; i < item.children.length; i++) all(item.children[i], pred, out);
        return out;
    }
    function texts() {
        return all(popout, it => it.text !== undefined && it.visible && it.text !== "").map(it => it.text);
    }
    function textItem(label) {
        const r = all(popout, it => it.text === label && it.visible);
        verify(r.length >= 1, "no visible text '" + label + "'; have " + JSON.stringify(texts()));
        return r[0];
    }
    function moreButtons() {   // the visible "..." icons
        return all(popout, it => it.name === "more_horiz" && it.visible);
    }
    function clickCentre(item, dx) {
        const p = item.mapToItem(tc, 0, 0);
        mouseClick(tc, p.x + item.width / 2 + (dx || 0), p.y + item.height / 2);
    }
    // The row a label belongs to: the 44px-high Rectangle containing it.
    function rowOf(label) {
        let it = textItem(label);
        while (it && !(it.height === 44 && it.width > 200)) it = it.parent;
        verify(it, "no row for " + label);
        return it;
    }
    function clickRowBody(label) {   // left part of the row, away from the "..." button
        const row = rowOf(label), p = row.mapToItem(tc, 0, 0);
        mouseClick(tc, p.x + 60, p.y + row.height / 2);
    }
    function clickMoreFor(label) {
        const row = rowOf(label), p = row.mapToItem(tc, 0, 0);
        mouseClick(tc, p.x + row.width - 20, p.y + row.height / 2);   // inside the 32px button
    }
    function toggles() { return Proc.calls.filter(c => c.id.indexOf("dotsServices.toggle.") === 0); }
    function actionCalls() { return Proc.calls.filter(c => c.id.indexOf("dotsServices.action.") === 0); }

    function init() {
        Proc.reset();
        ToastService.reset();
        const comp = Qt.createComponent(pluginUrl);
        compare(comp.status, Component.Ready, comp.errorString());
        plugin = comp.createObject(tc, { pluginData: data });
        verify(plugin, "plugin did not instantiate");
        const holder = Qt.createQmlObject('import QtQuick; Item { width: 320; height: 600 }', tc);
        popout = plugin.popoutContent.createObject(holder);
        verify(popout, "popout did not instantiate: " + plugin.popoutContent.errorString());
        popout.width = 320; popout.height = 600;
        wait(50);
    }
    function cleanup() {
        if (popout) popout.parent.destroy();
        if (plugin) plugin.destroy();
        popout = plugin = null;
    }

    function test_rows_and_state_from_status_command() {
        compare(Proc.calls[0].id, "dotsServices.status");
        for (const label of ["Tailscale", "GlobalProtect", "Minecraft"]) textItem(label);
        compare(texts().filter(t => t === "up").length, 2);     // tailscale, mc
        compare(texts().filter(t => t === "down").length, 1);   // gp
    }

    function test_button_only_on_services_with_actions() {
        compare(moreButtons().length, 2, "expected a '...' on gp and mc only");
        // and none of their action labels shown until opened
        verify(texts().indexOf("Reattach") < 0);
        verify(texts().indexOf("Console") < 0);
    }

    function test_more_opens_actions_and_does_not_toggle() {
        clickMoreFor("GlobalProtect");
        wait(30);
        verify(texts().indexOf("Reattach") >= 0, "Reattach should be listed: " + JSON.stringify(texts()));
        compare(toggles().length, 0, "clicking '...' must not switch the service");
        compare(plugin.expanded, "gp");
    }

    function test_more_again_closes() {
        clickMoreFor("GlobalProtect"); wait(30);
        clickMoreFor("GlobalProtect"); wait(30);
        verify(texts().indexOf("Reattach") < 0);
        compare(plugin.expanded, "");
        compare(toggles().length, 0);
    }

    function test_only_one_open_at_a_time() {
        clickMoreFor("GlobalProtect"); wait(30);
        clickMoreFor("Minecraft"); wait(30);
        verify(texts().indexOf("Reattach") < 0, "gp's actions should have closed");
        verify(texts().indexOf("Console") >= 0 && texts().indexOf("Backup") >= 0);
        compare(plugin.expanded, "mc");
    }

    function test_action_runs_its_argv_with_no_timeout_and_closes() {
        clickMoreFor("GlobalProtect"); wait(30);
        clickCentre(textItem("Reattach"));
        wait(30);
        const a = actionCalls();
        compare(a.length, 1);
        compare(a[0].id, "dotsServices.action.gp");
        compare(JSON.stringify(a[0].command), JSON.stringify(["kitty", "--detach", "gp", "attach"]));
        compare(a[0].timeout, -1);
        compare(plugin.expanded, "", "the list should close after running an action");
        compare(toggles().length, 0);
        compare(ToastService.errors.length, 0);
    }

    function test_failed_action_shows_a_toast() {
        Proc.nextExit = 3;
        clickMoreFor("Minecraft"); wait(30);
        clickCentre(textItem("Backup")); wait(30);
        compare(ToastService.errors.length, 1);
        verify(ToastService.errors[0].indexOf("Minecraft: Backup failed (exit 3)") === 0, ToastService.errors[0]);
    }

    // Regression: the row still toggles, with and without actions, using up when down and down when up.
    function test_row_body_still_toggles() {
        clickRowBody("GlobalProtect"); wait(30);      // gp is down -> up
        clickRowBody("Tailscale"); wait(30);          // tailscale is up -> down
        const t = toggles();
        compare(t.length, 2);
        compare(t[0].id, "dotsServices.toggle.gp");
        compare(JSON.stringify(t[0].command), JSON.stringify(["gp", "up"]));
        compare(t[1].id, "dotsServices.toggle.tailscale");
        compare(JSON.stringify(t[1].command), JSON.stringify(["ts", "down"]));
        // each toggle is followed by a fresh status check
        compare(Proc.calls.filter(c => c.id === "dotsServices.status").length, 3);
    }

    function test_reopening_the_popout_collapses_actions() {
        clickMoreFor("GlobalProtect"); wait(30);
        compare(plugin.expanded, "gp");
        plugin.expanded = "";   // what the popout's visibility handler does on every opening
        wait(30);
        verify(texts().indexOf("Reattach") < 0);
    }

    function test_no_services_message_unchanged() {
        cleanup();
        const comp = Qt.createComponent(pluginUrl);
        plugin = comp.createObject(tc, { pluginData: { services: [], statusCommand: "" } });
        const holder = Qt.createQmlObject('import QtQuick; Item { width: 320; height: 600 }', tc);
        popout = plugin.popoutContent.createObject(holder);
        popout.width = 320;
        wait(30);
        verify(texts().indexOf("No services on this machine") >= 0);
        compare(moreButtons().length, 0);
    }
}
