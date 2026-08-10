{ pkgs, ... }:

## https://wiki.nixos.org/wiki/Thumbnails#Enable_Video_Thumbnails
{
  environment.systemPackages = with pkgs; [
    ffmpeg-headless
    ffmpegthumbnailer
  ];

  # 'ffmpegthumbnailer.thumbnailer' is created in '/run/current-system/sw/share/thumbnailers'
}
