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
        openCommand: ["xdg-open"],
        codeCommand: ["code"],
        branchPublishCommand: ["repos", "branch-publish"],
        branchPushCommand: ["repos", "branch-push"],
        branchPullCommand: ["repos", "branch-pull"],
        branchSwitchCommand: ["repos", "branch-switch"]
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
                  { name: "main", upstream: "origin/main", gone: false, ahead: 0, aheadUpstream: 1, behindUpstream: 0, merged: true, head: true, integration: true },
                  { name: "chore/old", upstream: null, gone: false, ahead: 0, aheadUpstream: null, behindUpstream: null, merged: true, head: false, integration: false },
                  { name: "feat/new", upstream: "origin/feat/new", gone: true, ahead: 4, aheadUpstream: null, behindUpstream: null, merged: false, head: false, integration: false }
              ],
              worktrees: [
                  { path: "/g/me/dots", branch: "main", detached: false, main: true, dirty: null, exists: true },
                  { path: "/tmp/wt/dots-feat", branch: "feat/new", detached: false, main: false, dirty: 0, exists: true }
              ] },
            { id: "me/forest", owner: "me", name: "forest", path: "/g/me/forest", branch: "main", detached: false,
              integration: "main", upstream: "origin/main", remote: "origin", ahead: 0, behind: 0, dirty: 0,
              operation: null, fetched: null, unmerged: 0,
              branches: [ { name: "main", upstream: "origin/main", gone: false, ahead: 0, aheadUpstream: 0, behindUpstream: 0, merged: true, head: true, integration: true } ],
              worktrees: [ { path: "/g/me/forest", branch: "main", detached: false, main: true, dirty: null, exists: true } ] },
            { id: "other/thing", owner: "other", name: "thing", path: "/g/other/thing", branch: "main", detached: false,
              integration: "main", upstream: "origin/main", remote: "origin", ahead: 0, behind: 3, dirty: 0,
              operation: "rebase", fetched: 1, unmerged: 0,
              branches: [ { name: "main", upstream: "origin/main", gone: false, ahead: 0, aheadUpstream: 0, behindUpstream: 0, merged: true, head: true, integration: true } ],
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
        textItem("upstream origin/main · fetched " + plugin.ago(1) + " (fetch only downloads) · merges into main");
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

    function test_branch_actions_offered_only_where_they_would_succeed() {
        open("dots");
        // main: ahead of its upstream -> push. chore/old: no upstream -> publish. feat/new: upstream gone -> publish.
        // dots has 2 changed paths, so no switch and no pull anywhere.
        compare(icons("more_horiz").length, 3, JSON.stringify(texts()));
        clickCentre(icons("more_horiz")[0]); wait(30);
        textItem("Push");
        verify(texts().indexOf("Pull (fast-forward)") < 0 && texts().indexOf("Switch to") < 0 && texts().indexOf("Publish") < 0, JSON.stringify(texts()));
        clickCentre(icons("more_horiz")[1]); wait(30);
        textItem("Publish");
        verify(texts().indexOf("Push") < 0, "one branch open at a time: " + JSON.stringify(texts()));
        open("forest");
        compare(icons("more_horiz").length, 0, "in step and checked out: nothing to offer");
        open("thing");
        compare(icons("more_horiz").length, 0, "behind, but mid-rebase: nothing to offer");
    }

    function test_branch_action_runs_its_command_and_checks_again() {
        open("dots");
        clickCentre(icons("more_horiz")[1]); wait(30);
        const before = statusCalls();
        clickCentre(textItem("Publish")); wait(30);
        const a = actions();
        compare(a.length, 1);
        compare(a[0].id, "dotsRepos.action.publish:me/dots:chore/old");
        compare(JSON.stringify(a[0].command), JSON.stringify(["repos", "branch-publish", "me/dots", "chore/old"]));
        compare(statusCalls(), before + 1);
        compare(plugin.expandedBranch, "", "the list closes after an action");
    }

    function test_branch_row_shows_its_own_ahead_behind() {
        open("dots");
        textItem("merged · ↑1 ↓0");
    }

    // Long names: every row keeps its text clear of its icons and inside itself.
    readonly property var longStatus: ({
        root: "/g",
        generated: 1,
        repos: [
            { id: "thecathe/a-rather-long-repository-name", owner: "thecathe", name: "a-rather-long-repository-name",
              path: "/g/thecathe/a-rather-long-repository-name", branch: "feat/an-equally-long-branch-name-here", detached: false,
              integration: "main", upstream: "origin/main", remote: "origin", ahead: 2, behind: 1, dirty: 12,
              operation: "rebase", fetched: 1, unmerged: 9,
              branches: [
                  { name: "feat/a-very-long-branch-name-that-keeps-going-on", upstream: "origin/feat/a-very-long-branch-name-that-keeps-going-on", gone: false, ahead: 3, aheadUpstream: 1, behindUpstream: 0, merged: true, head: false, integration: false }
              ],
              worktrees: [
                  { path: "/g/thecathe/a-rather-long-repository-name", branch: "feat/x", detached: false, main: true, dirty: null, exists: true },
                  { path: "/g/thecathe/a-rather-long-repository-name/.claude/worktrees/report-rejected-feedback-and-more", branch: "worktree-report-rejected-feedback-and-more", detached: false, main: false, dirty: 0, exists: true }
              ] }
        ]
    })

    // Every visible text and icon under `row`, as a box in the row's own coordinates.
    function boxesIn(row) {
        return all(row, it => it !== row && visibleUp(it) && it.width > 0 && (it.name !== undefined || (it.text !== undefined && it.text !== "")))
            .map(it => { const p = it.mapToItem(row, 0, 0); return { item: it, label: it.name !== undefined ? "icon " + it.name : "'" + it.text + "'", x0: p.x, x1: p.x + it.width, y0: p.y, y1: p.y + it.height }; });
    }
    function assertClear(row, what) {
        const b = boxesIn(row);
        verify(b.length >= 2, what + ": found only " + b.length + " items");
        for (const a of b) {
            verify(a.x0 >= -0.5 && a.x1 <= row.width + 0.5, what + ": " + a.label + " runs outside the row (" + a.x0 + ".." + a.x1 + " of " + row.width + ")");
            verify(a.y0 >= -0.5 && a.y1 <= row.height + 0.5, what + ": " + a.label + " is taller than the row (it wrapped?) " + a.y0 + ".." + a.y1 + " of " + row.height);
            for (const c of b)
                if (a !== c && a.y0 < c.y1 && c.y0 < a.y1 && a.x0 < c.x1 - 0.5 && c.x0 < a.x1 - 0.5)
                    fail(what + ": " + a.label + " overlaps " + c.label);
        }
    }
    function rowAround(text, height) {
        let it = textItem(text);
        while (it && !(it.height === height && it.width > 200)) it = it.parent;
        verify(it, "no " + height + "px row around " + text);
        return it;
    }

    // Squeezing a text to nothing would also keep it clear of its neighbours: it must stay readable (truncated, not gone).
    function readable(text) {
        const t = textItem(text);
        verify(t.truncated, "'" + text + "' should be elided in this fixture");
        verify(t.width >= 60, "'" + text + "' was squeezed to " + t.width + "px");
    }
    function openLong() {
        Proc.statusOut = JSON.stringify(longStatus);
        plugin.refresh(); wait(30);
        open("a-rather-long-repository-name");
    }
    function test_long_repository_row_keeps_its_text_clear_of_its_summary() {
        openLong();
        assertClear(rowAround("a-rather-long-repository-name", 44), "repository row");
        readable("a-rather-long-repository-name");
    }
    function test_long_branch_row_keeps_its_text_clear_of_its_icons() {
        openLong();
        assertClear(rowAround("feat/a-very-long-branch-name-that-keeps-going-on", 30), "branch row");
        readable("feat/a-very-long-branch-name-that-keeps-going-on");
    }
    function test_long_worktree_row_keeps_its_text_clear_of_its_icons() {
        openLong();
        assertClear(rowAround(".claude/worktrees/report-rejected-feedback-and-more", 30), "worktree row");
        readable(".claude/worktrees/report-rejected-feedback-and-more");
    }

    function test_vscode_button_opens_the_directory_in_vscode() {
        open("dots");
        const before = statusCalls();
        clickCentre(textItem("VS Code")); wait(30);
        const c = Proc.calls.filter(x => x.id === "dotsRepos.code");
        compare(c.length, 1);
        compare(JSON.stringify(c[0].command), JSON.stringify(["code", "/g/me/dots"]));
        compare(statusCalls(), before, "opening an editor changes nothing, so no recheck");
        compare(ToastService.errors.length, 0);
    }

    function test_vscode_failure_is_a_toast() {
        open("dots");
        Proc.nextExit = 1;
        clickCentre(textItem("VS Code")); wait(30);
        compare(ToastService.errors.length, 1);
        compare(ToastService.errors[0], "VS Code failed (exit 1)");
    }

    function test_no_vscode_button_without_a_command() {
        plugin.pluginData = Object.assign({}, data, { codeCommand: [] });
        open("dots");
        textItem("Terminal");
        verify(texts().indexOf("VS Code") < 0, JSON.stringify(texts()));
    }
}
