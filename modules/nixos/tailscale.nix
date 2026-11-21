# Tailscale: this machine joins your tailnet, which is what lets it open the
# private sites (served by the webserver repo's droplet only to the tailnet
# owner). Join once per machine:
#
#   tailscale up   # then open the link and log in
#
# The dots user is the operator (set below on every start), so `tailscale`
# needs no sudo: `tailscale up` / `tailscale down`, or the DMS services menu.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.tailscale.enable = lib.mkEnableOption "Tailscale, with the per-user tools" // {default = true;};

  config = lib.mkIf config.dots.tailscale.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true; # the direct-connection UDP port, so peers needn't relay
      extraSetFlags = ["--operator=${config.dots.user.name}"];
    };

    dots.services.tailscale = let
      tailscale = "${config.services.tailscale.package}/bin/tailscale";
    in {
      label = "Tailscale";
      icon = "vpn_lock";
      up = [tailscale "up"];
      down = [tailscale "down"];
      status = [
        "${pkgs.writeShellScript "tailscale-is-up" ''
          ${tailscale} status --json 2>/dev/null | ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' >/dev/null
        ''}"
      ];
    };
  };
}
