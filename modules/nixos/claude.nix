{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.claude.enable = lib.mkEnableOption "Claude Code and its usage monitor, for every user" // {default = true;};

  config = lib.mkIf config.dots.claude.enable {
    environment.systemPackages = with pkgs; [
      claude-code
      claude-monitor
      ## claude-agent-acp ## could be interesting, no idea
    ];
  };
}
