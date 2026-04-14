{ pkgs, ... }:

let
  thenixuser = import /home/cathe/dots/user.nix { inherit pkgs; };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };
    setOptions = thenixuser.configs.zsh.options;

    shellAliases = {
      update = "sudo nixos-rebuild test";
      upgrade = "sudo nixos-rebuild switch";
      refresh = "home-manager switch";
      nix-shell = "nix-shell --run $SHELL";
    };
  };

  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
      "github"
      "profiles"
      "themes"
      "tmux" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/tmux
      "vscode"
      "web-search" # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/web-search
    ];
    theme = thenixuser.configs.zsh.theme;
    # custom = "/home/cathe/dots/.config/home-manager/zsh/custom/";
  };
}
