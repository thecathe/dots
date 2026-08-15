{pkgs, ...}:
## https://wiki.nixos.org/wiki/Immich
{
  environment.systemPackages = with pkgs; [
    immich ## self-hosted image/video management
    immich-cli ## cli
    ##    immich-go ## useful for go-import
  ];

  # starts on: http://localhost:2283/
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
    environment.IMMICH_LOG_LEVEL = "warn";
    mediaLocation = "/mnt/data/Multimedia/immich";
    accelerationDevices = null;
  };
  systemd.tmpfiles.rules = [
    "d /mnt/data/Multimedia/immich 0750 immich immich -"
  ];

  users.users.immich.extraGroups = ["video" "render"];
}
