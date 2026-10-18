import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

// Daemon surface: lives for the whole session, so the IPC target exists
// before the menu is first opened. Layout and key handling follow DMS's own
// power menu (Modules/PowerMenu/PowerMenuContent.qml, list mode).
// Maintenance notes: README.md next to this file.
PluginComponent {
    id: root

    // [{ key, label, icon, and one of: command: [argv...] | entries: [...] |
    // generator: [argv...] }], from this plugin's settings (written by
    // modules/home/dank/curated-menu.nix, which checks the static entries).
    readonly property var entries: pluginData.entries || []

    // Open submenus, innermost last: [{ title, entries }]. Empty at the top.
    property var stack: []
    readonly property var current: stack.length > 0 ? stack[stack.length - 1].entries : entries
    readonly property string title: stack.length > 0 ? stack[stack.length - 1].title : ""

    signal levelChanged

    function push(title, items) {
        stack = stack.concat([{
                title: title,
                entries: items
            }]);
        levelChanged();
    }

    function back() {
        if (stack.length === 0) {
            modal.close();
            return;
        }
        stack = stack.slice(0, -1);
        levelChanged();
    }

    function activate(index) {
        const entry = current[index];
        if (!entry)
            return;
        if (entry.entries && entry.entries.length > 0) {
            push(entry.label, entry.entries);
        } else if (entry.generator) {
            generator.title = entry.label;
            generator.command = entry.generator;
            generator.running = true;
        } else if (entry.command) {
            modal.close();
            Quickshell.execDetached(entry.command);
        }
    }

    // Runs an entry's generator; its stdout is the submenu's entries as JSON.
    Process {
        id: generator

        property string title: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") {
                    ToastService.showError(generator.title + ": generator printed nothing (did it fail?)");
                    return;
                }
                let items;
                try {
                    items = JSON.parse(text);
                } catch (e) {
                    ToastService.showError(generator.title + ": generator output is not JSON", String(e));
                    return;
                }
                if (Array.isArray(items) && items.length > 0)
                    root.push(generator.title, items);
                else
                    ToastService.showError(generator.title + ": nothing to show");
            }
        }
    }

    IpcHandler {
        target: "curatedMenu"

        function toggle(): string {
            modal.toggle();
            return "CURATED_MENU_TOGGLED";
        }

        function open(): string {
            modal.open();
            return "CURATED_MENU_OPENED";
        }

        function close(): string {
            modal.close();
            return "CURATED_MENU_CLOSED";
        }
    }

    DankModal {
        id: modal

        layerNamespace: "dms:curated-menu"
        useOverlayLayer: true
        positioning: "center"
        // Esc goes back a level (handled below) rather than always closing.
        closeOnEscapeKey: false
        modalWidth: 400
        modalHeight: contentLoader.item ? contentLoader.item.implicitHeight : 300

        onShouldBeVisibleChanged: {
            if (shouldBeVisible) {
                root.stack = [];
                root.levelChanged();
            }
        }
        onShouldHaveFocusChanged: {
            if (shouldHaveFocus)
                Qt.callLater(() => contentLoader.item?.forceActiveFocus());
        }

        content: Component {
            FocusScope {
                id: menu

                property int selectedIndex: 0

                anchors.fill: parent
                focus: true
                implicitHeight: column.implicitHeight + Theme.spacingL * 2

                Connections {
                    target: root
                    function onLevelChanged() {
                        menu.selectedIndex = 0;
                    }
                }

                Keys.onPressed: event => {
                    event.accepted = true;
                    const count = root.current.length;
                    switch (event.key) {
                    case Qt.Key_Escape:
                    case Qt.Key_Backspace:
                    case Qt.Key_Left:
                        root.back();
                        return;
                    case Qt.Key_J:
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        if (count > 0)
                            selectedIndex = (selectedIndex + 1) % count;
                        return;
                    case Qt.Key_K:
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                        if (count > 0)
                            selectedIndex = (selectedIndex - 1 + count) % count;
                        return;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Right:
                        root.activate(selectedIndex);
                        return;
                    }
                    // Modifier and other non-text keys have empty text; never
                    // let them match an entry without a key.
                    const index = event.text === "" ? -1 : root.current.findIndex(e => e.key === event.text);
                    if (index >= 0)
                        root.activate(index);
                    else
                        event.accepted = false;
                }

                Column {
                    id: column

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Theme.spacingL
                    }
                    spacing: Theme.spacingS

                    // Submenu title; Esc/Backspace/Left goes back.
                    Row {
                        visible: root.stack.length > 0
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "arrow_back"
                            size: Theme.iconSize
                            color: Theme.surfaceTextSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.title
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceTextSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Repeater {
                        model: root.current

                        Rectangle {
                            id: row

                            required property int index
                            required property var modelData
                            readonly property bool isSelected: menu.selectedIndex === index
                            readonly property bool isSubmenu: !!(modelData.generator || (modelData.entries && modelData.entries.length > 0))

                            width: parent.width
                            height: 48
                            radius: Theme.cornerRadius
                            color: isSelected ? Theme.primaryHover : (mouseArea.containsMouse ? Theme.primaryHoverLight : Theme.surfaceHover)
                            border.color: isSelected ? Theme.primary : Theme.withAlpha(Theme.primary, 0)
                            border.width: isSelected ? 2 : 0

                            Row {
                                anchors {
                                    left: parent.left
                                    right: trailing.left
                                    leftMargin: Theme.spacingM
                                    rightMargin: Theme.spacingM
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: Theme.spacingM

                                DankIcon {
                                    name: row.modelData.icon || "chevron_right"
                                    size: Theme.iconSize + 4
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: row.modelData.label
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                id: trailing

                                spacing: Theme.spacingXS
                                anchors {
                                    right: parent.right
                                    rightMargin: Theme.spacingM
                                    verticalCenter: parent.verticalCenter
                                }

                                DankIcon {
                                    visible: row.isSubmenu
                                    name: "chevron_right"
                                    size: Theme.iconSize
                                    color: Theme.surfaceTextSecondary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    visible: !!row.modelData.key
                                    width: 28
                                    height: 20
                                    radius: 4
                                    color: Theme.onSurface_12
                                    anchors.verticalCenter: parent.verticalCenter

                                    StyledText {
                                        text: row.modelData.key || ""
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceTextSecondary
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            MouseArea {
                                id: mouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: menu.selectedIndex = row.index
                                onClicked: root.activate(row.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
