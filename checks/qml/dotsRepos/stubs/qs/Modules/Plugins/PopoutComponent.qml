import QtQuick
// The real one is a Column with a 40px header; headerActions is a Component
// shown in the header. Kept the same shape so the plugin's sizing works.
Column {
    property string headerText
    property bool showCloseButton
    property alias headerActions: headerActionsLoader.sourceComponent
    readonly property int headerHeight: 40
    Item {
        width: parent.width
        height: 40
        Loader {
            id: headerActionsLoader
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
