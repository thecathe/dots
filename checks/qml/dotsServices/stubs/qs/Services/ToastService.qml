pragma Singleton
import QtQuick
QtObject {
    property var errors: []
    function showError(msg) { errors = errors.concat([msg]); }
    function reset() { errors = []; }
}
