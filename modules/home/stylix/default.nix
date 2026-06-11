{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    targets = {
      firefox.profileNames = [ "cathe" ];
      kitty.enable = true;
      starship.enable = false;
      neovim.enable = true;
      qt.enable = false; # disable for gnome
      ## gnome-shell.enable = false;
    };
    

    ## base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    base16Scheme = {
      base00 = "282828";
      base01 = "3c3836";
      base02 = "504945";
      base03 = "665c54";
      base04 = "bdae93";
      base05 = "d5c4a1";
      base06 = "ebdbb2";
      base07 = "fbf1c7";
      base08 = "fb4934";
      base09 = "fe8019";
      base0A = "fabd2f";
      base0B = "b8bb26";
      base0C = "8ec07c";
      base0D = "83a598";
      base0E = "d3869b";
      base0F = "d65d0e";
    };

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
