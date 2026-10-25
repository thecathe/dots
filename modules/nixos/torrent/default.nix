{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.torrent.enable = lib.mkEnableOption "qBittorrent and Tor Browser";

  config = lib.mkIf config.dots.torrent.enable {
    environment.systemPackages = with pkgs; [
      qbittorrent
      tor-browser
    ];
  };
}
