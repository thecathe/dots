{pkgs, ...}: {
  # mkNixos imports stylix's NixOS module; it has to be enabled at this level
  # for the home-manager side (modules/home/stylix) to get its options.
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };
}
