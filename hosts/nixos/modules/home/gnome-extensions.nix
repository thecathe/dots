{pkgs, ...}: {
  dconf.enable = true;

  home.packages = with pkgs.gnomeExtensions; [
    disable-unredirect # fix screencast fullscreen
    appindicator # system tray (e.g., steam)
    just-perfection # ?
    vitals # CPU/GPU stats
    tiling-assistant # windows-like tile snapping
    tiling-shell # maybe better tiling?
    auto-move-windows # configure workstations to open on
  ];

  dconf.settings."org/gnome/shell".enabled-extensions = with pkgs.gnomeExtensions; [
    disable-unredirect.extensionUuid
    appindicator.extensionUuid
    just-perfection.extensionUuid
    vitals.extensionUuid
    tiling-assistant.extensionUuid
    tiling-shell.extensionUuid
    auto-move-windows.extensionUuid
  ];
}
