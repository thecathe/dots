{pkgs, ...}: {
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
}
