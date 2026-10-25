{...}: {
  imports = [
    ../shared/identity.nix
    ../shared/services.nix
    ./services.nix
    ./media
    ./torrent
    ./waydroid
    ./git.nix
    ./zsh.nix
    ./direnv.nix
    ./fonts.nix
    ./firefox.nix
    ./nautilus.nix
    ./docker.nix
    ./nix-ld.nix
    ./vscode.nix
    ./claude.nix
    ./network-sharing.nix
    ./tailscale.nix
    ./stylix.nix
    ./niri.nix
  ];
}
