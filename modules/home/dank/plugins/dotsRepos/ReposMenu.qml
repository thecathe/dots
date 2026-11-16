import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

// Bar pill + popout listing every git repository under dots.repos.root.
// Nothing runs while the popout is closed: opening it runs the status command
// once (`repos --json`, modules/home/repos/repos.sh), whose JSON gives each
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

    // The last status: [{ id, owner, name, path, branch, detached, integration,
    // upstream, ahead, behind, dirty, operation, fetched, branches, unmerged, worktrees }].
    property var repos: []
    property string rootDir: pluginData.root || ""
    property bool checking: false
    property bool loaded: false
    // The action under way ("fetch", "fetch:<id>", "delete:<id>:<branch>",
    // "remove:<id>:<path>"), "" when none. One at a time.
    property string busy: ""
    // The repository whose details are open, "" when none. One at a time.
    property string expanded: ""

    readonly property int attention: repos.filter(r => root.needsAttention(r)).length

    function refresh() {
        if (statusCommand.length === 0)
            return;
        checking = true;
        // Up to a minute: a status walks every repository, a big one included.
        Proc.runCommand("dotsRepos.status", statusCommand, (stdout, exitCode) => {
            checking = false;
            if (exitCode !== 0) {
                ToastService.showError("Repositories: status failed (exit " + exitCode + ")");
                return;
            }
            try {
                const data = JSON.parse(stdout);
                repos = data.repos || [];
                if (data.root)
                    rootDir = data.root;
                loaded = true;
            } catch (e) {
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
    // A worktree's path without the root in front of it.
    function shortPath(path) {
        if (rootDir !== "" && path.indexOf(rootDir + "/") === 0)
            return path.substring(rootDir.length + 1);
        return path;
    }

    horizontalBarPill: Component {
        DankIcon {
            name: "account_tree"
            size: Theme.barIconSize(root.barThickness, -4)
            color: root.attention > 0 ? Theme.error : Theme.widgetIconColor
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

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: item.isOpen ? "expand_more" : "chevron_right"
                                        size: Theme.iconSizeSmall
                                        color: Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: item.modelData.name
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: item.modelData.branch
                                        color: Theme.surfaceVariantText
                                        font.pixelSize: Theme.fontSizeSmall
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
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

                                // Actions: fetch, open, terminal.
                                Row {
                                    spacing: Theme.spacingS

                                    Repeater {
                                        model: [
                                            { key: "fetch", label: "Fetch", icon: "sync" },
                                            { key: "open", label: "Open", icon: "folder_open" },
                                            { key: "terminal", label: "Terminal", icon: "terminal" }
                                        ]

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
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: (item.modelData.upstream ? "upstream " + item.modelData.upstream : "no upstream") + " · fetched " + root.ago(item.modelData.fetched) + " · merges into " + item.modelData.integration
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    topPadding: Theme.spacingXS
                                }

                                // Branches: every local one; a merged one that is neither
                                // checked out nor the integration branch can be deleted.
                                Repeater {
                                    model: item.modelData.branches || []

                                    delegate: Rectangle {
                                        id: branchRow

                                        required property var modelData
                                        readonly property bool deletable: modelData.merged && !modelData.head && !modelData.integration
                                        readonly property string note: {
                                            const parts = [];
                                            if (modelData.ahead > 0)
                                                parts.push("+" + modelData.ahead);
                                            if (modelData.merged)
                                                parts.push("merged");
                                            if (modelData.gone)
                                                parts.push("upstream gone");
                                            return parts.join(" · ");
                                        }

                                        width: parent.innerWidth
                                        height: 30
                                        radius: Theme.cornerRadius
                                        color: "transparent"

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.spacingS

                                            DankIcon {
                                                name: branchRow.modelData.head ? "radio_button_checked" : "radio_button_unchecked"
                                                size: Theme.iconSizeSmall
                                                color: branchRow.modelData.head ? Theme.primary : Theme.surfaceVariantText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: branchRow.modelData.name
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: branchRow.modelData.head ? Font.Bold : Font.Normal
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: branchRow.note
                                                color: branchRow.modelData.merged || branchRow.modelData.gone ? Theme.surfaceVariantText : Theme.warning
                                                font.pixelSize: Theme.fontSizeSmall
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Rectangle {
                                            visible: branchRow.deletable
                                            width: 28
                                            height: 28
                                            radius: 14
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
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
                                                onClicked: root.deleteBranch(item.modelData, branchRow.modelData)
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

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.spacingS

                                            DankIcon {
                                                name: "folder"
                                                size: Theme.iconSizeSmall
                                                color: Theme.surfaceVariantText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: root.shortPath(worktreeRow.modelData.path)
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: worktreeRow.note
                                                color: worktreeRow.modelData.dirty > 0 || !worktreeRow.modelData.exists ? Theme.warning : Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Row {
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
