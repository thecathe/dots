{ pkgs, inputs, ... }:

# let
#   ## https://github.com/fufexan/nix-gaming#nix-stable
#   nix-gaming = import (
#     builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz"
#   );
# in
{
  nix.settings = {
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };
  imports = with inputs.nix-gaming.nixosModules; [
    wine
    pipewireLowLatency
    platformOptimizations
  ];
  environment.systemPackages =
    with pkgs;
    # with nix-gaming.packages.${pkgs.stdenv.hostPlatform.system};
    with inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system};
    [
      wine
      mo2installer
      mangohud
      protonup-ng
    ];
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/cathe/.steam/root/compatibilitytools.d";
  };
  # https://mynixos.com/options/programs.steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    platformOptimizations.enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  programs.gamemode.enable = true;
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
