#!/usr/bin/env bash
# Tests plugins/dictationStatus/DictationStatus.qml in Qt's QML engine, offscreen. The DMS
# modules it imports (qs.Common, qs.Modules.Plugins, qs.Widgets) and Quickshell.Io are
# replaced by the small stand-ins in ./stubs: the "process" runs nothing and the test
# feeds it voxtype's output lines and makes it exit. So this covers the widget's own logic
# (what each state looks like, which lines are ignored, what happens when the command exits
# or changes), not Quickshell's real Process and SplitParser or how it looks in the live bar.
#
# Not part of `nix flake check` (it needs Qt and an offscreen display); run it by hand
# after changing the plugin:   checks/qml/dictationStatus/run.sh
set -euo pipefail
cd "$(dirname "$0")"
flake=$(cd ../../.. && pwd)
qtd=$(nix build --no-link --print-out-paths --inputs-from "$flake" nixpkgs#qt6.qtdeclarative | head -1)
qtb=$(nix build --no-link --print-out-paths --inputs-from "$flake" nixpkgs#qt6.qtbase | head -1)
QT_QPA_PLATFORM=offscreen \
  QT_PLUGIN_PATH="$qtb/lib/qt-6/plugins" \
  QML_IMPORT_PATH="$qtd/lib/qt-6/qml:$PWD/stubs" \
  exec "$qtd/bin/qmltestrunner" -import "$PWD/stubs" -import "$qtd/lib/qt-6/qml" -input tst_status.qml "$@"
