{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    targets = {
      firefox.profileNames = [ "cathe" ];
      kitty.enable = true;
      neovim.enable = true;
      qt.enable = false; # disable for gnome
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };
}
