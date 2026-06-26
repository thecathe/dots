{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./thumbnails
    ./torrent
    ./waydroid
    ./git.nix
    ./zsh.nix
    ./direnv.nix
    ./fonts.nix
    ./firefox.nix
    ./nautilus.nix
    ./docker.nix
    ./network-sharing.nix
  ];
}
