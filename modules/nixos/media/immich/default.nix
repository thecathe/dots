{pkgs, ...}:
## https://wiki.nixos.org/wiki/Immich
{
  environment.systemPackages = with pkgs; [
    immich ## self-hosted image/video management
    immich-cli ## cli
    ##    immich-go ## useful for go-import
  ];
}
