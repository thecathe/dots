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
        pullCommand: ["repos", "pull"],
        pushCommand: ["repos", "push"],
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

    // The header's download button: `repos pull`, then a status; a repository it
    // could not fast-forward says so on its row and, open, why; a status that shows
    // it no longer behind clears that.
    function test_pull_all_marks_the_repositories_it_could_not_pull() {
        Proc.nextExit = 3;
        Proc.nextOut = "me/dots: up to date\nme/forest: pulled 2\nother/thing: not pulled: local changes are in the way\n";
        const before = statusCalls();
        clickCentre(icons("download").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        const a = actions();
        compare(a.length, 1);
        compare(a[0].id, "dotsRepos.action.pull");
        compare(JSON.stringify(a[0].command), JSON.stringify(["repos", "pull"]));
        compare(statusCalls(), before + 1);
        compare(plugin.busy, "");
        compare(ToastService.errors.length, 0);
        compare(JSON.stringify(ToastService.warnings), JSON.stringify(["Pulled 1 repository; not pulled: other/thing"]));
        compare(ToastService.details[0], "other/thing: local changes are in the way");
        textItem("not pulled · rebase · ↑0 ↓3");
        open("thing");
        textItem("Not pulled: local changes are in the way");
        const s = JSON.parse(Proc.statusOut);
        s.repos[2].behind = 0;
        Proc.statusOut = JSON.stringify(s);
        plugin.refresh(); wait(30);
        compare(plugin.pullRefused["other/thing"], undefined);
        compare(plugin.summary(plugin.repos[2]), "rebase");
    }
    function test_pull_all_with_nothing_refused() {
        Proc.nextOut = "me/dots: up to date\nme/forest: pulled 1\nother/thing: pulled 3\n";
        clickCentre(icons("download").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        compare(JSON.stringify(ToastService.infos), JSON.stringify(["Pulled 2 repositories"]));
        compare(ToastService.warnings.length, 0);
        compare(JSON.stringify(plugin.pullRefused), "{}");
    }
    function test_pull_all_that_fails_outright_is_an_error() {
        Proc.nextExit = 64;
        Proc.nextOut = "usage: repos ...\n";
        clickCentre(icons("download").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        compare(JSON.stringify(ToastService.errors), JSON.stringify(["Pull failed: usage: repos ..."]));
    }

    // The header's upload button: `repos push`, then a status; a repository with a
    // branch it could not push says so on its row and, open, why; a status that
    // shows none of its branches ahead clears that.
    function test_push_all_marks_the_repositories_it_could_not_push() {
        Proc.nextExit = 3;
        Proc.nextOut = "me/dots: main: not pushed: diverged from origin/main, and merging it conflicts in 1 file(s)\n"
            + "me/dots: feat/x: merged origin/feat/x, pushed 2\nme/forest: nothing to push\nother/thing: main: pushed 1\n";
        const before = statusCalls();
        clickCentre(icons("upload").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        const a = actions();
        compare(a.length, 1);
        compare(a[0].id, "dotsRepos.action.push");
        compare(JSON.stringify(a[0].command), JSON.stringify(["repos", "push"]));
        compare(statusCalls(), before + 1);
        compare(plugin.busy, "");
        compare(ToastService.errors.length, 0);
        compare(JSON.stringify(ToastService.warnings), JSON.stringify(["Pushed 2 branches; not pushed: me/dots"]));
        compare(ToastService.details[0], "me/dots: main: diverged from origin/main, and merging it conflicts in 1 file(s)");
        verify(plugin.summary(plugin.repos[0]).startsWith("not pushed · "), plugin.summary(plugin.repos[0]));
        open("dots");
        textItem("Not pushed: main: diverged from origin/main, and merging it conflicts in 1 file(s)");
        const s = JSON.parse(Proc.statusOut);
        s.repos[0].branches[0].aheadUpstream = 0;
        Proc.statusOut = JSON.stringify(s);
        plugin.refresh(); wait(30);
        compare(plugin.pushRefused["me/dots"], undefined);
    }
    function test_push_all_with_nothing_refused() {
        Proc.nextOut = "me/dots: nothing to push\nme/forest: nothing to push\nother/thing: no remote\n";
        clickCentre(icons("upload").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        compare(JSON.stringify(ToastService.infos), JSON.stringify(["Nothing to push"]));
        compare(ToastService.warnings.length, 0);
        compare(JSON.stringify(plugin.pushRefused), "{}");
    }
    function test_push_all_with_a_failed_fetch_names_the_repository() {
        Proc.nextExit = 3;
        Proc.nextOut = "me/forest: not pushed: fetch failed: could not read from remote\n";
        clickCentre(icons("upload").filter(i => i.parent && i.parent.width === 32)[0]); wait(30);
        compare(JSON.stringify(ToastService.warnings), JSON.stringify(["Nothing to push; not pushed: me/forest"]));
        compare(ToastService.details[0], "me/forest: fetch failed: could not read from remote");
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

    // Columns: the same column is in the same place on every row, whatever the text in a row.
    // (A RowLayout of size-capped items centres the leftover room: the name and branch then sat
    // wherever the status text left space, a different x on each row, and none left-aligned.)
    function textBoxes(row) {   // the row's texts, left to right
        return boxesIn(row).filter(b => b.label[0] === "'").sort((a, c) => a.x0 - c.x0);
    }
    // Like rowAround, for a text that appears more than once ("main" is a repository's branch
    // and a branch row's name): the first of its occurrences that sits in such a row.
    function innerRowAround(text, height) {
        for (const t of all(popout, it => it.text === text && visibleUp(it))) {
            let it = t;
            while (it && !(it.height === height && it.width > 200)) it = it.parent;
            if (it) return it;
        }
        fail("no " + height + "px row around " + text);
    }
    function sameColumns(rows, what, edges) {
        for (let i = 1; i < rows.length; i++)
            for (let k = 0; k < edges.length; k++) {
                const a = rows[0][k], b = rows[i][k];
                compare(b.x0, a.x0, what + ": column " + k + " starts elsewhere in row " + i + " (" + b.label + " vs " + a.label + ")");
                compare(b.x1, a.x1, what + ": column " + k + " ends elsewhere in row " + i + " (" + b.label + " vs " + a.label + ")");
            }
    }
    function test_name_branch_and_status_keep_their_own_column_down_the_list() {
        // Short and long names, branches and statuses, and one clean row, in one list.
        Proc.statusOut = JSON.stringify({ root: "/g", generated: 1, repos: status.repos.concat(longStatus.repos) });
        plugin.refresh(); wait(30);
        const rows = ["dots", "forest", "thing", "a-rather-long-repository-name"].map(n => textBoxes(rowOf(n)));
        for (const r of rows) compare(r.length, 3, "name, branch and status in each row: " + JSON.stringify(r.map(b => b.label)));
        sameColumns(rows, "repository rows", [0, 1, 2]);
        const r = rows[0];
        verify(r[0].x1 <= r[1].x0 && r[1].x1 <= r[2].x0, "the columns must not overlap: " + JSON.stringify(r.map(b => [b.x0, b.x1])));
        // Left-aligned names and branches, a right-aligned status, in their columns.
        const name = textItem("dots"), status3 = textItem("clean");
        compare(name.horizontalAlignment, Text.AlignLeft);
        compare(status3.horizontalAlignment, Text.AlignRight);
    }
    function test_a_long_status_does_not_move_the_name_or_the_branch() {
        // The old layout gave the name whatever width the status left it.
        Proc.statusOut = JSON.stringify({ root: "/g", generated: 1, repos: status.repos.concat(longStatus.repos) });
        plugin.refresh(); wait(30);
        const clean = textBoxes(rowOf("forest")), long = textBoxes(rowOf("a-rather-long-repository-name"));
        compare(long[0].x1 - long[0].x0, clean[0].x1 - clean[0].x0, "the name column is as wide next to a long status");
        compare(long[1].x0, clean[1].x0, "the branch column starts in the same place next to a long status");
    }
    function test_branch_rows_keep_their_name_and_note_in_columns() {
        open("dots");
        // main has none of the icons, chore/old can be deleted: the icon slots are reserved either way.
        const rows = ["main", "chore/old", "feat/new"].map(n => textBoxes(innerRowAround(n, 30)));
        for (const r of rows) compare(r.length, 2, "name and note: " + JSON.stringify(r.map(b => b.label)));
        sameColumns(rows, "branch rows", [0, 1]);
        compare(rows[0][0].x0, Theme.iconSizeSmall + Theme.spacingS, "the name starts right after the icon");
    }
    function test_the_info_line_wraps_inside_the_popout() {
        // "upstream origin/main · fetched 2h ago (fetch only downloads) · merges into main" is
        // about 80 characters, wider than the popout: it used to run off the right edge.
        open("dots");
        const info = textItem("upstream origin/main · fetched " + plugin.ago(1) + " (fetch only downloads) · merges into main");
        const right = info.mapToItem(popout, info.width, 0).x;
        verify(right <= popout.width + 0.5, "the info line ends at " + right + ", past the popout's " + popout.width);
        verify(info.lineCount > 1, "a line this long should wrap; it has " + info.lineCount);
    }

    function test_worktree_rows_line_up_with_the_branch_rows() {
        open("dots");
        const wt = textBoxes(innerRowAround("/tmp/wt/dots-feat", 30)), br = textBoxes(innerRowAround("main", 30));
        compare(wt.length, 2);
        compare(wt[0].x0, br[0].x0, "worktree path and branch name start in the same column");
        compare(wt[1].x1, br[1].x1, "worktree note and branch note end in the same column");
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

    // The overview: how many repositories fall in each bucket. From `status`: dots has an
    // unpushed commit, local changes, an unmerged branch and a merged one to delete; forest is
    // in step with its upstream; thing is mid-rebase and behind.
    function test_overview_counts_repositories_per_bucket() {
        const o = plugin.overviewOf(status.repos);
        compare(o.total, 3);
        compare(o.upToDate, 1);
        compare(o.behind, 1);
        compare(o.ahead, 1);
        compare(o.merged, 1);
        compare(o.dirty, 1);
        compare(o.unmerged, 1);
        compare(o.noUpstream, 0);
        compare(o.stuck, 1);
    }

    function test_overview_up_to_date_means_in_step_with_an_upstream() {
        const r = JSON.parse(JSON.stringify(status.repos[1]));   // forest: in step
        compare(plugin.overviewOf([r]).upToDate, 1);
        r.upstream = null;
        const o = plugin.overviewOf([r]);
        compare(o.upToDate, 0, "a repository with no upstream is not in step with anything");
        compare(o.noUpstream, 1);
        compare(plugin.overviewOf([]).total, 0);
    }

    function test_overview_chips_hide_empty_buckets_but_always_say_up_to_date() {
        compare(plugin.overviewChips.map(c => c.label).join(" | "),
                "1 up to date | 1 to pull | 1 to push | 1 with merged branches | 1 with changes | 1 with unmerged branches | 1 mid-operation or detached");
        Proc.statusOut = JSON.stringify({ root: "/g", generated: 1, repos: [status.repos[1]] });
        plugin.refresh(); wait(30);
        compare(plugin.overviewChips.map(c => c.label).join(" | "), "1 up to date");
        Proc.statusOut = JSON.stringify({ root: "/g", generated: 1, repos: [] });
        plugin.refresh(); wait(30);
        compare(plugin.overviewChips.map(c => c.label).join(" | "), "0 up to date");
    }

    function test_overview_chip_colours_follow_the_row_colours() {
        const by = {};
        for (const c of plugin.overviewChips) by[c.key] = c.color;
        verify(Qt.colorEqual(by.behind, Theme.error) && Qt.colorEqual(by.stuck, Theme.error), "behind and mid-operation are the red of a row");
        verify(Qt.colorEqual(by.ahead, Theme.warning) && Qt.colorEqual(by.dirty, Theme.warning) && Qt.colorEqual(by.unmerged, Theme.warning), "unfinished work is the orange of a row");
        verify(Qt.colorEqual(by.upToDate, Theme.success));
    }

    function test_popout_says_the_overview_in_words() {
        textItem("3 repositories");
        textItem("1 up to date"); textItem("1 to pull"); textItem("1 to push"); textItem("1 with merged branches");
        textItem("1 with changes"); textItem("1 with unmerged branches"); textItem("1 mid-operation or detached");
    }

    // The pill: the icon alone, until the pointer has rested on it for hoverDelay.
    function pillOf() {
        const holder = Qt.createQmlObject('import QtQuick; Item { width: 600; height: 40 }', tc);
        const pill = plugin.horizontalBarPill.createObject(holder);
        verify(pill, "pill did not instantiate: " + plugin.horizontalBarPill.errorString());
        return pill;
    }
    function pillTexts(pill) { return all(pill, it => it.text !== undefined && it.text !== "" && visibleUp(it)).map(it => it.text); }

    function test_hover_expands_the_pill_after_a_short_rest_and_collapses_on_leaving() {
        plugin.hoverDelay = 30;
        const pill = pillOf();
        wait(10);
        const closed = pill.implicitWidth;
        compare(pillTexts(pill).length, 0, "nothing but the icon at rest");
        plugin.pointerChanged(true);
        wait(10);
        compare(plugin.overviewShown, false, "a pointer sweeping past does not open it");
        wait(150);
        compare(plugin.overviewShown, true);
        verify(pill.implicitWidth > closed + 60, "grew from " + closed + " to " + pill.implicitWidth);
        compare(pillTexts(pill).join(" "), "1 1 1 1 1 1 1", "counts only, in the pill");
        plugin.pointerChanged(false);
        wait(150);
        compare(plugin.overviewShown, false);
        compare(pill.implicitWidth, closed);
        pill.parent.destroy();
    }

    // dots.repos.hoverDelayMs reaches the plugin as the hoverDelayMs setting.
    function test_hover_delay_comes_from_the_settings() {
        compare(plugin.hoverDelay, 250, "the default when the setting is absent");
        plugin.pluginData = Object.assign({}, data, { hoverDelayMs: 600 });
        compare(plugin.hoverDelay, 600);
        plugin.pluginData = Object.assign({}, data, { hoverDelayMs: 0 });
        compare(plugin.hoverDelay, 0, "zero means at once, it is not 'unset'");
    }

    function test_the_configured_delay_is_the_one_the_pill_waits() {
        // Longer than the 250 ms default, so only the configured value passes both waits.
        plugin.pluginData = Object.assign({}, data, { hoverDelayMs: 400 });
        plugin.pointerChanged(true);
        wait(320);
        compare(plugin.overviewShown, false, "still inside the configured delay");
        wait(250);
        compare(plugin.overviewShown, true);
        plugin.pointerChanged(false);
    }

    function test_a_pointer_that_leaves_before_the_delay_never_opens_it() {
        plugin.hoverDelay = 60;
        plugin.pointerChanged(true);
        wait(20);
        plugin.pointerChanged(false);
        wait(120);
        compare(plugin.overviewShown, false);
    }

    function test_hover_checks_again_only_when_the_last_check_is_old() {
        plugin.hoverDelay = 10;
        const before = statusCalls();
        plugin.pointerChanged(true); wait(60);
        compare(statusCalls(), before, "fresh: nothing to check");
        plugin.pointerChanged(false);
        plugin.checkedAt = Date.now() - 10 * 60 * 1000;
        plugin.pointerChanged(true); wait(60);
        compare(statusCalls(), before + 1, "stale: checked once");
        compare(ToastService.errors.length, 0);
    }

    function test_hover_check_that_fails_is_silent() {
        plugin.hoverDelay = 10;
        plugin.checkedAt = 0;
        Proc.statusOut = "not json";
        plugin.pointerChanged(true); wait(60);
        compare(ToastService.errors.length, 0, "a failed check on hover is not worth a toast");
        compare(plugin.repos.length, 3, "the last good status stays");
        Proc.statusOut = JSON.stringify(status);
        plugin.refresh(); wait(30);
        compare(ToastService.errors.length, 0);
    }
}
