# The home `gnome` profile: the half of the GNOME desktop that lives in the user's
# home, for a machine with the NixOS `gnome` profile. Seven GNOME Shell extensions,
# turned on through dconf, and a dark GTK theme (adw-gtk3 for GTK 3, the dark
# preference for GTK 4) with the Adwaita icons.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
  extensions = with pkgs.gnomeExtensions; [
    disable-unredirect # fixes screen casting full-screen windows
    appindicator # system tray (Steam, for one)
    just-perfection
    vitals # CPU and GPU stats
    tiling-assistant # Windows-like tile snapping
    tiling-shell
    auto-move-windows # which workspace an application opens on
  ];
in {
  options.dots.profile.gnome.enable = lib.mkEnableOption "the home gnome profile: GNOME Shell extensions and a dark GTK theme";

  config = lib.mkIf config.dots.profile.gnome.enable {
    dconf.enable = mkDefault true;

    home.packages =
      extensions
      ++ (with pkgs; [
        adwaita-icon-theme
        adw-gtk3
      ]);

    dconf.settings."org/gnome/shell".enabled-extensions = map (e: e.extensionUuid) extensions;

    gtk = {
      enable = mkDefault true;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = mkDefault 1;
        gtk-theme-name = mkDefault "adw-gtk3-dark";
      };
      gtk4.extraConfig.gtk-application-prefer-dark-theme = mkDefault 1;
    };
  };
}
