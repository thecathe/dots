{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./gaming
    ./nordvpn.nix
  ];
}
