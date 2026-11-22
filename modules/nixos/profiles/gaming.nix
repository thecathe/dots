# The `gaming` profile: Steam (with gamescope, Proton-GE and protontricks), SteamOS's
# sysctls, gamemode, the Wine and Proton tools, Lutris, MangoHud and the nix-gaming
# binary cache. Steam's dedicated-server port opens only while hosting
# (`steam-server up|down`, or the DMS services menu). Its home half is the home
# `gaming` profile: the Steam launcher entry, where GPU-specific variables go.
#
# Not here, being separate choices a gaming machine may or may not make: the kernel
# (`boot.kernelPackages`), PipeWire's latency, and the GPU driver.
{
  config,
  lib,
  pkgs,
  dotsInputs,
  ...
}: let
  inherit (lib) mkDefault;
  user = config.dots.user.name;
  nixGamingPkgs = dotsInputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system};

  # Lutris without gnome-desktop. nixpkgs puts gnome-desktop's GnomeDesktop-3.0
  # typelib on Lutris's GI path, and Lutris's display code (lutris/util/display.py)
  # calls `GnomeDesktop.RRScreen` from it at import. gnome-desktop 51 no longer has
  # `RRScreen`, so from the nixpkgs bump of 2026-11-12 every `lutris` command died
  # with an AttributeError. With no typelib Lutris falls back to its xrandr display
  # manager, which is the one it uses on niri anyway. This is the only place Lutris
  # uses GnomeDesktop. Drop the override once nixpkgs' Lutris copes with
  # gnome-desktop 51.
  lutris = pkgs.lutris.override {
    lutris-unwrapped = pkgs.lutris-unwrapped.overrideAttrs (old: {
      buildInputs = lib.remove pkgs.gnome-desktop old.buildInputs;
    });
  };

  # Steam's dedicated server port (27015, what programs.steam's
  # dedicatedServer.openFirewall would open for good), opened only while the unit
  # is up. A firewall reload or restart rebuilds the nixos-fw chain, so the rules
  # are added again then (ReloadPropagatedFrom, partOf).
  rules = action: ''
    for ipt in iptables ip6tables; do
      for proto in tcp udp; do
        while $ipt -D nixos-fw -p $proto --dport 27015 -j nixos-fw-accept 2>/dev/null; do :; done
        ${
      if action == "open"
      then "$ipt -I nixos-fw -p $proto --dport 27015 -j nixos-fw-accept"
      else ":"
    }
      done
    done
  '';
in {
  options.dots.profile.gaming.enable = lib.mkEnableOption "the gaming profile: Steam, gamemode, the Wine and Proton tools, Lutris and the nix-gaming cache";

  config = lib.mkIf config.dots.profile.gaming.enable {
    nix.settings = {
      substituters = ["https://nix-gaming.cachix.org"];
      trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
    };

    environment.systemPackages =
      # Only mo2installer (Mod Organizer 2) comes from nix-gaming; the rest are nixpkgs'.
      (with pkgs; [sdl3.lib wine])
      ++ [nixGamingPkgs.mo2installer]
      ++ (with pkgs; [
        mangohud
        protonup-ng
        lutris
        wineWow64Packages.staging
        winetricks
        vulkan-tools
        protonup-qt
        protontricks
      ]);

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = mkDefault "${config.users.users.${user}.home}/.steam/root/compatibilitytools.d";
      STEAM_FORCE_DESKTOPUI_SCALING = mkDefault "1";
      STEAM_FORCE_PIPEWIRE_CAPTURE = mkDefault "1";
      __EGL_VENDOR_LIBRARY_DIRS = mkDefault "/run/opengl-driver/share/glvnd/egl_vendor.d";
    };

    # https://mynixos.com/options/programs.steam
    programs.steam = {
      enable = mkDefault true;
      remotePlay.openFirewall = mkDefault true;
      # Opened only while hosting: see steam-server-ports below.
      dedicatedServer.openFirewall = mkDefault false;
      platformOptimizations.enable = mkDefault true;
      gamescopeSession.enable = mkDefault true;
      extraCompatPackages = [pkgs.proton-ge-bin];
      protontricks.enable = mkDefault true;
    };

    programs.gamemode.enable = mkDefault true;

    systemd.services.steam-server-ports = {
      description = "Steam dedicated server port (27015), open while hosting";
      after = ["firewall.service"];
      partOf = ["firewall.service"];
      unitConfig.ReloadPropagatedFrom = "firewall.service";
      path = [config.networking.firewall.package];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = rules "open";
      reload = rules "open";
      preStop = rules "close";
    };
    dots.services.steam-server = {
      label = "Steam server ports";
      icon = "router";
      unit = "steam-server-ports.service";
      command = "steam-server";
    };
  };
}
