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
        # GBM_BACKEND/NVD_BACKEND/__GLX_VENDOR_LIBRARY_NAME/LIBVA_DRIVER_NAME
        # scoped here (rather than global sessionVariables) so they only
        # force nvidia's GBM/VA-API path for Steam/gamescope, not niri
        # itself and every other app in the session.
        exec = "env GBM_BACKEND=nvidia-drm __GLX_VENDOR_LIBRARY_NAME=nvidia LIBVA_DRIVER_NAME=nvidia NVD_BACKEND=direct steam -pipewire %U";
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
      # will under it). Running it inside a plain nested rootful Xwayland
      # session gives it a real X11 desktop, so HDT's overlay works exactly
      # like it would under a normal X11 window manager. This only launches
      # HDT itself - use its own "Start Hearthstone" button to launch the
      # game from inside it (see hearthstone-with-tracker's own comments for
      # why launching both independently doesn't work as well).
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

        # Only HDT gets launched here - use its own "Start Hearthstone"
        # button once it's up to launch the game. Earlier versions of this
        # script also launched Hearthstone independently (in its own
        # separate steam-run sandbox) and tried to time HDT's launch off of
        # polling for Hearthstone's X11 window, but that had two real
        # problems in practice: (1) launching Hearthstone from a second,
        # separate sandbox meant it and HDT's own Battle.net-launch attempt
        # ran in different, unshared /tmp namespaces, so Battle.net's
        # cross-process single-instance IPC detection couldn't see across
        # them and both came up as independent "server" sessions - the
        # double-Battle.net/double-login bug; and (2) HDT does a one-time
        # check for Hearthstone's window early in its own startup and
        # doesn't retry if it's not found yet, and no amount of external
        # window-title polling (even debounced against transient decoy
        # windows) matched HDT's own launch-then-attach logic for
        # reliability - the overlay kept failing to attach. Letting HDT
        # launch Hearthstone itself (as its own child, inside its own
        # already-running sandbox) sidesteps both: there's only one launch
        # path so only one Battle.net, and HDT knows exactly when its own
        # child process is ready without guessing from outside.

        # Generate a standalone launch script (full env baked in -
        # WINEPREFIX, DXVK, etc.) via Lutris's --output-script mode instead
        # of using `lutris lutris:rungameid/N` directly. The latter goes
        # through Lutris's single-instance GApplication daemon, which can
        # silently queue or misbehave; --output-script exits immediately
        # after writing the script - no daemon stays resident. 59 is
        # Lutris's own DB-assigned game ID for this install (see
        # ~/.local/share/lutris/games/hdt-*.yml) - not portable across a
        # fresh Lutris database.
        # Generated under $HOME rather than /tmp: steam-run's bubblewrap
        # sandbox (needed below) gives itself a fresh, empty private /tmp
        # instead of bind-mounting the host's, so anything written under
        # /tmp is invisible inside it - $HOME is bind-mounted through.
        mkdir -p "$HOME/.cache"
        scriptdir=$(mktemp -d -p "$HOME/.cache")
        (cd "$scriptdir" && lutris --output-script=59 >/dev/null 2>&1)

        # The generated script runs umu-run (a python3 script) which in turn
        # runs steamrt4/pressure-vessel/GE-Proton - plain, non-NixOS
        # dynamically-linked binaries that need a real FHS environment to
        # run at all. Lutris's own daemon normally runs games inside a
        # bubblewrap FHS sandbox that provides both python3 and that FHS
        # environment, but this script runs outside that sandbox, so both
        # need to be supplied explicitly: python3 on PATH, and steam-run to
        # wrap execution in an FHS sandbox. Hearthstone, launched by HDT
        # itself via its "Start Hearthstone" button, inherits this same
        # sandbox automatically as HDT's own child process.
        export PATH="${pkgs.python3}/bin:$PATH"
        steam_run="${pkgs.steam-run}/bin/steam-run"

        display_num=2
        while [ -e "/tmp/.X11-unix/X$display_num" ]; do
          display_num=$((display_num + 1))
        done

        # Latch: lets hearthstone-focus-window/-session/-restart-tracker
        # (bound to niri keys) know a session is active and which display to
        # target, and no-op harmlessly if none is running. Removed on any
        # exit path, not just the clean one.
        latch="$XDG_RUNTIME_DIR/hearthstone-with-tracker.display"
        echo "$display_num" > "$latch"
        trap 'rm -f "$latch"' EXIT

        ${pkgs.xwayland}/bin/Xwayland ":$display_num" -geometry 1920x1080 &
        xwayland_pid=$!

        sleep 3
        DISPLAY=":$display_num" "$steam_run" bash "$scriptdir/hdt.sh" &

        # Nothing automatically receives X11 input focus without a window
        # manager to hand it over - it just stays on the root window
        # (nowhere) until something explicitly claims it (confirmed live:
        # `xdotool getwindowfocus` returned the root window id after HDT had
        # been up for minutes). HDT's own UI appears to depend on actually
        # receiving that focus/activation to consider itself active - without
        # it, it's visually present but doesn't respond to clicks at all.
        # Wait for its window and focus it proactively so it's usable
        # immediately instead of requiring Ctrl+Alt+T first.
        (
          for _ in $(seq 1 30); do
            win=$(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name '^Hearthstone Deck Tracker$' 2>/dev/null | head -1)
            if [ -n "$win" ]; then
              DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowfocus "$win" 2>/dev/null
              break
            fi
            sleep 1
          done
        ) &

        # Same reasoning, for whenever Hearthstone itself gets launched (via
        # HDT's "Start Hearthstone" button, at a time this script doesn't
        # control): focus it once, the first time its window appears, so it
        # picks up keyboard/mouse input without needing Ctrl+Alt+H first.
        # Not raising it (see hearthstone-focus-window) - would cover HDT's
        # overlay, since there's no window manager to keep it on top.
        (
          focused=0
          while kill -0 "$xwayland_pid" 2>/dev/null; do
            if [ "$focused" = 0 ]; then
              win=$(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name '^Hearthstone$' 2>/dev/null | head -1)
              if [ -n "$win" ]; then
                DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowfocus "$win" 2>/dev/null
                focused=1
              fi
            fi
            sleep 2
          done
        ) &

        # Battle.net's main launcher window relies on a window manager to
        # service its "minimize" request once the game launches, and we
        # deliberately run without one here (needed so HDT's overlay can
        # position itself with absolute coordinates - a WM would risk
        # decorating/repositioning things and breaking that). Poll for and
        # lower it directly via X11 instead (XLowerWindow, not unmap -
        # unmapping is permanent since nothing ever remaps it, which
        # previously stranded a launch when Battle.net needed an interactive
        # click and got hidden mid-flow before that could happen; lowering
        # only changes stacking order, so it's still fully visible/clickable
        # if raised again, e.g. via the Ctrl+Alt+B keybind below). Matched
        # by exact title only ("^Battle\.net$") - Battle.net also opens
        # windows titled e.g. "Battle.net Login" or "Battle.net Error" that
        # must stay in front (a broader "contains Battle.net" match
        # previously hid the login prompt itself, silently stalling the
        # whole launch on a reboot where re-authentication was needed).
        # Runs for the whole session (not a fixed window after startup)
        # since Hearthstone now only launches whenever the user clicks
        # HDT's "Start Hearthstone" button, which could be any time.
        (
          while kill -0 "$xwayland_pid" 2>/dev/null; do
            for win in $(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name '^Battle\.net$' 2>/dev/null); do
              DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowlower "$win" 2>/dev/null
            done
            sleep 2
          done
        ) &

        wait "$xwayland_pid"

        # Xwayland exiting - including via plain Mod+Q/close-window, which
        # was confirmed to genuinely terminate it, so this covers the
        # reflexive case too - doesn't reliably take its clients down with
        # it: wine/proton processes can survive with a dead X11 connection
        # instead of exiting cleanly, becoming orphaned zombies that pile up
        # across sessions and compete for resources with the next one (this
        # happened in practice - two stale sessions' worth, one at 122% CPU,
        # found and killed by hand). Precisely find (via each process's own
        # environment, not fragile text matching) and kill anything still
        # tied to this session's display, escalating to SIGKILL after a
        # grace period for anything that ignores the first signal.
        kill_session_processes() {
          sig="$1"
          for proc in /proc/[0-9]*; do
            pid="''${proc#/proc/}"
            if tr '\0' '\n' < "$proc/environ" 2>/dev/null | grep -qx "DISPLAY=:$display_num"; then
              kill "-$sig" "$pid" 2>/dev/null
            fi
          done
        }
        kill_session_processes TERM
        sleep 2
        kill_session_processes KILL

        rm -rf "$scriptdir"
      '')

      (pkgs.writeShellScriptBin "hearthstone-focus-window" ''
        set -u
        latch="$XDG_RUNTIME_DIR/hearthstone-with-tracker.display"
        [ -f "$latch" ] || exit 0
        display_num=$(cat "$latch")

        case "''${1:-}" in
          hearthstone) title='^Hearthstone$' ;;
          battlenet)   title='^Battle\.net$' ;;
          hdt)         title='^Hearthstone Deck Tracker$' ;;
          *) exit 1 ;;
        esac

        win=$(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name "$title" 2>/dev/null | head -1)
        [ -n "$win" ] || exit 0
        # windowactivate relies on a window manager to service the
        # _NET_ACTIVE_WINDOW EWMH request, which we don't run (see
        # hearthstone-with-tracker) - windowraise/windowfocus are direct X11
        # protocol requests (XRaiseWindow/XSetInputFocus) that work without
        # one, same principle as the Battle.net auto-hide poller above.
        # windowfocus (XSetInputFocus) fails with a BadMatch X error on a
        # window that isn't currently mapped/viewable, so map defensively
        # first - a no-op if it's already visible, but means this can't
        # silently fail the way it did when the Battle.net poller still
        # used windowunmap instead of windowlower.
        DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowmap "$win" 2>/dev/null
        # Not raising for "hearthstone": Hearthstone is the base/background
        # layer under HDT's overlay, and raising it would put it above the
        # overlay in stacking order - there's no window manager to enforce
        # "always on top" as a persistent property, so this would hide the
        # overlay until HDT next reasserts itself. Input focus and stacking
        # order are independent in X11, so focusing without raising still
        # directs keyboard/mouse input to Hearthstone while leaving the
        # overlay visually on top.
        if [ "$1" = "hearthstone" ]; then
          # HDT's main window (title "Hearthstone Deck Tracker") is a
          # separate, regular window from its overlay (title
          # "HearthstoneOverlay", confirmed distinct via live xdotool
          # inspection) - raising it (e.g. via Ctrl+Alt+T) can leave it
          # stuck on top of Hearthstone indefinitely, since nothing here
          # raises Hearthstone above it and a plain click doesn't restack
          # without a window manager. Lower it specifically when switching
          # back to Hearthstone - this never touches the overlay, which has
          # a different title and is left alone.
          hdt_main=$(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name '^Hearthstone Deck Tracker$' 2>/dev/null | head -1)
          [ -n "$hdt_main" ] && DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowlower "$hdt_main" 2>/dev/null
        else
          DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowraise "$win"
        fi
        DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowfocus "$win"
      '')

      (pkgs.writeShellScriptBin "hearthstone-focus-session" ''
        set -u
        latch="$XDG_RUNTIME_DIR/hearthstone-with-tracker.display"
        [ -f "$latch" ] || exit 0

        id=$(niri msg windows | awk '
          /^Window ID/ { id=$3; gsub(":","",id) }
          /App ID: "org\.freedesktop\.Xwayland"/ { print id; exit }
        ')
        [ -n "$id" ] || exit 0
        niri msg action focus-window --id "$id"
      '')

      (pkgs.writeShellScriptBin "hdt-update" ''
        set -u

        # HDT ships via Squirrel.Windows: HearthSim/HDT-Releases publishes a
        # *-full.nupkg per version (a complete standalone build - a .nupkg is
        # just a zip, payload under lib/<tfm>/) alongside *-delta.nupkg files
        # (bsdiff patches relative to one specific prior version, requiring
        # Squirrel's own patch-apply engine and an unbroken version chain).
        # The flat install below is missing the Update.exe/packages-cache
        # scaffolding Squirrel needs to self-update, hence "reinstall to
        # update" - grabbing the full package for the target version and
        # overlaying it is equivalent to a fresh install regardless of what
        # version is currently on disk, so there's no need to ever touch a
        # delta or walk through intermediate versions.
        install_dir="$HOME/Games/battlenet/drive_c/Hearthstone Deck Tracker"
        repo="HearthSim/HDT-Releases"
        version="''${1:-}"

        mkdir -p "$HOME/.cache"
        work=$(mktemp -d -p "$HOME/.cache")
        trap 'rm -rf "$work"' EXIT

        if [ -z "$version" ]; then
          version=$(${pkgs.curl}/bin/curl -sL "https://api.github.com/repos/$repo/releases/latest" \
            | ${pkgs.gnugrep}/bin/grep -oP '"tag_name":\s*"v\K[0-9.]+')
        fi
        [ -n "$version" ] || { echo "Couldn't resolve a version to install" >&2; exit 1; }

        base="https://github.com/$repo/releases/download/v$version"
        pkg="HearthstoneDeckTracker-$version-full.nupkg"

        echo "Fetching $pkg ..."
        ${pkgs.curl}/bin/curl -sL -o "$work/RELEASES" "$base/RELEASES"
        ${pkgs.curl}/bin/curl -sL -o "$work/$pkg" "$base/$pkg"

        # Verify against HearthSim's own manifest before touching the live
        # install - cheap insurance against a truncated download or a bad
        # version string silently 404-ing into an HTML error page.
        expected=$(${pkgs.gnugrep}/bin/grep " $pkg " "$work/RELEASES" | ${pkgs.gawk}/bin/awk '{print toupper($1)}')
        actual=$(${pkgs.coreutils}/bin/sha1sum "$work/$pkg" | ${pkgs.gawk}/bin/awk '{print toupper($1)}')
        if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
          echo "SHA1 mismatch for $pkg (expected [$expected], got [$actual]) - aborting" >&2
          exit 1
        fi

        ${pkgs.unzip}/bin/unzip -q "$work/$pkg" -d "$work/extracted"

        # Overlay rather than wipe: Plugins/, GLCache/ and HDTUninstaller.exe
        # aren't part of the Squirrel package and must survive the update.
        src=("$work"/extracted/lib/*/)
        cp -a "''${src[0]}." "$install_dir/"
        mv -f "$install_dir/HearthstoneDeckTracker.exe" "$install_dir/Hearthstone Deck Tracker.exe"
        mv -f "$install_dir/HearthstoneDeckTracker.exe.config" "$install_dir/Hearthstone Deck Tracker.exe.config"

        echo "Hearthstone Deck Tracker updated to $version."
      '')

      (pkgs.writeShellScriptBin "hearthstone-restart-tracker" ''
        set -u
        latch="$XDG_RUNTIME_DIR/hearthstone-with-tracker.display"
        [ -f "$latch" ] || exit 0
        display_num=$(cat "$latch")

        # Two patterns, both far too specific to collide with anything
        # unrelated (unlike the broad patterns that caused real problems
        # earlier in this project): the launch chain shows a Linux absolute
        # path (umu-run, umu.exe, and everything in between) right up until
        # the real exe takes over and self-reports a Windows-style path
        # instead (how wine represents its own argv). Matching only the
        # final form (as before) misses anything still stuck mid-bootstrap
        # from a previous attempt that never made it that far - confirmed in
        # practice: a stuck bootstrap-stage chain from an earlier restart
        # survived indefinitely because this didn't catch it, while new
        # restart attempts kept piling up alongside it. Note: since
        # Hearthstone now launches as HDT's own child (via its "Start
        # Hearthstone" button, see hearthstone-with-tracker), killing HDT
        # here may or may not take Hearthstone down with it depending on how
        # HDT spawns it - if Hearthstone survives as an orphan, the fresh
        # HDT instance this starts won't automatically reattach to it; use
        # "Start Hearthstone" again from inside it if so.
        pkill -f "$HOME/Games/battlenet/drive_c/Hearthstone Deck Tracker/Hearthstone Deck Tracker\.exe" 2>/dev/null
        pkill -f '^C:.Hearthstone Deck Tracker.Hearthstone Deck Tracker\.exe$' 2>/dev/null

        mkdir -p "$HOME/.cache"
        scriptdir=$(mktemp -d -p "$HOME/.cache")
        (cd "$scriptdir" && lutris --output-script=59 >/dev/null 2>&1)

        export PATH="${pkgs.python3}/bin:$PATH"
        DISPLAY=":$display_num" ${pkgs.steam-run}/bin/steam-run bash "$scriptdir/hdt.sh" &

        # Proactively focus it once up, same reasoning as
        # hearthstone-with-tracker - nothing gets X11 input focus
        # automatically without a window manager to hand it over.
        (
          for _ in $(seq 1 30); do
            win=$(DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool search --name '^Hearthstone Deck Tracker$' 2>/dev/null | head -1)
            if [ -n "$win" ]; then
              DISPLAY=":$display_num" ${pkgs.xdotool}/bin/xdotool windowfocus "$win" 2>/dev/null
              break
            fi
            sleep 1
          done
        ) &
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
      # raised from 64: a ~1.3ms buffer forced on the whole pipewire graph
      # at all times (not just while gaming) was a likely cause of
      # audio xruns/distortion under normal desktop load.
      quantum = 1024;
      rate = 48000;
    };
  };

  # make pipewire realtime-capable
  security.rtkit.enable = true;
}
