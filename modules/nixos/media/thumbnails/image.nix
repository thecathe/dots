{
  config,
  lib,
  pkgs,
  ...
}:
## https://wiki.nixos.org/wiki/Thumbnails#Enable_Image_Thumbnails
{
  config = lib.mkIf config.dots.media.enable {
    environment.systemPackages = with pkgs; [
      gdk-pixbuf
    ];

    # 'gdk-pixbuf-thumbnailer.thumbnailer' is created in '/run/current-system/sw/share/thumbnailers'
  };
}
