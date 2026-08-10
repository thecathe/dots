{pkgs, ...}:
## https://wiki.nixos.org/wiki/Immich
{
  environment.systemPackages = with pkgs; [
    immich ## self-hosted image/video management
    immich-cli ## cli
    ##    immich-go ## useful for go-import
  ];

  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
    environment.IMMICH_LOG_LEVEL = "warn";
    mediaLocation = "/home/cathe/Pictures/immich";
    accelerationDevices = null;
  };

  users.users.immich.extraGroups = ["video" "render"];
}
