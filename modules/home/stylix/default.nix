{pkgs, ...}: {
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";
    targets = {
      firefox.profileNames = ["cathe"];
      kitty.enable = true;
      starship.enable = false;
      neovim.enable = false;
      ## disable for gnome
      qt.enable = false;
      gnome.enable = false;
      gtk.enable = false;
      ## gnome-shell.enable = false;
    };

    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    #base16Scheme = {
    #  base00 = "282828"; # bg ----
    #  base01 = "3c3836"; # bg ---
    #  base02 = "504945"; # bg --
    #  base03 = "665c54"; # bg -
    #  base04 = "bdae93"; # fg +
    #  base05 = "d5c4a1"; # fg ++
    #  base06 = "ebdbb2"; # fg +++
    #  base07 = "fbf1c7"; # fg ++++
    #  base08 = "cc241d"; # red
    #  base09 = "d65d0e"; # orange
    #  base0A = "d79921"; # yellow
    #  base0B = "98971a"; # green
    #  base0C = "689d6a"; # aqua
    #  base0D = "458588"; # blue
    #  base0E = "b16286"; # purple
    #  base0F = "d65d0e"; # brown
    #};

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
        #        package = pkgs.nerd-fonts.fira-code;
        #        name = "FiraCode Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.cantarell-fonts;
        name = "Cantarell";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };
}
