{
  config,
  lib,
  pkgs,
  ...
}: let
  # gsr-ui-cli sends a command to the running gsr-ui over a socket in
  # $XDG_RUNTIME_DIR (and fails with "failed to connect" when none runs). It
  # comes in the same package as gsr-ui, hence the same system profile path.
  cli = "/run/current-system/sw/bin/gsr-ui-cli";

  # Whether a recording is going: some process of the gsr-ui unit (it starts
  # gpu-screen-recorder for each capture) holds a file named Video_* open. The
  # UI names a plain recording that way, and so does gpu-screen-recorder one
  # started inside a replay or stream session (src/recorder/recorder.c), which
  # leaves no sign in the process arguments. Replay buffers and saves are named
  # Replay_*, screenshots Screenshot_*. The unit's cgroup is read directly: its
  # processes are not all children of gsr-ui. The unit is the first argument,
  # gsr-ui.service unless given (so a copy under another name can be tested).
  recordingScript = pkgs.writeShellScript "gsr-recording" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.systemd]}
    cgroup=$(systemctl --user show -p ControlGroup --value "''${1:-gsr-ui.service}")
    [ -n "$cgroup" ] || exit 0
    for pid in $(cat "/sys/fs/cgroup$cgroup/cgroup.procs" 2>/dev/null); do
      for fd in /proc/$pid/fd/*; do
        case $(readlink "$fd" 2>/dev/null) in
          */Video_*)
            echo recording
            exit 0
            ;;
        esac
      done
    done
  '';

  # The folder recordings go to is a UI setting (`record.save_directory` in its
  # config file, the XDG videos folder until changed), so it is read when
  # clicked rather than fixed here. xdg-user-dir answers $HOME when the user has
  # no videos folder set, where the UI falls back to ~/Videos: so does this.
  openFolderScript = pkgs.writeShellScript "gsr-open-recordings" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnused pkgs.xdg-utils pkgs.xdg-user-dirs]}
    config=''${XDG_CONFIG_HOME:-$HOME/.config}/gpu-screen-recorder/config_ui
    dir=$(sed -n 's/^record\.save_directory //p' "$config" 2>/dev/null | head -n 1)
    if [ -z "$dir" ]; then
      dir=$(xdg-user-dir VIDEOS)
      [ "$dir" != "$HOME" ] || dir=$HOME/Videos
    fi
    mkdir -p "$dir"
    exec xdg-open "$dir"
  '';

  cfg = config.dots.gpuScreenRecorder;

  # Run by systemd before it signals the unit's processes (ExecStop), so that a
  # recording still going when the service is stopped (the menu's "down", a
  # restart, logging out) ends the way the UI's own stop does and the UI says so.
  # Without this the UI is only told to exit: its shutdown stops the recorder
  # (the file is saved either way) but never raises the "Saved a ... recording"
  # notification, which only the UI's stop path does. That popup is a process of
  # the unit too, so it is also waited for: systemd would kill it at once. The
  # unit is the first argument (%n in the unit file).
  stopScript = pkgs.writeShellScript "gsr-stop" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.systemd]}
    unit=''${1:-gsr-ui.service}
    recording() { [ -n "$(${recordingScript} "$unit")" ]; }
    notifying() {
      cgroup=$(systemctl --user show -p ControlGroup --value "$unit")
      for pid in $(cat "/sys/fs/cgroup$cgroup/cgroup.procs" 2>/dev/null); do
        case $(cat "/proc/$pid/comm" 2>/dev/null) in
          *gsr-notify*) return 0 ;;
        esac
      done
      return 1
    }
    recording || exit 0
    ${cli} toggle-record || exit 0
    # Finishing a long recording can take a while: up to 30 s.
    for _ in $(seq 60); do
      recording || break
      sleep 0.5
    done
    # The popup is started just after the recorder has finished; up to 8 s.
    sleep 0.5
    for _ in $(seq 40); do
      notifying || break
      sleep 0.2
    done
  '';

  # Sets each of cfg.settings in the UI's config file, which the UI otherwise
  # owns (it rewrites the whole file whenever a setting is saved, so a read-only
  # symlink would break that). It runs before every start, so what is declared
  # wins over what the UI last saved. There is no file until the UI has run
  # once, and a file of just these lines would also reset what the UI takes from
  # a missing file (the default audio tracks), so nothing is done until then.
  # A key the file lacks is added; a key that can repeat (the audio tracks)
  # cannot be pinned.
  pinScript = pkgs.writeShellScript "gsr-pin-settings" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.diffutils]}
    config=''${XDG_CONFIG_HOME:-$HOME/.config}/gpu-screen-recorder/config_ui
    [ -f "$config" ] || exit 0
    pin() {
      key=$1 value=$2 found=
      tmp=$(mktemp)
      while IFS= read -r line || [ -n "$line" ]; do
        case $line in
          "$key "*)
            printf '%s %s\n' "$key" "$value"
            found=1
            ;;
          *) printf '%s\n' "$line" ;;
        esac
      done < "$config" > "$tmp"
      [ -n "$found" ] || printf '%s %s\n' "$key" "$value" >> "$tmp"
      cmp -s "$tmp" "$config" || cat "$tmp" > "$config"
      rm -f "$tmp"
    }
    ${lib.concatStrings (lib.mapAttrsToList (key: value: "pin ${lib.escapeShellArg key} ${lib.escapeShellArg value}\n") cfg.settings)}
  '';
