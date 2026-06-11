{ config, pkgs, inputs, ... }: {
  imports = [
    ../../modules/home
    # Add or remove host-specific module imports here:
    # ../../modules/home/hyprland
  ];

  home.username = "NEW_HOST";
  home.homeDirectory = "/home/NEW_HOST";
  home.stateVersion = "25.11";

  home.sessionPath = [ "$HOME/dots/bin" ];

  # Required for standalone home-manager (non-NixOS hosts)
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    wget fzf git gh tmux
    nix nixfmt
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
