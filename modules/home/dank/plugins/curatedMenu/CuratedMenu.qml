import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Modules.Plugins
import qs.Widgets

// Daemon surface: lives for the whole session, so the IPC target exists
// before the menu is first opened. Layout and key handling follow DMS's own
// power menu (Modules/PowerMenu/PowerMenuContent.qml, list mode).
PluginComponent {
    id: root

    // [{ key, label, icon, command: [argv...] }], from this plugin's settings
    // (written by modules/home/dank/curated-menu.nix, which also checks that
    // keys are single characters, unique, and not j/k).
    readonly property var entries: pluginData.entries || []

    function run(index) {
        const entry = entries[index];
        if (!entry)
            return;
        modal.close();
        Quickshell.execDetached(entry.command);
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
        modalWidth: 400
        modalHeight: contentLoader.item ? contentLoader.item.implicitHeight : 300

        onShouldBeVisibleChanged: {
            if (shouldBeVisible && contentLoader.item)
                contentLoader.item.selectedIndex = 0;
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

                Keys.onPressed: event => {
                    event.accepted = true;
                    const count = root.entries.length;
                    switch (event.key) {
                    case Qt.Key_Escape:
                        modal.close();
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
                        root.run(selectedIndex);
                        return;
                    }
                    const index = root.entries.findIndex(e => e.key === event.text);
                    if (index >= 0)
                        root.run(index);
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

                    Repeater {
                        model: root.entries

                        Rectangle {
                            id: row

                            required property int index
                            required property var modelData
                            readonly property bool isSelected: menu.selectedIndex === index

                            width: parent.width
                            height: 48
                            radius: Theme.cornerRadius
                            color: isSelected ? Theme.primaryHover : (mouseArea.containsMouse ? Theme.primaryHoverLight : Theme.surfaceHover)
                            border.color: isSelected ? Theme.primary : Theme.withAlpha(Theme.primary, 0)
                            border.width: isSelected ? 2 : 0

                            Row {
                                anchors {
                                    left: parent.left
                                    right: keyCap.left
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

                            Rectangle {
                                id: keyCap

                                width: 28
                                height: 20
                                radius: 4
                                color: Theme.onSurface_12
                                anchors {
                                    right: parent.right
                                    rightMargin: Theme.spacingM
                                    verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: row.modelData.key
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceTextSecondary
                                    anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: mouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: menu.selectedIndex = row.index
                                onClicked: root.run(row.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
