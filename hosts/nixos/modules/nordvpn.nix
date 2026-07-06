{pkgs, ...}: {
  networking = {
    firewall.checkReversePath = false;
    wg-quick.interfaces.nordlynx = {
      autostart = false;
      address = ["10.5.0.2/32"];
      dns = ["103.86.96.100" "103.86.99.100"];
      privateKeyFile = "/etc/nordvpn/nordlynx.key";

      peers = [
        {
          publicKey = "qIhtTW9K4iXWFo5Q4dOPdXg8/xubXr9yEGoN55D8xnA=";
          allowedIPs = ["0.0.0.0/0" "::/0"];
          endpoint = "ca1697.nordvpn.com:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  environment.systemPackages = with pkgs; [wireguard-tools];
}
