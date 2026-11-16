import QtQuick
import QtTest
import qs.Common
import qs.Services

TestCase {
    id: tc
    name: "ReposMenu"
    width: 500
    height: 800
    visible: true
    when: windowShown

    readonly property string pluginUrl: Qt.resolvedUrl("../../../modules/home/dank/plugins/dotsRepos/ReposMenu.qml")

    readonly property var data: ({
        root: "/g",
        statusCommand: ["repos", "--json"],
        fetchCommand: ["repos", "fetch"],
        branchDeleteCommand: ["repos", "branch-delete"],
        worktreeRemoveCommand: ["repos", "worktree-remove"],
        terminalCommand: ["kitty", "--detach", "--directory"],
        openCommand: ["xdg-open"]
    })

    // dots: on main, 2 changed paths, ahead 1, a merged branch (deletable), an
    // unmerged one, and a clean linked worktree. forest: clean, in sync, no
    // extra branches. other/thing: mid-rebase, behind 3, no upstream for a branch.
    readonly property var status: ({
        root: "/g",
        generated: 1,
        repos: [
            { id: "me/dots", owner: "me", name: "dots", path: "/g/me/dots", branch: "main", detached: false,
              integration: "main", upstream: "origin/main", remote: "origin", ahead: 1, behind: 0, dirty: 2,
              operation: null, fetched: 1, unmerged: 1,
              branches: [
                  { name: "main", upstream: "origin/main", gone: false, ahead: 0, merged: true, head: true, integration: true },
                  { name: "chore/old", upstream: null, gone: false, ahead: 0, merged: true, head: false, integration: false },
                  { name: "feat/new", upstream: "origin/feat/new", gone: true, ahead: 4, merged: false, head: false, integration: false }
              ],
              worktrees: [
                  { path: "/g/me/dots", branch: "main", detached: false, main: true, dirty: null, exists: true },
                  { path: "/tmp/wt/dots-feat", branch: "feat/new", detached: false, main: false, dirty: 0, exists: true }
              ] },
            { id: "me/forest", owner: "me", name: "forest", path: "/g/me/forest", branch: "main", detached: false,
              integration: "main", upstream: "origin/main", remote: "origin", ahead: 0, behind: 0, dirty: 0,
              operation: null, fetched: null, unmerged: 0,
              branches: [ { name: "main", upstream: "origin/main", gone: false, ahead: 0, merged: true, head: true, integration: true } ],
              worktrees: [ { path: "/g/me/forest", branch: "main", detached: false, main: true, dirty: null, exists: true } ] },
            { id: "other/thing", owner: "other", name: "thing", path: "/g/other/thing", branch: "main", detached: false,
              integration: "main", upstream: "origin/main", remote: "origin", ahead: 0, behind: 3, dirty: 0,
              operation: "rebase", fetched: 1, unmerged: 0,
              branches: [ { name: "main", upstream: "origin/main", gone: false, ahead: 0, merged: true, head: true, integration: true } ],
              worktrees: [ { path: "/g/other/thing", branch: "main", detached: false, main: true, dirty: null, exists: true } ] }
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
    function visibleUp(it) {   // visible, and every ancestor visible
        for (; it; it = it.parent) if (it.visible === false) return false;
        return true;
    }
    function texts() {
        return all(popout, it => it.text !== undefined && it.text !== "" && visibleUp(it)).map(it => it.text);
    }
    function textItem(label) {
        const r = all(popout, it => it.text === label && visibleUp(it));
        verify(r.length >= 1, "no visible text '" + label + "'; have " + JSON.stringify(texts()));
        return r[0];
    }
    function icons(name) { return all(popout, it => it.name === name && visibleUp(it)); }
    function clickCentre(item, dx) {
        const p = item.mapToItem(tc, 0, 0);
        mouseClick(tc, p.x + item.width / 2 + (dx || 0), p.y + item.height / 2);
    }
    // The 44px row holding a repository's name.
    function rowOf(name) {
        let it = textItem(name);
        while (it && !(it.height === 44 && it.width > 200)) it = it.parent;
        verify(it, "no row for " + name);
        return it;
    }
    function open(name) { clickCentre(rowOf(name)); wait(30); }
    function actions() { return Proc.calls.filter(c => c.id.indexOf("dotsRepos.action.") === 0); }
    function statusCalls() { return Proc.calls.filter(c => c.id === "dotsRepos.status").length; }

    function init() {
        Proc.reset();
        Proc.statusOut = JSON.stringify(status);
        ToastService.reset();
        const comp = Qt.createComponent(pluginUrl);
        compare(comp.status, Component.Ready, comp.errorString());
        plugin = comp.createObject(tc, { pluginData: data });
        verify(plugin, "plugin did not instantiate");
        const holder = Qt.createQmlObject('import QtQuick; Item { width: 440; height: 700 }', tc);
        popout = plugin.popoutContent.createObject(holder);
        verify(popout, "popout did not instantiate: " + plugin.popoutContent.errorString());
        popout.width = 440;
        wait(50);
    }
    function cleanup() {
        if (popout) popout.parent.destroy();
        if (plugin) plugin.destroy();
        popout = plugin = null;
    }

    function test_rows_grouped_by_owner_with_a_summary_each() {
        compare(Proc.calls[0].id, "dotsRepos.status");
        compare(Proc.calls[0].timeout, 60000);
        for (const t of ["me", "other", "dots", "forest", "thing"]) textItem(t);
        textItem("2 changed · ↑1 ↓0 · 1 unmerged · 1 wt");
        textItem("clean");
        textItem("rebase · ↑0 ↓3");
        compare(texts().filter(t => t === "me").length, 1, "one owner heading for two repositories");
    }

    function test_colours_say_what_needs_attention() {
        verify(Qt.colorEqual(textItem("rebase · ↑0 ↓3").color, Theme.error), "an operation in progress is an error");
        verify(Qt.colorEqual(textItem("2 changed · ↑1 ↓0 · 1 unmerged · 1 wt").color, Theme.warning), "local work is a warning");
        verify(Qt.colorEqual(textItem("clean").color, Theme.surfaceVariantText), "clean is quiet");
        compare(plugin.attention, 1);
    }

    function test_details_closed_until_the_row_is_clicked_and_one_at_a_time() {
        verify(texts().indexOf("Fetch") < 0, "no actions until a row is open");
        open("dots");
        compare(plugin.expanded, "me/dots");
        verify(texts().indexOf("Fetch") >= 0 && texts().indexOf("Terminal") >= 0, JSON.stringify(texts()));
        textItem("chore/old"); textItem("feat/new"); textItem("Worktrees"); textItem("/tmp/wt/dots-feat");
        textItem("upstream origin/main · fetched " + plugin.ago(1) + " · merges into main");
        open("thing");
        compare(plugin.expanded, "other/thing");
        verify(texts().indexOf("chore/old") < 0, "dots' details should have closed");
        open("thing");
        compare(plugin.expanded, "");
    }

    function test_delete_only_on_merged_branches_that_are_not_checked_out() {
        open("dots");
        // chore/old is merged and not HEAD: one delete icon among the branches;
        // plus the clean worktree's remove icon.
        compare(icons("delete").length, 2, "chore/old and the clean worktree");
        open("forest");
        compare(icons("delete").length, 0, "main alone is never deletable");
    }

    function test_deleting_a_branch_runs_the_command_and_checks_again() {
        open("dots");
        const before = statusCalls();
        const del = icons("delete")[0];
        clickCentre(del); wait(30);
        const a = actions();
        compare(a.length, 1);
        compare(a[0].id, "dotsRepos.action.delete:me/dots:chore/old");
        compare(JSON.stringify(a[0].command), JSON.stringify(["repos", "branch-delete", "me/dots", "chore/old"]));
        compare(a[0].timeout, -1);
        compare(statusCalls(), before + 1);
        compare(ToastService.errors.length, 0);
    }

    function test_removing_a_worktree_runs_the_command() {
        open("dots");
        clickCentre(icons("delete")[1]); wait(30);
        const a = actions();
        compare(a.length, 1);
        compare(a[0].id, "dotsRepos.action.remove:me/dots:/tmp/wt/dots-feat");
        compare(JSON.stringify(a[0].command), JSON.stringify(["repos", "worktree-remove", "me/dots", "/tmp/wt/dots-feat"]));
    }

    function test_failed_action_shows_the_commands_first_line() {
        open("dots");
        Proc.nextExit = 3;
        Proc.nextOut = "error: the branch 'chore/old' is not fully merged\nhint: ...\n";
        clickCentre(icons("delete")[0]); wait(30);
        compare(ToastService.errors.length, 1);
        compare(ToastService.errors[0], "me/dots: delete chore/old failed: error: the branch 'chore/old' is not fully merged");
        compare(plugin.busy, "");
    }

    function test_fetch_one_repository_then_fetch_all() {
        open("dots");
        clickCentre(textItem("Fetch")); wait(30);
        let a = actions();
        compare(a[0].id, "dotsRepos.action.fetch:me/dots");
        compare(JSON.stringify(a[0].command), JSON.stringify(["repos", "fetch", "me/dots"]));
        const before = statusCalls();
        clickCentre(icons("sync").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        a = actions();
        compare(a[1].id, "dotsRepos.action.fetch");
        compare(JSON.stringify(a[1].command), JSON.stringify(["repos", "fetch"]));
        compare(statusCalls(), before + 1);
    }

    function test_open_and_terminal_do_not_recheck() {
        open("dots");
        const before = statusCalls();
        clickCentre(textItem("Terminal")); wait(30);
        clickCentre(textItem("Open")); wait(30);
        const t = Proc.calls.filter(c => c.id === "dotsRepos.terminal");
        const o = Proc.calls.filter(c => c.id === "dotsRepos.open");
        compare(JSON.stringify(t[0].command), JSON.stringify(["kitty", "--detach", "--directory", "/g/me/dots"]));
        compare(JSON.stringify(o[0].command), JSON.stringify(["xdg-open", "/g/me/dots"]));
        compare(statusCalls(), before);
        // and the worktree's own terminal icon opens there
        clickCentre(icons("terminal").filter(i => i.size === Theme.iconSizeSmall && i.parent.width === 28)[0]); wait(30);
        const t2 = Proc.calls.filter(c => c.id === "dotsRepos.terminal");
        compare(JSON.stringify(t2[1].command), JSON.stringify(["kitty", "--detach", "--directory", "/tmp/wt/dots-feat"]));
    }

    function test_unreadable_status_is_a_toast_not_a_crash() {
        Proc.statusOut = "not json";
        plugin.refresh(); wait(30);
        compare(ToastService.errors.length, 1);
        verify(ToastService.errors[0].indexOf("unreadable") >= 0, ToastService.errors[0]);
        compare(plugin.repos.length, 3, "the last good status stays");
    }

    function test_reopening_collapses_details() {
        open("dots");
        plugin.expanded = "";   // what the popout's visibility handler does on every opening
        wait(30);
        verify(texts().indexOf("Fetch") < 0);
    }

    function test_no_repositories_message() {
        Proc.statusOut = JSON.stringify({ root: "/nowhere", generated: 1, repos: [] });
        plugin.refresh(); wait(30);
        textItem("No repositories under /nowhere");
    }
}
