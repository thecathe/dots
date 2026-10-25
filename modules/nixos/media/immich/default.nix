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
    # Up only when wanted: nothing starts at boot. `immich up` / `immich down`
    # (or the DMS services menu) start and stop immich.target, which takes the
    # server, machine learning and its redis with it. Any other `immich`
    # arguments go to immich-cli. Postgres, which Immich shares with anything
    # else that wants it, is left running.
    dots.services.immich = {
      label = "Immich";
      icon = "photo_library";
      unit = "immich.target";
      status = ["${pkgs.systemd}/bin/systemctl" "is-active" "--quiet" "immich-server.service"];
      command = "immich";
      fallback = "${pkgs.immich-cli}/bin/immich";
    };
    systemd.targets.immich = {
      description = "Immich, started by hand (immich up)";
      wants = ["immich-server.service" "immich-machine-learning.service" "redis-immich.service"];
    };
    systemd.services = lib.genAttrs ["immich-server" "immich-machine-learning" "redis-immich"] (_: {
      wantedBy = lib.mkForce [];
      partOf = ["immich.target"];
    });

    # Served on this machine only: http://localhost:2283/
    services.immich = {
      enable = true;
      port = 2283;
      host = "localhost";
      openFirewall = false;
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
