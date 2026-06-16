{...}: {
  programs.bash.sessionVariables = {KP_EDITOR = "neovide";};
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
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_SAVE_NO_DUPS"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_SPACE"
      "APPENDHISTORY"
      "SHARE_HISTORY"
      "HIST_FCNTL_LOCK"
    ];

    sessionVariables = {KP_EDITOR = "neovide";};
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
      img2pdf = "nix-shell -p img2pdf --run $SHELL";
      torrent = "qbittorrent & tor-browser &";
      epub = "nix-shell -p epy --run $SHELL";
    };
  };
}
