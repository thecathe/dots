{ pkgs, ... }:

## https://wiki.nixos.org/wiki/Thumbnails#Enable_Image_Thumbnails
{
  environment.systemPackages = with pkgs; [
    gdk-pixbuf
  ];

  # 'gdk-pixbuf-thumbnailer.thumbnailer' is created in '/run/current-system/sw/share/thumbnailers'
}
