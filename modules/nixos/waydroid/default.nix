{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.waydroid.enable = lib.mkEnableOption "Waydroid, Android in a container (started by hand)";

  config = lib.mkIf config.dots.waydroid.enable {
    virtualisation.waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };
    environment.systemPackages = with pkgs; [wl-clipboard waydroid-helper];
    systemd.services.waydroid-container = {
      wantedBy = lib.mkForce [];
      serviceConfig.ExecStopPost = lib.mkForce "";
    };
  };
}
