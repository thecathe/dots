{
  config,
  pkgs,
  inputs,
  ...
}: let
  nixgl = inputs.nixgl;
  nixGLPrefix = "${nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel}/bin/nixGLIntel";
  ## auto detection version
  # nixGLPrefix = "${nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGL}/bin/nixGL";
in {
  imports = [
    ../../modules/home
  ];

  ## override
  stylix.targets.kde.enable = false;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  home.username = "jjp38";
  home.homeDirectory = "/home/jjp38";
  home.stateVersion = "25.11";
  news.display = "silent";

  home.sessionPath = ["$HOME/dots/bin"];

  # Required for standalone home-manager (non-NixOS hosts)
  programs.home-manager.enable = true;

  home.packages = with pkgs;
    (import ../../modules/shared/fonts.nix pkgs)
    ++ [
      wget
      fzf
      git
      gh
      tmux
      nix
      nixfmt
    ];

  ## NOTE: must install zsh using apt
  programs.zsh = {
    enable = true;
    shellAliases = {
      rebuild = ''
        (cd ~/dots && home-manager switch --flake .#cathe@worklaptop);
        printf "Press Enter to continue...";
        read -r _
      '';
    };
  };

  ## override
  programs.kitty = {
    enable = true;
    package = (
      pkgs.writeShellScriptBin "kitty" ''
        exec ${nixGLPrefix} ${pkgs.kitty}/bin/kitty "$@"
      ''
    );
  };

  xdg.desktopEntries.kitty = {
    name = "Kitty";
    genericName = "Terminal Emulator";
    exec = "${nixGLPrefix}${pkgs.kitty}/bin/kitty";
    icon = "${pkgs.kitty}/share/icons/hicolor/256x256/apps/kitty.png";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    settings = {StartupWMClass = "kitty";};
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  systemd.user.sessionVariables = {
    KP_EDITOR = "neovide";
  };

  fonts.fontconfig.enable = true;
}
