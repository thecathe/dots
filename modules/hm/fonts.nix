{pkgs, ...}: {
  home.packages = import ../shared/fonts.nix pkgs;
}
