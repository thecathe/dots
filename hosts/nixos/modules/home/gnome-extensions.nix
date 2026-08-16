{pkgs, ...}: {
  dconf.enable = true;

  home.packages = [
    pkgs.gnomeExtensions.disable-unredirect-fullscreen-windows
  ];

  dconf.settings."org/gnome/shell".enabled-extensions = [
    pkgs.gnomeExtensions.disable-unredirect-fullscreen-windows.extensionUuid
  ];
}
