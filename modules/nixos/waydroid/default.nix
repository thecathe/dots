{
  pkgs,
  lib,
  ...
}: {
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
  environment.systemPackages = with pkgs; [wl-clipboard];
  systemd.services.waydroid-container = {
    wantedBy = lib.mkForce [];
    serviceConfig.ExecStopPost = lib.mkForce "";
  };
}
