{
  pkgs,
  lib,
  ...
}: {
  imports = [./aliases.nix];
  programs.bash.sessionVariables = {KP_EDITOR = "neovide";};
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
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
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        export PATH="$HOME/dots/bin:$PATH"
      '')
      (lib.mkOrder 1000 ''
        # forward/backward word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
      '')
      (lib.mkOrder 1200 ''
        webm2mp4() {
          local input output
          input="$(realpath "$1")"
          output="$(realpath -, "$2")"
          nix-shell -p ffmpeg --run \
            "ffmpeg -i '$input' -c:v libx264 -crf 18 -c:a flac '$output'"
        }
      '')
    ];

    plugins = [
      {
        # shift-select/ctrl+shift-select
        name = "zsh-shift-select";
        src = pkgs.fetchFromGitHub {
          owner = "jirutka";
          repo = "zsh-shift-select";
          rev = "47296f18c52e9cdff5ddf0c28a5cc8c88ef8696e";
          hash = "sha256-4kUUBH2GTMb/d6PUNiSNFogkvDUSwMX823j4xsroJKs=";
        };
      }
    ];
  };
}
