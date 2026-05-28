{ ... }:

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
    setOptions = [
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_SAVE_NO_DUPS"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_SPACE"
      "APPENDHISTORY"
      "SHARE_HISTORY"
      "HIST_FCNTL_LOCK"
    ];

    initContent = ''
      export PATH="$HOME/dots/bin:$PATH"
      ## 
      webm2mp4() {
        local input output
        input="$(realpath "$1")"
        output="$(realpath -, "$2")" 
        nix-shell -p ffmpeg --run \ 
          "ffmpeg -i '$input' -c:v libx264 -crf 18 -c:a flac '$output'"
      }
    '';

    shellAliases = {
      # update = "sudo nixos-rebuild test";
      # upgrade = "sudo nixos-rebuild switch";
      # upboot = "sudo nixos-rebuild boot";
      # refresh = "home-manager switch -b backup";
      # nix-shell = "nix-shell --run $SHELL";
      img2pdf = "nix-shell -p img2pdf --run $SHELL";
      torrent = "nix-shell -p qbittorrent tor-browser --run $SHELL";
      epub = "nix-shell -p epy --run $SHELL";
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
    theme = "agnoster";
    # custom = "/home/cathe/dots/.config/home-manager/zsh/custom/";
  };
}
