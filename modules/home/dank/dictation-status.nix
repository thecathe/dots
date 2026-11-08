# The DMS "Dictation" bar indicator (plugins/dictationStatus) for dots.dictation:
# a microphone that is dim while idle, pulses red while recording, shows a waveform
# while the speech is turned into text, and warns when the daemon is not running.
# It follows `voxtype status --follow`, which reads the same config file as the
# daemon. While recording, the pill's background fills as the recording nears voxtype's
# length limit (audio.max_duration_secs), at which voxtype stops it by itself.
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

  # How long voxtype lets one recording run before it stops it and transcribes what it
  # has, which the widget shows progress towards. Read from the very settings the
  # daemon's config file is generated from, so the two cannot disagree; voxtype's own
  # default (60) applies when no host sets audio.max_duration_secs.
  maxDurationSecs = lib.attrByPath ["audio" "max_duration_secs"] 60 cfg.settings;
in {
  config = lib.mkIf cfg.enable {
    programs.dank-material-shell.plugins.dictationStatus = {
      enable = true;
      src = ./plugins/dictationStatus;
      settings.maxDurationSecs = maxDurationSecs;
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
