{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    targets = {
      firefox.profileNames = [ "cathe" ];
      kitty.enable = true;
      starship.enable = true;
      neovim.enable = true;
      qt.enable = false; # disable for gnome
      ## gnome-shell.enable = false;
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
#        package = pkgs.nerd-fonts.fira-code;
#        name = "FiraCode Nerd Font Mono";
      };
    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };
    };
  };
}
