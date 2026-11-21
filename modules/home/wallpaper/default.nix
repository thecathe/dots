{lib, ...}: {
  imports = [
    ./bing.nix
  ];
  options.dots.wallpaper.enable = lib.mkEnableOption "the Bing wallpaper tools" // {default = true;};
}
