pragma Singleton
import QtQuick
QtObject {
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    property real iconSize: 24
    property real iconSizeSmall: 16
    property real cornerRadius: 12
    property real fontSizeMedium: 14
    property color primary: "#6750a4"
    property color primaryHover: "#1f6750a4"
    property color surfaceText: "#e6e0e9"
    property color surfaceVariantText: "#cac4d0"
    property color widgetIconColor: "#e6e0e9"
    function barIconSize(thickness, offset) { return thickness + offset; }
}
