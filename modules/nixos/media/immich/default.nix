## https://wiki.nixos.org/wiki/Immich
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.immich;
in {
  options.dots.immich = {
    enable = lib.mkEnableOption "Immich, self-hosted photo and video management";
    mediaLocation = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/immich";
      example = "/mnt/data/Multimedia/immich";
      description = "Where Immich keeps the photos and videos it manages.";
    };
  };

  config = lib.mkIf cfg.enable {
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
      inherit (cfg) mediaLocation;
      accelerationDevices = null;
    };
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaLocation} 0750 immich immich -"
    ];

    users.users.immich.extraGroups = ["video" "render"];
  };
}
