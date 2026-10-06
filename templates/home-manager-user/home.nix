{pkgs, ...}: {
  home.username = "NEW_USER";
  home.homeDirectory = "/home/NEW_USER";
  home.stateVersion = "25.11";

  # Required for standalone home-manager
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "NEW_USER";
      email = "replace-me@example.com";
    };
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
