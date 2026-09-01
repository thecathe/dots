{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./xmodmap
    ./wm/niri.nix
    ./home
    # ./shell-overrides
  ];
}
