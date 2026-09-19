{pkgs, ...}: {
  imports = [
    ../../modules/home
    ./modules/home
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cathe";
  home.homeDirectory = "/home/cathe";

  home.sessionPath = ["$HOME/dots/bin"];

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
    discord

    expat # required by fontconfig?
    fontconfig

    ## https://github.com/ilyamiro/nixos-configuration/blob/master/home.nix
    adwaita-icon-theme
    adw-gtk3
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.lazydocker = {
    enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # set cursor
  ## https://github.com/ilyamiro/nixos-configuration/blob/master/home.nix
  home.pointerCursor = let
    getFrom = url: hash: name: {
      gtk.enable = true;
      x11.enable = true;
      name = name;
      size = 24;
      package = pkgs.runCommand "moveUp" {} ''
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

  gtk = {
    enable = true;

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

  fonts.fontconfig.enable = true;
}
