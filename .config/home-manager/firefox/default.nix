{ pkgs, ... }:

{
  # https://mynixos.com/home-manager/options/programs.firefox
  programs.firefox = {
    enable = true;
    profiles = import ./profiles.nix { inherit pkgs; };
  };
}
