{lib, ...}: {
  imports = [
    ./music
    ./thumbnails
    ./immich
  ];
  options.dots.media.enable = lib.mkEnableOption "the music player and the thumbnail generators" // {default = true;};
}
