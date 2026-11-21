{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.fonts.enable = lib.mkEnableOption "dots' font packages" // {default = true;};

  config = lib.mkIf config.dots.fonts.enable {
    fonts.packages = import ../shared/fonts.nix pkgs; # ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };
}
