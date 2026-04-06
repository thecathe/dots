{ pkgs, ... }:

{
  # https://mynixos.com/options/programs.zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
    };

    shellAliases = {
      update = "sudo nixos-rebuild test";
      upgrade = "sudo nixos-rebuild switch";
      refresh = "home-manager switch";
    };
  };
  users.defaultUserShell = pkgs.zsh;
  #system.userActivationScripts.zshrc = "touch .zshrc";
  environment.shells = with pkgs; [ zsh ];
}
