{ pkgs, ... }:

{
  imports = [
    ./firefox.nix
    ./git.nix
    ./hyprland.nix
    ./neovim.nix
    ./steam.nix
    ./zsh.nix
  ];
}
