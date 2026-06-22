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
    exec = "${nixGLPrefix} ${pkgs.kitty}/bin/kitty";
    icon = "kitty";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  fonts.fontconfig.enable = true;
}
