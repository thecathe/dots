# The DMS "Dictation" bar indicator (plugins/dictationStatus) for dots.dictation:
# a microphone that is dim while idle, pulses red while recording, shows a waveform
# while the speech is turned into text, and warns when the daemon is not running.
# It follows `voxtype status --follow`, which reads the same config file as the
# daemon.
#
# Installed only where dictation is enabled. The widget itself is listed in each
# bar's rightWidgets in settings.json, shared by every host; on a host without the
# plugin that id has nothing behind it and DMS draws nothing for it.
{
  config,
  lib,
  ...
}: let
  cfg = config.dots.dictation;
in {
  config = lib.mkIf cfg.enable {
    programs.dank-material-shell.plugins.dictationStatus = {
      enable = true;
      src = ./plugins/dictationStatus;
      settings.statusCommand = [
        "${cfg.package}/bin/voxtype"
        "status"
        "--follow"
        "--format"
        "json"
      ];
    };
  };
}
