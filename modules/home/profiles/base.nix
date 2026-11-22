# The home `base` profile: what any home-manager configuration of this setup has,
# on NixOS or not. home-manager manages itself, and fontconfig sees the user's fonts.
# (`EDITOR` is not here: dots' nvim area sets it, through programs.neovim.defaultEditor.)
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  options.dots.profile.base.enable = lib.mkEnableOption "the home base profile: home-manager managing itself, and fontconfig";

  config = lib.mkIf config.dots.profile.base.enable {
    programs.home-manager.enable = mkDefault true;
    fonts.fontconfig.enable = mkDefault true;
  };
}
