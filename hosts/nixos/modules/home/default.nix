{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./gnome-extensions.nix
    ./monitor.nix
  ];
}
