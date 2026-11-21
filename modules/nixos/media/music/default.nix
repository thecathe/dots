{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.dots.media.enable {
    environment.systemPackages = with pkgs; [
      strawberry # # local library player, MPRIS-native
    ];
  };
}
