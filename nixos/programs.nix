{ pkgs, ... }:

{
  imports = [
    ./programs/firefox.nix
    ./programs/git.nix
    ./programs/hyprland.nix
    ./programs/neovim.nix
    ./programs/steam.nix
    ./programs/zsh.nix
  ];
}