in {
  options.dots.gpuScreenRecorder = {
    enable = lib.mkEnableOption ''
      GPU Screen Recorder, a ShadowPlay-style recorder with an instant-replay
      buffer and an overlay UI, which the niri module binds to Mod+Alt+Z (and
      Mod+Alt+F6..F12, see modules/home/wm/niri/gsr-binds.kdl). Installs two setcap
      wrappers: gsr-kms-server (cap_sys_admin, for promptless capture) and
      gsr-global-hotkeys (cap_setuid, which only the recorder's own hotkeys use)'';

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"record.save_directory" = "/mnt/data/Videos";};
      description = ''
        Settings of the UI (keys of ~/.config/gpu-screen-recorder/config_ui, as
        that file spells them) to set to these values each time the service
        starts. Everything else stays whatever the UI saved. See pinScript in
        modules/nixos/gpu-screen-recorder.nix for the limits: nothing is set
        before the UI has written the file once, and a key that repeats (audio
        tracks) cannot be set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # The recorder's own global hotkeys are off: they grab every keyboard, so
    # Alt+Z, Print and the rest never reach any other program, niri included.
    # Mod+... binds in niri (gsr-binds.kdl) send the same commands to the UI
    # instead. Any value but the three enable_* ones means "no hotkeys". A host
    # that wants them back sets this to "enable_hotkeys".
    dots.gpuScreenRecorder.settings."main.hotkeys_enable_option" = lib.mkDefault "disable_hotkeys";

    programs.gpu-screen-recorder = {
      enable = true;
      ui.enable = true;
    };

    # The UI owns the replay buffer (and the commands niri sends it), so it has
    # to be running before the first key press. "launch-daemon" is the
    # action meant for a service: it starts hidden and, unlike "launch-hide",
    # does not pop the UI open if one is already running. Leave the UI's own
    # "Start program on system startup" setting off, or both would start it.
    #
    # The module installs the UI with the real setcap wrapper directory baked
    # in, and does not expose that package, hence the system profile path.
    systemd.user.services.gsr-ui = {
      description = "GPU Screen Recorder overlay UI";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      # A unit's PATH is only what it lists, not the login shell's. The UI's
      # wrapper adds the recorder, the notifier and the setcap wrappers, but not
      # the UI's own helpers, which it starts by name: gsr-game-tracker ("turn on
      # replay when a game starts") was "No such file or directory" under the unit.
      path = [config.programs.gpu-screen-recorder.ui.package];
      serviceConfig = {
        # The "-" lets the service start even if pinning failed.
        ExecStartPre = lib.mkIf (cfg.settings != {}) "-${pinScript}";
        ExecStart = "/run/current-system/sw/bin/gsr-ui launch-daemon";
        # Also with "-": a failure here must not stop the stop (the unit's
        # processes are signalled afterwards in any case, which saves the file).
        ExecStop = "-${stopScript} %n";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # The services menu: whether the UI is running, and "recording" while it
    # is capturing. Stopping the unit (the menu's "down") saves a recording in
    # progress: systemd sends SIGTERM to gsr-ui and to the gpu-screen-recorder
    # it started, and both treat it as SIGINT, "stop and save" (gsr-ui's
    # destructor also waits for the recorder to finish); a replay buffer that
    # was not saved is thrown away. Not tried live yet.
    dots.services.gsr-ui = {
      label = "Screen recorder";
      icon = "videocam";
      unit = "gsr-ui.service";
      userUnit = true;
      detail = ["${recordingScript}"];
      actions = [
        {
          label = "Start / stop recording";
          icon = "fiber_manual_record";
          argv = [cli "toggle-record"];
          requiresUp = true;
        }
        {
          label = "Toggle replay buffer";
          icon = "history";
          argv = [cli "toggle-replay"];
          requiresUp = true;
        }
        {
          label = "Save replay";
          icon = "save";
          argv = [cli "replay-save"];
          requiresUp = true;
        }
        {
          label = "Show overlay";
          icon = "visibility";
          argv = [cli "toggle-show"];
          requiresUp = true;
        }
        {
          label = "Open recordings folder";
          icon = "folder_open";
          argv = ["${openFolderScript}"];
        }
      ];
    };
  };
}
