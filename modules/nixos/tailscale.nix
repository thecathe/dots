# Tailscale: this machine joins your tailnet, which is what lets it open the
# private sites (served by the webserver repo's droplet only to the tailnet
# owner). Join once per machine:
#
#   sudo tailscale up --operator=$USER   # then open the link and log in
#
# --operator lets you run `tailscale` afterwards without sudo.
{...}: {
  services.tailscale = {
    enable = true;
    openFirewall = true; # the direct-connection UDP port, so peers needn't relay
  };
}
