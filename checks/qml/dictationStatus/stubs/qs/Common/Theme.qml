pragma Singleton
import QtQuick
QtObject {
    property color primary: "#6750a4"
    property color error: "#b3261e"
    property real cornerRadius: 12
    property color warning: "#ff9800"
    property color surfaceVariantText: "#cac4d0"
    function barIconSize(thickness, offset) { return thickness + offset; }
}
