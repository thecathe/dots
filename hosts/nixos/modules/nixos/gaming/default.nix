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
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
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
      lutris
      wineWow64Packages.staging
      winetricks
      vulkan-tools
      protonup-qt
      protontricks
    ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/cathe/.steam/root/compatibilitytools.d";
    STEAM_FORCE_DESKTOPUI_SCALING = "1";
    STEAM_FORCE_PIPEWIRE_CAPTURE = "1";
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };
  # https://mynixos.com/options/programs.steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    platformOptimizations.enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
    protontricks.enable = true;
  };
  home-manager.users.cathe = {
    xdg.desktopEntries = {
      steam = {
        name = "Steam";
        exec = "steam -pipewire %U";
        icon = "steam";
        terminal = false;
        categories = [
          "Network"
          "FileTransfer"
          "Game"
        ];
        mimeType = [
          "x-scheme-handler/steam"
          "x-scheme-handler/steamlink"
        ];
      };

      # Hearthstone Deck Tracker's overlay positions itself relative to
      # Hearthstone using absolute X11 coordinates, which niri's Xwayland
      # integration doesn't support (X11 apps can't position themselves at
      # will under it). Running both inside a plain nested rootful Xwayland
      # session gives them a real shared X11 desktop, so HDT's overlay works
      # exactly like it would under a normal X11 window manager.
      hearthstone-with-tracker = {
        name = "Hearthstone (with Deck Tracker)";
        exec = "hearthstone-with-tracker";
        icon = "lutris_hearthstone";
        terminal = false;
        categories = [ "Game" ];
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "hearthstone-with-tracker" ''
        set -u

        # NOTE: if a previous attempt crashed and left an orphaned HDT
        # process behind, it can trip HDT's own single-instance check on the
        # next launch. Deliberately not auto-killing anything by name-match
        # here to clean that up - pattern-matching pkill against wine/proton
        # process command lines proved unpredictable and killed unrelated
        # things during testing. Close it manually if this happens.

        # Generate standalone launch scripts (full env baked in - WINEPREFIX,
        # DXVK, etc.) via Lutris's --output-script mode instead of using
        # `lutris lutris:rungameid/N` directly. The latter goes through
        # Lutris's single-instance GApplication daemon: if one game is
        # already being monitored, a second launch request silently queues
        # behind it instead of starting, and any DISPLAY we set is ignored
        # when the request gets relayed to an already-running daemon rather
        # than starting fresh. --output-script exits immediately after
        # writing the script - no daemon stays resident - so running both
        # scripts directly as independent processes avoids all of that.
        # 57/59 are Lutris's own DB-assigned game IDs for this install (see
        # ~/.local/share/lutris/games/{hearthstone,hdt}-*.yml) - not
        # portable across a fresh Lutris database.
        # Generated under $HOME rather than /tmp: steam-run's bubblewrap
        # sandbox (needed below) gives itself a fresh, empty private /tmp
        # instead of bind-mounting the host's, so anything written under
        # /tmp is invisible inside it - $HOME is bind-mounted through.
        mkdir -p "$HOME/.cache"
        scriptdir=$(mktemp -d -p "$HOME/.cache")
        (cd "$scriptdir" && lutris --output-script=57 >/dev/null 2>&1)
        (cd "$scriptdir" && lutris --output-script=59 >/dev/null 2>&1)

        # The generated scripts run umu-run (a python3 script) which in turn
        # runs steamrt4/pressure-vessel/GE-Proton - plain, non-NixOS
        # dynamically-linked binaries that need a real FHS environment to
        # run at all. Lutris's own daemon normally runs games inside a
        # bubblewrap FHS sandbox that provides both python3 and that FHS
        # environment, but these scripts run outside that sandbox, so both
        # need to be supplied explicitly: python3 on PATH, and steam-run to
        # wrap execution in an FHS sandbox.
        export PATH="${pkgs.python3}/bin:$PATH"
        steam_run="${pkgs.steam-run}/bin/steam-run"

        display_num=2
        while [ -e "/tmp/.X11-unix/X$display_num" ]; do
          display_num=$((display_num + 1))
        done

        ${pkgs.xwayland}/bin/Xwayland ":$display_num" -geometry 1920x1080 &
        xwayland_pid=$!

        sleep 2
        DISPLAY=":$display_num" "$steam_run" bash "$scriptdir/hearthstone.sh" &

        # Battle.net's main launcher window relies on a window manager to
        # service its "minimize" request once the game launches, and we
        # deliberately run without one here (needed so HDT's overlay can
        # position itself with absolute coordinates - a WM would risk
        # decorating/repositioning things and breaking that). Poll for and
        # unmap it directly via X11 instead. Matched by exact title only
        # ("^Battle\.net$") - Battle.net also opens windows titled e.g.
        # "Battle.net Login" or "Battle.net Error" that must stay visible
        # (a broader "contains Battle.net" match previously hid the login
        # prompt itself, silently stalling the whole launch on a reboot
        # where re-authentication was needed).
        (
          for _ in $(seq 1 40); do
            for win in $(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name '^Battle\.net$' 2>/dev/null); do
              DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowunmap "$win" 2>/dev/null
            done
            sleep 2
          done
        ) &

        sleep 5
        DISPLAY=":$display_num" "$steam_run" bash "$scriptdir/hdt.sh" &

        wait "$xwayland_pid"
        rm -rf "$scriptdir"
      '')
    ];
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
