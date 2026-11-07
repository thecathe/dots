import QtQuick
// Has its own Component.onCompleted, like DMS's, to show that the plugin's one runs as well.
Item {
    property var pluginData: ({})
    property real barThickness: 30
    property Component horizontalBarPill
    property Component verticalBarPill
    property bool baseCompleted: false
    // null until the plugin has said whether it wants to be shown.
    property var visibilityOverride: null
    function setVisibilityOverride(visible) { visibilityOverride = visible; }
    Component.onCompleted: baseCompleted = true
}
