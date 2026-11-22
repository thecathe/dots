# The home `base` profile: what any home-manager configuration of this setup has,
# on NixOS or not. home-manager manages itself, fontconfig sees the user's fonts, and
# the checkout's `bin` (scripts kept editable, no rebuild needed) is on PATH.
# (`EDITOR` is not here: dots' nvim area sets it, through programs.neovim.defaultEditor.)
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  imports = [../checkout.nix];

  options.dots.profile.base.enable = lib.mkEnableOption "the home base profile: home-manager managing itself, fontconfig, and the checkout's bin on PATH";

  config = lib.mkIf config.dots.profile.base.enable {
    programs.home-manager.enable = mkDefault true;
    fonts.fontconfig.enable = mkDefault true;
    # Follows dots.checkout, so a machine with the checkout elsewhere sets that once.
    home.sessionPath = ["${config.dots.checkout}/bin"];
  };
}
