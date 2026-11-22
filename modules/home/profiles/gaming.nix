# The home `gaming` profile: the Steam launcher entry, for a machine with the NixOS
# `gaming` profile. `steamEnv` puts variables in front of Steam in that entry only,
# for what one GPU needs and the rest of the session must not get (NVIDIA's GBM
# path, for example, which niri itself should not be forced onto).
{
  config,
  lib,
  ...
}: let
  cfg = config.dots.profile.gaming;
in {
  options.dots.profile.gaming = {
    enable = lib.mkEnableOption "the home gaming profile: the Steam launcher entry";
    steamEnv = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["GBM_BACKEND=nvidia-drm" "__GLX_VENDOR_LIBRARY_NAME=nvidia"];
      description = ''
        `NAME=value` pairs set for Steam (and so for gamescope and the games) by its
        launcher entry, in this order, and for nothing else in the session.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.desktopEntries.steam = {
      name = "Steam";
      exec = lib.concatStringsSep " " ((lib.optionals (cfg.steamEnv != []) (["env"] ++ cfg.steamEnv)) ++ ["steam" "-pipewire" "%U"]);
      icon = "steam";
      terminal = false;
      categories = [
        "Network"
        "FileTransfer"
        "Game"
      ];
      mimeType = [
        "x-scheme-handler/steam"
        "x-scheme-handler/steamlink"
      ];
    };
  };
}
