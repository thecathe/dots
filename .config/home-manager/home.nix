{
  config,
  pkgs,
  input,
  ...
}:

let
  thenixuser = import /home/cathe/dots/user.nix { inherit pkgs; };
  # thehyprland = import (thenixuser.home + "/dots/nixos/programs/hyprland.nix") { };
in
{
  imports = [
    ./zsh
    ./direnv
    ./starship
    ./firefox
    # ./hyprland
    # ./battlenet
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = thenixuser.username;
  home.homeDirectory = thenixuser.home;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    nixfmt

    zsh # -powerlevel9k
    powerline
    git
    gh
    #    nix
    #    nix-index
    #   nix-diff
    #   neovim
    #vimPlugins.coc-nvim

    prismlauncher

    egl-wayland
    alacritty
    kitty
    hyprland
    waybar
    waybar-lyric
    hyprpaper
    ags
    sway
    swaylock
    hypridle

    expat # required by fontconfig?
    fontconfig # required by hyprland?

    hyprlandPlugins.hy3
    # hyprlandPlugins.hyprbars # err
    hyprlandPlugins.hyprsplit
    # hyprlandPlugins.hyprspace # err
    # hyprlandPlugins.hyprfocus # err
    # hyprlandPlugins.hyprtrails # err
    hyprlandPlugins.hypr-dynamic-cursors

    # waylock
    # quickshell ## replace waybar
    mutagen
    slurp
    eww
    rofi

    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtwebsockets
    gtk3

    ## https://github.com/ilyamiro/nixos-configuration/blob/master/home.nix
    adwaita-icon-theme
    adw-gtk3

    pomodoro

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cathe/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # nix
  #nix.settings.experimental-features = [ "nix-command" ];
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # set cursor
  ## https://github.com/ilyamiro/nixos-configuration/blob/master/home.nix
  home.pointerCursor =
    let
      getFrom = url: hash: name: {
        gtk.enable = true;
        x11.enable = true;
        name = name;
        size = 24;
        package = pkgs.runCommand "moveUp" { } ''
          mkdir -p $out/share/icons
          ln -s ${
            pkgs.fetchzip {
              url = url;
              hash = hash;
            }
          }/dist $out/share/icons/${name}
        '';
      };
    in
    getFrom "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE="
      "ArcMidnight-Cursors";

  # services.easyeffects.enable = true;

  gtk = {
    enable = true;

    # Global `theme` block has been entirely removed to protect GTK4 apps.

    # Target GTK3 specifically
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-theme-name = "adw-gtk3-dark";
    };

    # Keep GTK4 native but ensure it requests the dark preference
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  fonts.fontconfig.enable = true;

  #######

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings.user = {
      name = thenixuser.username;
      email = thenixuser.email;
    };
  };

  #  programs.steam.enable = true;

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    coc.enable = true;
  };

  ## https://github.com/CurryFavour/NixDotfiles/blob/main/modules/home.nix
  services.hyprpaper.enable = true;
  programs.prismlauncher.enable = true;
}
