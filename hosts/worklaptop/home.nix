{ config, pkgs, inputs, ... }: {
  imports = [
    ../../modules/home
  ];

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  home.username = "jjp38";
  home.homeDirectory = "/home/jjp38";
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
