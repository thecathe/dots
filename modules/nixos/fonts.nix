{pkgs, ...}: {
  fonts.packages = import ../shared/fonts.nix pkgs; # ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
