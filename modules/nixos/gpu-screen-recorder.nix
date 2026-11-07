{
  config,
  lib,
  ...
}: {
  options.dots.gpuScreenRecorder.enable = lib.mkEnableOption ''
    GPU Screen Recorder, a ShadowPlay-style recorder with an instant-replay
    buffer and an overlay UI (Alt+Z). Installs two setcap wrappers:
    gsr-kms-server (cap_sys_admin, for promptless capture) and
    gsr-global-hotkeys (cap_setuid, for hotkeys under Wayland)'';

  config = lib.mkIf config.dots.gpuScreenRecorder.enable {
    programs.gpu-screen-recorder = {
      enable = true;
      ui.enable = true;
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
  };
}
