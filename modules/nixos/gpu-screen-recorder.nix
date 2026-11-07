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
  # processes are not all children of gsr-ui.
  recordingScript = pkgs.writeShellScript "gsr-recording" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.systemd]}
    cgroup=$(systemctl --user show -p ControlGroup --value gsr-ui.service)
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
in {
  options.dots.gpuScreenRecorder.enable = lib.mkEnableOption ''
    GPU Screen Recorder, a ShadowPlay-style recorder with an instant-replay
    buffer and an overlay UI (Alt+Z). Installs two setcap wrappers:
    gsr-kms-server (cap_sys_admin, for promptless capture) and
    gsr-global-hotkeys (cap_setuid, for hotkeys under Wayland)'';

  config = lib.mkIf config.dots.gpuScreenRecorder.enable {
    programs.gpu-screen-recorder = {
      enable = true;
      ui.enable = true;

      # nixpkgs builds it against ffmpeg 9, whose NVENC headers need API 13.1,
      # but the 595 driver offers 13.0, so gsr drops every NVENC codec
      # ("gsr_get_supported_video_codecs_nvenc: your nvidia driver only supports
      # nvenc api version 13.0 ...") and is left with software h264 and the
      # experimental Vulkan encoders. ffmpeg 7 brings them back (checked with
      # `gpu-screen-recorder --info`: h264, hevc, av1, 10-bit and HDR). Drop
      # this once the driver catches up with the headers. The module hands this
      # package on to the UI, so the one override covers both.
      package = pkgs.gpu-screen-recorder.override {ffmpeg = pkgs.ffmpeg_7;};
    };

    # The UI is what owns the global hotkeys and the replay buffer, so it has
    # to be running before the first hotkey press. "launch-daemon" is the
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
      serviceConfig = {
        ExecStart = "/run/current-system/sw/bin/gsr-ui launch-daemon";
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
