{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts
  ];
  # ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
