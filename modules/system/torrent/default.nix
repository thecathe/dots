{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qbittorrent
    tor-browser
  ];
}
