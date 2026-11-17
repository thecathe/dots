import QtQuick
// The real one (DankCommon/Widgets/StyledText.qml) is a Text that wraps and elides by
// default, so a text given less width than it wants WRAPS onto a second line unless the
// user sets wrapMode: Text.NoWrap. The stub keeps those two defaults for that reason.
Text {
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
}
