{pkgs, ...}: {
  networking = {
    networkmanager.unmanaged = ["interface-name:nordlynx"];
    # firewall.checkReversePath = false;
    wg-quick.interfaces.nordlynx = {
      autostart = false;
      address = ["10.5.0.2/32"];
      dns = ["103.86.96.100" "103.86.99.100"];
      privateKeyFile = "/etc/nordvpn/nordlynx.key";

      peers = [
        {
          publicKey = "8pRFH/FfMBs3eBJCM2ABFoOs/13n78LYQvoovZVLdgI=";
          allowedIPs = ["0.0.0.0/0" "::/0"];
          endpoint = "us2944.nordvpn.com:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  environment.systemPackages = with pkgs; [wireguard-tools];
}
