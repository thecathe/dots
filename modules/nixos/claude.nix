{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    claude-code
    claude-monitor
    ## claude-agent-acp ## could be interesting, no idea
  ];
}
