{ inputs, pkgs, ... }:
{
  inputs.stylix = {
    enable = true;
    targets = {
      kitty.enable = true;
      neovim.enable = true;
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };
}
