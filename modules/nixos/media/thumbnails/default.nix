{...}: {
  imports = [
    ./image.nix
    ./raw.nix
    ./video.nix
  ];

  # The thumbnailers above install their .thumbnailer files under
  # share/thumbnailers, which the system profile links only when asked to.
  # https://wiki.nixos.org/wiki/Thumbnails
  environment.pathsToLink = ["share/thumbnailers"];
}
