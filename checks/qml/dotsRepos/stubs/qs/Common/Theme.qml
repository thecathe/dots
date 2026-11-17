pragma Singleton
import QtQuick
QtObject {
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    property real spacingL: 16
    property real iconSize: 24
    property real iconSizeSmall: 16
    property real cornerRadius: 12
    property real fontSizeMedium: 14
    property real fontSizeSmall: 12
    property color primary: "#6750a4"
    property color primaryHover: "#1f6750a4"
    property color error: "#b3261e"
    property color errorHover: "#1fb3261e"
    property color warning: "#ff9800"
    property color success: "#4caf50"
    property int shortDuration: 40
    property color surfaceVariantAlpha: "#33cac4d0"
    property color surfaceText: "#e6e0e9"
    property color surfaceVariantText: "#cac4d0"
    property color widgetIconColor: "#e6e0e9"
    function barIconSize(thickness, offset) { return thickness + offset; }
    function barTextSize(thickness, scale, maximize) { return 12; }
}
