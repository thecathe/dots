#!/usr/bin/env bash
# Tests plugins/dotsServices/ServicesMenu.qml in Qt's QML engine, offscreen, with
# simulated mouse clicks. The DMS modules the plugin imports (qs.Common, qs.Services,
# qs.Modules.Plugins, qs.Widgets) are replaced by the small stand-ins in ./stubs, which
# record the commands the plugin runs instead of running them. So this covers the
# plugin's own logic (what a click on a row, on "...", or on an action does), not how
# it looks or behaves inside the live DMS bar.
#
# Not part of `nix flake check` (it needs Qt and an offscreen display); run it by hand
# after changing the plugin:   checks/qml/dotsServices/run.sh
set -euo pipefail
cd "$(dirname "$0")"
flake=$(cd ../../.. && pwd)
qtd=$(nix build --no-link --print-out-paths --inputs-from "$flake" nixpkgs#qt6.qtdeclarative | head -1)
qtb=$(nix build --no-link --print-out-paths --inputs-from "$flake" nixpkgs#qt6.qtbase | head -1)
QT_QPA_PLATFORM=offscreen \
  QT_PLUGIN_PATH="$qtb/lib/qt-6/plugins" \
  QML_IMPORT_PATH="$qtd/lib/qt-6/qml:$PWD/stubs" \
  exec "$qtd/bin/qmltestrunner" -import "$PWD/stubs" -import "$qtd/lib/qt-6/qml" -input tst_services.qml "$@"
