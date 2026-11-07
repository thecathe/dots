# Offline voice dictation: press Mod+D, speak, press Mod+D again, and the text is
# typed into the focused window. Everything runs on this machine; nothing is sent
# anywhere.
#
# The pieces:
#   voxtype  the dictation daemon (nixpkgs), built with ONNX support so it can run
#            NVIDIA's Parakeet speech model on the CPU (its default, Whisper, is
#            what you get without it). It records from the default microphone,
#            transcribes, and types the result with wtype (which the nixpkgs
#            package puts on its own PATH, with wl-clipboard and dotool as
#            fallbacks).
#   the model  models.nix: Parakeet TDT 0.6B v2 (English only), fetched from
#            Hugging Face by hash when a build first needs it.
#   a user service  `voxtype daemon`, started with the graphical session.
#   a niri bind  `voxtype record toggle` on Mod+D. niri binds fire on press only
#            (there is no release trigger), so this is start/stop, not hold to
#            talk. voxtype's own hotkey would give hold to talk but needs the
#            `input` group and a grab on every keyboard, so it is off.
#
# The text goes to whichever window has focus when transcription finishes, so
# keep the target focused. (A VS Code extension that takes text for its own editor
# whatever has focus is a planned later step.)
#
# voxtype's config file is generated from `settings` and installed read-only. The
# daemon never writes it, but `voxtype config set`, `voxtype configure` and
# `voxtype setup model` do: the first two would replace the link with a plain file
# (home-manager then refuses to overwrite it at the next switch), the last fails.
# Change settings here. To try something without touching the managed file, stop
# the service and run `voxtype -c /tmp/try.toml daemon`.
#
# The CPU speed of both model variants and the reasoning behind the defaults are in
# the devlog entry dots/voice-dictation.md.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.dictation;

  tomlFormat = pkgs.formats.toml {};
  models = pkgs.callPackage ./models.nix {};

  voxtype = "${cfg.package}/bin/voxtype";

  configFile = tomlFormat.generate "voxtype-config.toml" cfg.settings;

  # Added to niri's config the way gsr-binds.kdl is: binds in an included file
  # are merged into the main `binds` block (a second block in config.kdl itself
  # would be an error).
  #   repeat=false  holding the key would otherwise toggle again and again
  # allow-inhibiting is left at its default (true), so a game or remote desktop
  # that asks niri to stop processing shortcuts also stops dictation.
  bindsFile = pkgs.writeText "dictation-binds.kdl" ''
    // Voice dictation (modules/home/dictation). Start/stop dictating into the
    // focused window.
    binds {
        ${cfg.bind} repeat=false hotkey-overlay-title="Dictation: start/stop" { spawn "${voxtype}" "record" "toggle"; }
    }
  '';
in {
  options.dots.dictation = {
    enable = lib.mkEnableOption "offline voice dictation (voxtype with a Parakeet model)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.voxtype.override {onnxSupport = true;};
      defaultText = lib.literalExpression "pkgs.voxtype.override { onnxSupport = true; }";
      description = ''
        The voxtype package. It has to be built with ONNX support, or the
        Parakeet engine is missing.
      '';
    };

    model = lib.mkOption {
      type = lib.types.enum (builtins.attrNames models);
      default = "v2";
      description = ''
        Which Parakeet model directory to use (see models.nix): `v2` is the
        full-precision model, `v2-int8` the 8-bit quantised one.
      '';
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "Mod+D";
      example = "Mod+Alt+D";
      description = ''
        The niri key that starts and stops dictation. Takes effect on hosts that
        use dots' niri module.
      '';
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = {};
      example = {
        text.spoken_punctuation = true;
      };
      description = ''
        voxtype's config.toml, as an attribute set. Only what differs from
        voxtype's own defaults needs to be here; the defaults set by this module
        can be replaced with a plain assignment.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dots.dictation.settings = {
      engine = lib.mkDefault "parakeet";
      parakeet = {
        model = lib.mkDefault "${models.${cfg.model}}";
        # The directory is detected as a TDT model by looking for the
        # full-precision file names, which the int8 variant does not have.
        model_type = lib.mkDefault "tdt";
        # Keep the model in memory between dictations. Loading it for each
        # recording would add a delay before the first word is heard.
        on_demand_loading = lib.mkDefault false;
      };
      # voxtype's own default is on, and would grab every keyboard to watch for
      # its key. The niri bind owns the key.
      hotkey.enabled = lib.mkDefault false;
      # With a toggle bind and no window of its own, a short sound on start, stop
      # and finish is the only sign that anything happened.
      audio.feedback.enabled = lib.mkDefault true;
    };

    home.packages = [cfg.package];

    xdg.configFile."voxtype/config.toml".source = configFile;

    systemd.user.services.voxtype = {
      Unit = {
        Description = "voxtype: offline voice dictation";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        # The config is read once at start; a changed file means a new store
        # path, which would otherwise leave the old daemon running on the old one.
        X-Restart-Triggers = [configFile];
        # A bad config or a missing model makes the daemon exit at once. Retry a
        # few times, then stay failed (visible in `systemctl --user status`)
        # instead of loading the model every 5 s forever.
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        ExecStart = "${voxtype} daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    wayland.windowManager.niri.extraConfig = ''
      include "${bindsFile}"
    '';
  };
}
