{
  config,
  lib,
  pkgs,
  ...
}:
## https://wiki.nixos.org/wiki/Thumbnails#Enable_Video_Thumbnails
{
  config = lib.mkIf config.dots.media.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg-headless
      ffmpegthumbnailer
    ];

    # 'ffmpegthumbnailer.thumbnailer' is created in '/run/current-system/sw/share/thumbnailers'
  };
}
