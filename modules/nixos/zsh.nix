{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.zsh.enable = lib.mkEnableOption "zsh as the system shell, with dots' defaults" // {default = true;};

  config = lib.mkIf config.dots.zsh.enable {
    # https://mynixos.com/options/programs.zsh
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    users.defaultUserShell = pkgs.zsh;
    environment.shells = with pkgs; [zsh];
  };
}
