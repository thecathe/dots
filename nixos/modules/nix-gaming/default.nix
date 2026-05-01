{ pkgs, ... }:

let
  ## https://github.com/fufexan/nix-gaming#nix-stable
  nix-gaming = import (
    builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz"
  );
in
{
  nix.settings = {
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };
  imports = [
    nix-gaming.nixosModules.wine
    nix-gaming.nixosModules.pipewireLowLatency
    nix-gaming.nixosModules.platformOptimizations
  ];
  environment.systemPackages =
    with pkgs;
    with nix-gaming.packages.${pkgs.stdenv.hostPlatform.system};
    [
      wine
      mo2installer
    ];
  # https://mynixos.com/options/programs.steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    platformOptimizations.enable = true;
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    lowLatency = {
      # enable this module
      enable = true;
      # defaults (no need to be set unless modified)
      quantum = 64;
      rate = 48000;
    };
  };

  # make pipewire realtime-capable
  security.rtkit.enable = true;
}
