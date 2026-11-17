import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

// Bar pill + popout listing every git repository under dots.repos.root.
// Nothing runs while the popout is closed and the pointer is elsewhere: opening
// it, or resting the pointer on the pill (which then shows an overview, see
// below), runs the status command once (`repos --json`, modules/home/repos/repos.sh), whose JSON gives each
// repository's branch, how far it is ahead of and behind its upstream, its
// changed paths, an operation in progress, its local branches (merged into the
// integration branch or not) and its worktrees. A row opens to those and to
// the actions. Every command is an argv from the plugin settings
// (modules/home/dank/repos-menu.nix) that this file appends arguments to.
PluginComponent {
    id: root

    readonly property var statusCommand: pluginData.statusCommand || []
    readonly property var fetchCommand: pluginData.fetchCommand || []
    readonly property var branchDeleteCommand: pluginData.branchDeleteCommand || []
    readonly property var worktreeRemoveCommand: pluginData.worktreeRemoveCommand || []
    readonly property var terminalCommand: pluginData.terminalCommand || []
    readonly property var openCommand: pluginData.openCommand || []
    readonly property var codeCommand: pluginData.codeCommand || []
    readonly property var branchPublishCommand: pluginData.branchPublishCommand || []
    readonly property var branchPushCommand: pluginData.branchPushCommand || []
    readonly property var branchPullCommand: pluginData.branchPullCommand || []
    readonly property var branchSwitchCommand: pluginData.branchSwitchCommand || []

    // The last status: [{ id, owner, name, path, branch, detached, integration,
    // upstream, ahead, behind, dirty, operation, fetched, branches, unmerged, worktrees }].
    property var repos: []
    property string rootDir: pluginData.root || ""
    property bool checking: false
    property bool loaded: false
    // When the last status arrived (Date.now(), ms); 0 before the first.
    property double checkedAt: 0
    // The pill shows its overview while the pointer has rested on it for hoverDelay
    // ms. Resting there also checks again if the last status is older than freshMs,
    // so the counts are not the ones from whenever the menu was last opened.
    // hoverDelay comes from dots.repos.hoverDelayMs; 0 is a valid choice (at once),
    // so the fallback tests for undefined rather than for falsy.
    property bool overviewShown: false
    property int hoverDelay: pluginData.hoverDelayMs !== undefined ? pluginData.hoverDelayMs : 250
    property int freshMs: 30000
    // How a repository row's width is split into columns: the name, the branch, and the
    // status takes the rest. The same on every row, which is what makes them columns.
    readonly property real colNameShare: 0.37
    readonly property real colBranchShare: 0.22
    // The same for the branch and worktree rows under an open repository: the name takes
    // this share, its note the rest, and two 28px icon slots stay free on the right.
    readonly property real detailNameShare: 0.60
    readonly property real iconSlotsWidth: 56
    // The action under way ("fetch", "fetch:<id>", "delete:<id>:<branch>",
    // "remove:<id>:<path>"), "" when none. One at a time.
    property string busy: ""
    // The repository whose details are open, "" when none. One at a time.
    property string expanded: ""
    // The branch whose actions are open ("<id>:<branch>"), "" when none.
    property string expandedBranch: ""

    readonly property int attention: repos.filter(r => root.needsAttention(r)).length

    // quiet: a check nobody asked for (the pointer on the pill) does not toast a failure.
    function refresh(quiet) {
        if (statusCommand.length === 0)
            return;
        checking = true;
        // Up to a minute: a status walks every repository, a big one included.
        Proc.runCommand("dotsRepos.status", statusCommand, (stdout, exitCode) => {
            checking = false;
            if (exitCode !== 0) {
                if (!quiet)
                    ToastService.showError("Repositories: status failed (exit " + exitCode + ")");
                return;
            }
            try {
                const data = JSON.parse(stdout);
                repos = data.repos || [];
                if (data.root)
                    rootDir = data.root;
                loaded = true;
                checkedAt = Date.now();
            } catch (e) {
                if (!quiet)
                    ToastService.showError("Repositories: unreadable status");
            }
        }, 0, 60000);
    }

    // An action that changes a repository: one at a time, a toast with the
    // command's first line if it fails, and a fresh status after it either way.
    function run(key, argv, label) {
        if (busy !== "")
            return;
        busy = key;
        Proc.runCommand("dotsRepos.action." + key, argv, (stdout, exitCode) => {
            if (exitCode !== 0) {
                const line = (stdout || "").split("\n").find(l => l.trim() !== "") || "";
                ToastService.showError(label + " failed" + (line !== "" ? ": " + line : " (exit " + exitCode + ")"));
            }
            busy = "";
            refresh();
        }, 0, -1);
    }

    function fetchAll() {
        run("fetch", fetchCommand, "Fetch");
    }
    function fetchRepo(repo) {
        run("fetch:" + repo.id, fetchCommand.concat([repo.id]), repo.id + ": fetch");
    }
    function deleteBranch(repo, branch) {
        run("delete:" + repo.id + ":" + branch.name, branchDeleteCommand.concat([repo.id, branch.name]), repo.id + ": delete " + branch.name);
    }
    function removeWorktree(repo, worktree) {
        run("remove:" + repo.id + ":" + worktree.path, worktreeRemoveCommand.concat([repo.id, worktree.path]), repo.id + ": remove worktree");
    }

    // The actions a branch's "..." offers: only those that would succeed, so
    // that git's refusals (unmerged, dirty, diverged) are never the answer.
    // Publish: no upstream, or one that is gone. Push: ahead of its upstream and
    // not behind it (never forced). Pull: the checked-out branch, behind its
    // upstream, with a clean tree (fast-forward only). Switch: another branch,
    // with a clean tree. Nothing while an operation is in progress.
    function branchActions(repo, b) {
        const out = [];
        const clean = (repo.dirty || 0) === 0 && !repo.operation;
        const hasUpstream = b.upstream !== null && b.upstream !== undefined && !b.gone;
        if (!hasUpstream && repo.remote)
            out.push({ key: "publish", label: "Publish", icon: "cloud_upload" });
        if (hasUpstream && (b.aheadUpstream || 0) > 0 && (b.behindUpstream || 0) === 0)
            out.push({ key: "push", label: "Push", icon: "upload" });
        if (b.head && hasUpstream && (b.behindUpstream || 0) > 0 && clean)
            out.push({ key: "pull", label: "Pull (fast-forward)", icon: "download" });
        if (!b.head && clean)
            out.push({ key: "switch", label: "Switch to", icon: "swap_horiz" });
        return out;
    }
    function branchAction(repo, b, key) {
        expandedBranch = "";
        const commands = { publish: branchPublishCommand, push: branchPushCommand, pull: branchPullCommand, switch: branchSwitchCommand };
        run(key + ":" + repo.id + ":" + b.name, commands[key].concat([repo.id, b.name]), repo.id + ": " + key + " " + b.name);
    }

    // Fire and forget: a terminal (kitty --detach) and a file manager both
    // return at once; nothing to check afterwards.
    function openTerminal(path) {
        Proc.runCommand("dotsRepos.terminal", terminalCommand.concat([path]), (stdout, exitCode) => {
            if (exitCode !== 0)
                ToastService.showError("Terminal failed (exit " + exitCode + ")");
        }, 0, -1);
    }
    function openDir(path) {
        Proc.runCommand("dotsRepos.open", openCommand.concat([path]), (stdout, exitCode) => {
            if (exitCode !== 0)
                ToastService.showError("Open failed (exit " + exitCode + ")");
        }, 0, -1);
    }
    // VS Code: `code DIR` hands the directory to the running editor, or starts one.
    // The command is wrapped by the module so that a newly started editor is not
    // left in the shell's own cgroup (see repos-menu.nix).
    function openCode(path) {
        Proc.runCommand("dotsRepos.code", codeCommand.concat([path]), (stdout, exitCode) => {
            if (exitCode !== 0)
                ToastService.showError("VS Code failed (exit " + exitCode + ")");
        }, 0, -1);
    }

    // The buttons under an open repository, in order. VS Code only when the module
    // gave the menu a command for it.
    readonly property var repoActions: {
        const out = [
            { key: "fetch", label: "Fetch", icon: "sync" },
            { key: "open", label: "Open", icon: "folder_open" },
            { key: "terminal", label: "Terminal", icon: "terminal" }
        ];
        if (codeCommand.length > 0)
            out.push({ key: "code", label: "VS Code", icon: "code" });
        return out;
    }

    // What the row says on the right, and in which colour.
    function needsAttention(r) {
        return r.operation !== null || (r.behind || 0) > 0 || r.detached === true;
    }
    function summary(r) {
        const parts = [];
        if (r.operation)
            parts.push(r.operation);
        if (r.detached)
            parts.push("detached");
        if ((r.dirty || 0) > 0)
            parts.push(r.dirty + " changed");
        if (r.upstream === null)
            parts.push("no upstream");
        else if ((r.ahead || 0) > 0 || (r.behind || 0) > 0)
            parts.push("↑" + (r.ahead || 0) + " ↓" + (r.behind || 0));
        if ((r.unmerged || 0) > 0)
            parts.push(r.unmerged + " unmerged");
        const linked = (r.worktrees || []).filter(w => !w.main).length;
        if (linked > 0)
            parts.push(linked + " wt");
        return parts.length > 0 ? parts.join(" · ") : "clean";
    }
    function tint(r) {
        if (needsAttention(r))
            return Theme.error;
        if ((r.dirty || 0) > 0 || (r.ahead || 0) > 0 || (r.unmerged || 0) > 0 || r.upstream === null)
            return Theme.warning;
        return Theme.surfaceVariantText;
    }
    // The overview: how many repositories fall in each bucket. One repository can be
    // in several (ahead and with changes); "up to date" is in step with an upstream.
    // Pull and push are counted as the rows show them: the checked-out branch against
    // its upstream, as of the last fetch of each repository. "merged" counts the
    // repositories that have a merged branch the menu would offer to delete.
    function overviewOf(list) {
        const o = { total: list.length, upToDate: 0, behind: 0, ahead: 0, merged: 0, dirty: 0, unmerged: 0, noUpstream: 0, stuck: 0 };
        for (const r of list) {
            if (r.upstream === null || r.upstream === undefined)
                o.noUpstream++;
            else if ((r.ahead || 0) === 0 && (r.behind || 0) === 0)
                o.upToDate++;
            if ((r.behind || 0) > 0)
                o.behind++;
            if ((r.ahead || 0) > 0)
                o.ahead++;
            if ((r.branches || []).some(b => b.merged && !b.head && !b.integration))
                o.merged++;
            if ((r.dirty || 0) > 0)
                o.dirty++;
            if ((r.unmerged || 0) > 0)
                o.unmerged++;
            if (r.operation || r.detached)
                o.stuck++;
        }
        return o;
    }
    readonly property var overview: overviewOf(repos)
    // The buckets, in the order they are shown; the colours are the rows' (red: needs
    // attention, orange: unfinished work, grey: nothing to do), green for in step.
    readonly property var overviewKinds: [
        { key: "upToDate", icon: "check_circle", phrase: "up to date", color: Theme.success, always: true },
        { key: "behind", icon: "download", phrase: "to pull", color: Theme.error },
        { key: "ahead", icon: "upload", phrase: "to push", color: Theme.warning },
        { key: "merged", icon: "call_merge", phrase: "with merged branches", color: Theme.surfaceVariantText },
        { key: "dirty", icon: "edit", phrase: "with changes", color: Theme.warning },
        { key: "unmerged", icon: "fork_right", phrase: "with unmerged branches", color: Theme.warning },
        { key: "noUpstream", icon: "cloud_off", phrase: "without an upstream", color: Theme.warning },
        { key: "stuck", icon: "error", phrase: "mid-operation or detached", color: Theme.error }
    ]
    // Only the buckets that are not empty, but always "up to date".
    readonly property var overviewChips: overviewKinds.filter(k => k.always === true || overview[k.key] > 0).map(k => ({
                key: k.key,
                icon: k.icon,
                color: k.color,
                count: overview[k.key],
                label: overview[k.key] + " " + k.phrase
            }))

    // The pointer on the pill: after hoverDelay (so one sweeping past does nothing) the
    // pill grows to show the overview, and a status older than freshMs is checked again,
    // quietly, since nobody asked for it. Leaving closes it at once.
    function pointerChanged(inside) {
        if (inside) {
            hoverTimer.restart();
        } else {
            hoverTimer.stop();
            overviewShown = false;
        }
    }
    function hoverRefresh() {
        if (checking || busy !== "")
            return;
        if (loaded && Date.now() - checkedAt < freshMs)
            return;
        refresh(true);
    }

    Timer {
        id: hoverTimer

        interval: root.hoverDelay
        onTriggered: {
            root.overviewShown = true;
            root.hoverRefresh();
        }
    }

    HoverHandler {
        onHoveredChanged: root.pointerChanged(hovered)
    }

    // One bucket: its icon and count, or with the words spelled out. The row it sits in
    // says which (`labelled`): the bar pill has no room for words, the menu has.
    Component {
        id: chipDelegate

        Row {
            required property var modelData
            readonly property bool labelled: parent && parent.labelled === true

            spacing: 2

            DankIcon {
                name: parent.modelData.icon
                size: parent.labelled ? Theme.iconSizeSmall : Theme.barIconSize(root.barThickness, -8)
                color: parent.modelData.color
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: parent.labelled ? parent.modelData.label : String(parent.modelData.count)
                color: parent.modelData.color
                font.pixelSize: parent.labelled ? Theme.fontSizeSmall : Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                wrapMode: Text.NoWrap
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // "2h ago" for an epoch, "never" for null.
    function ago(epoch) {
        if (epoch === null || epoch === undefined)
            return "never";
        const s = Math.max(0, Math.floor(Date.now() / 1000) - epoch);
        if (s < 60)
            return "just now";
        if (s < 3600)
            return Math.floor(s / 60) + "m ago";
        if (s < 86400)
            return Math.floor(s / 3600) + "h ago";
        return Math.floor(s / 86400) + "d ago";
    }
    // A worktree's path without what is already known: the repository's own
    // directory when the worktree sits inside it (".claude/worktrees/x"), else
    // the root in front of it.
    function shortPath(path, repoPath) {
        if (repoPath && path.indexOf(repoPath + "/") === 0)
            return path.substring(repoPath.length + 1);
        if (rootDir !== "" && path.indexOf(rootDir + "/") === 0)
            return path.substring(rootDir.length + 1);
        return path;
    }

    // The icon, and beside it the overview while the pointer rests on the pill: counts
    // only, each in the colour the rows use. The pill's width follows this Row's, so it
    // grows and shrinks with the overview (a vertical bar has no room, so none there).
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "account_tree"
                size: Theme.barIconSize(root.barThickness, -4)
                color: root.attention > 0 ? Theme.error : Theme.widgetIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: width > 0
                clip: true
                width: root.overviewShown ? overviewRow.implicitWidth : 0
                height: overviewRow.implicitHeight

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    id: overviewRow

                    property bool labelled: false

                    spacing: Theme.spacingS

                    StyledText {
                        // Before the first status there is nothing to count.
                        visible: !root.loaded
                        text: "…"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: root.overviewChips
                        delegate: chipDelegate
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "account_tree"
            size: Theme.barIconSize(root.barThickness, -4)
            color: root.attention > 0 ? Theme.error : Theme.widgetIconColor
        }
    }

    popoutWidth: 440
    // Fixed: the list scrolls inside it, since the repositories are many.
    popoutHeight: 640

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Repositories"
            showCloseButton: true

            // Injected by PluginPopout; used to check again on every opening,
            // since the content is kept between openings.
            property var parentPopout: null

            Component.onCompleted: root.refresh()

            Connections {
                target: popout.parentPopout
                function onShouldBeVisibleChanged() {
                    if (popout.parentPopout.shouldBeVisible) {
                        root.expanded = "";
                        root.expandedBranch = "";
                        root.refresh();
                    }
                }
            }

            // Fetch every repository, then check again.
            headerActions: Component {
                Rectangle {
                    id: fetchAllButton

                    width: 32
                    height: 32
                    radius: 16
                    color: fetchAllArea.containsMouse ? Theme.primaryHover : "transparent"
                    opacity: root.busy === "" ? 1 : 0.5

                    DankIcon {
                        anchors.centerIn: parent
                        name: "sync"
                        size: Theme.iconSize - 4
                        color: root.busy === "fetch" ? Theme.primary : Theme.surfaceText
                    }

                    MouseArea {
                        id: fetchAllArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.busy === ""
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fetchAll()
                    }
                }
            }

            DankFlickable {
                id: list

                width: parent.width
                height: root.popoutHeight - popout.headerHeight - Theme.spacingL * 2
                contentHeight: column.height
                clip: true

                Column {
                    id: column

                    width: parent.width
                    spacing: 2

                    // The overview with its words, in the colours the rows use: what the
                    // pill's counts mean, and what the colours mean.
                    Flow {
                        id: overviewStrip

                        property bool labelled: true

                        visible: root.loaded && root.repos.length > 0
                        width: parent.width
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        bottomPadding: Theme.spacingS
                        spacing: Theme.spacingM

                        StyledText {
                            text: root.repos.length + (root.repos.length === 1 ? " repository" : " repositories")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.NoWrap
                        }

                        Repeater {
                            model: root.overviewChips
                            delegate: chipDelegate
                        }
                    }

                    StyledText {
                        visible: !root.loaded && root.checking
                        text: "Checking…"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    StyledText {
                        visible: root.loaded && root.repos.length === 0
                        text: "No repositories under " + root.rootDir
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    Repeater {
                        model: root.repos

                        delegate: Column {
                            id: item

                            required property var modelData
                            required property int index
                            readonly property bool isOpen: root.expanded === modelData.id
                            readonly property bool firstOfOwner: index === 0 || root.repos[index - 1].owner !== modelData.owner
                            readonly property string summaryText: root.busy === "fetch:" + modelData.id ? "fetching…" : root.summary(modelData)
                            readonly property color tint: root.tint(modelData)
                            readonly property var linkedWorktrees: (modelData.worktrees || []).filter(w => !w.main)

                            // A Repeater evaluates a delegate once before it has a parent.
                            width: parent ? parent.width : 0
                            spacing: 2

                            // The owner, above its first repository.
                            StyledText {
                                visible: item.firstOfOwner
                                text: item.modelData.owner
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                topPadding: item.index === 0 ? 0 : Theme.spacingS
                                leftPadding: Theme.spacingM
                            }

                            Rectangle {
                                id: row

                                width: parent.width
                                height: 44
                                radius: Theme.cornerRadius
                                color: area.containsMouse || item.isOpen ? Theme.primaryHover : "transparent"

                                // Three columns, the same on every row: the name, the branch and the
                                // status each get a fixed share of the row (root.colNameShare,
                                // root.colBranchShare, the status the rest), so they line up down the
                                // whole list whatever the text in a row is. Text longer than its
                                // column is cut short (the status wraps to a second line first), it
                                // never moves or squeezes a neighbour. Nothing here sizes itself
                                // from its content or centres in leftover room: a RowLayout of
                                // capped items does exactly that (it centres the group), which is
                                // what this replaced.
                                readonly property real gap: Theme.spacingS
                                readonly property real nameX: Theme.spacingM + Theme.iconSizeSmall + gap
                                readonly property real columnsWidth: width - nameX - Theme.spacingM - gap * 2
                                readonly property real nameWidth: Math.floor(columnsWidth * root.colNameShare)
                                readonly property real branchWidth: Math.floor(columnsWidth * root.colBranchShare)
                                readonly property real statusWidth: columnsWidth - nameWidth - branchWidth

                                DankIcon {
                                    x: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: item.isOpen ? "expand_more" : "chevron_right"
                                    size: Theme.iconSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                StyledText {
                                    id: nameLabel

                                    x: row.nameX
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: row.nameWidth
                                    horizontalAlignment: Text.AlignLeft
                                    text: item.modelData.name
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    wrapMode: Text.NoWrap
                                }

                                StyledText {
                                    id: branchLabel

                                    x: row.nameX + row.nameWidth + row.gap
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: row.branchWidth
                                    horizontalAlignment: Text.AlignLeft
                                    text: item.modelData.branch
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.NoWrap
                                }

                                StyledText {
                                    id: summaryLabel

                                    x: row.nameX + row.nameWidth + row.gap + row.branchWidth + row.gap
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: row.statusWidth
                                    horizontalAlignment: Text.AlignRight
                                    maximumLineCount: 2
                                    text: item.summaryText
                                    color: item.tint
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                MouseArea {
                                    id: area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.expanded = item.isOpen ? "" : item.modelData.id
                                }
                            }

                            // The repository's details, under its row while open.
                            Column {
                                visible: item.isOpen
                                width: parent.width
                                spacing: 2
                                leftPadding: Theme.spacingM + Theme.iconSizeSmall + Theme.spacingS

                                readonly property real innerWidth: width - leftPadding - Theme.spacingM

                                // Actions: fetch, open, terminal, VS Code. A Flow, so a narrow popout or
                                // a large font wraps the buttons instead of pushing them off the edge.
                                Flow {
                                    width: parent.innerWidth
                                    spacing: Theme.spacingS

                                    Repeater {
                                        model: root.repoActions

                                        delegate: Rectangle {
                                            id: actionButton

                                            required property var modelData

                                            width: actionRow.width + Theme.spacingM * 2
                                            height: 30
                                            radius: 15
                                            color: actionArea.containsMouse ? Theme.primaryHover : Theme.surfaceVariantAlpha

                                            Row {
                                                id: actionRow
                                                anchors.centerIn: parent
                                                spacing: Theme.spacingXS

                                                DankIcon {
                                                    name: actionButton.modelData.icon
                                                    size: Theme.iconSizeSmall
                                                    color: Theme.surfaceText
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                StyledText {
                                                    text: actionButton.modelData.label
                                                    color: Theme.surfaceText
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            MouseArea {
                                                id: actionArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: root.busy === ""
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    switch (actionButton.modelData.key) {
                                                    case "fetch":
                                                        root.fetchRepo(item.modelData);
                                                        break;
                                                    case "open":
                                                        root.openDir(item.modelData.path);
                                                        break;
                                                    case "terminal":
                                                        root.openTerminal(item.modelData.path);
                                                        break;
                                                    case "code":
                                                        root.openCode(item.modelData.path);
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // About 80 characters, wider than the popout: it wraps inside the
                                // available width instead of running off the right edge.
                                StyledText {
                                    width: parent.innerWidth
                                    wrapMode: Text.WordWrap
                                    text: (item.modelData.upstream ? "upstream " + item.modelData.upstream : "no upstream") + " · fetched " + root.ago(item.modelData.fetched) + " (fetch only downloads) · merges into " + item.modelData.integration
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    topPadding: Theme.spacingXS
                                }

                                // Branches: every local one; a merged one that is neither
                                // checked out nor the integration branch can be deleted.
                                Repeater {
                                    model: item.modelData.branches || []

                                    delegate: Column {
                                        id: branchItem

                                        required property var modelData
                                        readonly property bool deletable: modelData.merged && !modelData.head && !modelData.integration
                                        // The actions that would succeed for this branch (publish,
                                        // push, pull, switch); the "..." shows only when there are any.
                                        readonly property var actions: root.branchActions(item.modelData, modelData)
                                        readonly property bool isOpen: root.expandedBranch === item.modelData.id + ":" + modelData.name
                                        readonly property string note: {
                                            const parts = [];
                                            if (modelData.ahead > 0)
                                                parts.push("+" + modelData.ahead);
                                            if (modelData.merged)
                                                parts.push("merged");
                                            if (modelData.gone)
                                                parts.push("upstream gone");
                                            else if (modelData.upstream !== null && ((modelData.aheadUpstream || 0) > 0 || (modelData.behindUpstream || 0) > 0))
                                                parts.push("↑" + (modelData.aheadUpstream || 0) + " ↓" + (modelData.behindUpstream || 0));
                                            return parts.join(" · ");
                                        }

                                        width: parent.innerWidth
                                        spacing: 0

                                        Rectangle {
                                            id: branchRow

                                            width: parent.width
                                            height: 30
                                            radius: Theme.cornerRadius
                                            color: branchItem.isOpen ? Theme.primaryHover : "transparent"

                                            // Two columns, the same on every row (see the repository
                                            // rows): the name, and its note right-aligned, both stopping
                                            // short of the icon slots, which are reserved whether or
                                            // not this branch has its icons so the columns never move.
                                            readonly property real nameX: Theme.iconSizeSmall + Theme.spacingS
                                            readonly property real textWidth: Math.max(0, width - nameX - root.iconSlotsWidth - Theme.spacingS)
                                            readonly property real nameWidth: Math.floor(textWidth * root.detailNameShare)
                                            readonly property real noteWidth: Math.max(0, textWidth - nameWidth - Theme.spacingS)

                                            DankIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: branchItem.modelData.head ? "radio_button_checked" : "radio_button_unchecked"
                                                size: Theme.iconSizeSmall
                                                color: branchItem.modelData.head ? Theme.primary : Theme.surfaceVariantText
                                            }

                                            StyledText {
                                                x: branchRow.nameX
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: branchRow.nameWidth
                                                horizontalAlignment: Text.AlignLeft
                                                text: branchItem.modelData.name
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: branchItem.modelData.head ? Font.Bold : Font.Normal
                                                wrapMode: Text.NoWrap
                                            }

                                            StyledText {
                                                x: branchRow.nameX + branchRow.nameWidth + Theme.spacingS
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: branchRow.noteWidth
                                                horizontalAlignment: Text.AlignRight
                                                text: branchItem.note
                                                color: branchItem.modelData.merged || branchItem.modelData.gone ? Theme.surfaceVariantText : Theme.warning
                                                font.pixelSize: Theme.fontSizeSmall
                                                wrapMode: Text.NoWrap
                                            }

                                            Row {
                                                id: branchIcons

                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 0

                                                // The branch's actions, under its row while open.
                                                Rectangle {
                                                    visible: branchItem.actions.length > 0
                                                    width: 28
                                                    height: 28
                                                    radius: 14
                                                    color: moreArea.containsMouse || branchItem.isOpen ? Theme.primaryHover : "transparent"

                                                    DankIcon {
                                                        anchors.centerIn: parent
                                                        name: "more_horiz"
                                                        size: Theme.iconSizeSmall
                                                        color: branchItem.isOpen ? Theme.primary : Theme.surfaceVariantText
                                                    }

                                                    MouseArea {
                                                        id: moreArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.expandedBranch = branchItem.isOpen ? "" : item.modelData.id + ":" + branchItem.modelData.name
                                                    }
                                                }

                                                Rectangle {
                                                    visible: branchItem.deletable
                                                    width: 28
                                                    height: 28
                                                    radius: 14
                                                    color: deleteArea.containsMouse ? Theme.errorHover : "transparent"

                                                    DankIcon {
                                                        anchors.centerIn: parent
                                                        name: "delete"
                                                        size: Theme.iconSizeSmall
                                                        color: deleteArea.containsMouse ? Theme.error : Theme.surfaceVariantText
                                                    }

                                                    MouseArea {
                                                        id: deleteArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        enabled: root.busy === ""
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.deleteBranch(item.modelData, branchItem.modelData)
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            visible: branchItem.isOpen
                                            width: parent.width
                                            spacing: 0

                                            Repeater {
                                                model: branchItem.actions

                                                delegate: Rectangle {
                                                    id: branchActionRow

                                                    required property var modelData

                                                    width: parent.width
                                                    height: 28
                                                    radius: Theme.cornerRadius
                                                    color: branchActionArea.containsMouse ? Theme.primaryHover : "transparent"

                                                    Row {
                                                        anchors.left: parent.left
                                                        // Lines up with the branch's name above.
                                                        anchors.leftMargin: Theme.iconSizeSmall + Theme.spacingS
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: Theme.spacingS

                                                        DankIcon {
                                                            name: branchActionRow.modelData.icon
                                                            size: Theme.iconSizeSmall
                                                            color: Theme.surfaceVariantText
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }

                                                        StyledText {
                                                            text: branchActionRow.modelData.label
                                                            color: Theme.surfaceText
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: branchActionArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        enabled: root.busy === ""
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.branchAction(item.modelData, branchItem.modelData, branchActionRow.modelData.key)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Linked worktrees: a terminal there, and removal when clean.
                                StyledText {
                                    visible: item.linkedWorktrees.length > 0
                                    text: "Worktrees"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    topPadding: Theme.spacingXS
                                }

                                Repeater {
                                    model: item.linkedWorktrees

                                    delegate: Rectangle {
                                        id: worktreeRow

                                        required property var modelData
                                        readonly property bool removable: modelData.exists && modelData.dirty === 0
                                        readonly property string note: {
                                            if (!modelData.exists)
                                                return "missing";
                                            const parts = [modelData.detached ? "detached" : (modelData.branch || "")];
                                            if (modelData.dirty > 0)
                                                parts.push(modelData.dirty + " changed");
                                            return parts.filter(p => p !== "").join(" · ");
                                        }

                                        width: parent.innerWidth
                                        height: 30
                                        radius: Theme.cornerRadius
                                        color: "transparent"

                                        // Two columns, the same on every row, like the branch rows:
                                        // the path and its note right-aligned, both stopping short
                                        // of the icon slots (reserved whether or not the worktree
                                        // has its icons). A path is the long part (one under
                                        // .claude/worktrees is 60 characters), so it elides in the
                                        // middle, where the name that tells worktrees apart stays
                                        // at the end.
                                        readonly property real nameX: Theme.iconSizeSmall + Theme.spacingS
                                        readonly property real textWidth: Math.max(0, width - nameX - root.iconSlotsWidth - Theme.spacingS)
                                        readonly property real nameWidth: Math.floor(textWidth * root.detailNameShare)
                                        readonly property real noteWidth: Math.max(0, textWidth - nameWidth - Theme.spacingS)

                                        DankIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "folder"
                                            size: Theme.iconSizeSmall
                                            color: Theme.surfaceVariantText
                                        }

                                        StyledText {
                                            x: worktreeRow.nameX
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: worktreeRow.nameWidth
                                            horizontalAlignment: Text.AlignLeft
                                            text: root.shortPath(worktreeRow.modelData.path, item.modelData.path)
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeSmall
                                            wrapMode: Text.NoWrap
                                            elide: Text.ElideMiddle
                                        }

                                        StyledText {
                                            x: worktreeRow.nameX + worktreeRow.nameWidth + Theme.spacingS
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: worktreeRow.noteWidth
                                            horizontalAlignment: Text.AlignRight
                                            text: worktreeRow.note
                                            color: worktreeRow.modelData.dirty > 0 || !worktreeRow.modelData.exists ? Theme.warning : Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                            wrapMode: Text.NoWrap
                                        }

                                        Row {
                                            id: worktreeIcons

                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 0

                                            Rectangle {
                                                visible: worktreeRow.modelData.exists
                                                width: 28
                                                height: 28
                                                radius: 14
                                                color: wtTerminalArea.containsMouse ? Theme.primaryHover : "transparent"

                                                DankIcon {
                                                    anchors.centerIn: parent
                                                    name: "terminal"
                                                    size: Theme.iconSizeSmall
                                                    color: Theme.surfaceVariantText
                                                }

                                                MouseArea {
                                                    id: wtTerminalArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.openTerminal(worktreeRow.modelData.path)
                                                }
                                            }

                                            Rectangle {
                                                visible: worktreeRow.removable
                                                width: 28
                                                height: 28
                                                radius: 14
                                                color: wtRemoveArea.containsMouse ? Theme.errorHover : "transparent"

                                                DankIcon {
                                                    anchors.centerIn: parent
                                                    name: "delete"
                                                    size: Theme.iconSizeSmall
                                                    color: wtRemoveArea.containsMouse ? Theme.error : Theme.surfaceVariantText
                                                }

                                                MouseArea {
                                                    id: wtRemoveArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    enabled: root.busy === ""
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.removeWorktree(item.modelData, worktreeRow.modelData)
                                                }
                                            }
                                        }
                                    }
                                }

                                Item {
                                    width: 1
                                    height: Theme.spacingS
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
