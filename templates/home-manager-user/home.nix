{pkgs, ...}: {
  home.username = "NEW_USER";
  home.homeDirectory = "/home/NEW_USER";
  home.stateVersion = "25.11";

  # Required for standalone home-manager
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "NEW_USER";
    userEmail = "replace-me@example.com";
  };

  home.packages = with pkgs; [
    wget
    fzf
    git
    gh
    tmux
    nix
    nixfmt
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
