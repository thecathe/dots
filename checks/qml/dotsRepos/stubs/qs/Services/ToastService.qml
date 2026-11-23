pragma Singleton
import QtQuick
QtObject {
    property var errors: []
    property var warnings: []
    property var infos: []
    // details: the second argument, as the real ToastService takes it.
    property var details: []
    function showError(msg, d) { errors = errors.concat([msg]); details = details.concat([d || ""]); }
    function showWarning(msg, d) { warnings = warnings.concat([msg]); details = details.concat([d || ""]); }
    function showInfo(msg, d) { infos = infos.concat([msg]); details = details.concat([d || ""]); }
    function reset() { errors = []; warnings = []; infos = []; details = []; }
}
