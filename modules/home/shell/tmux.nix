{...}: {
  programs.tmux = {
    enable = true;
    shortcut = "b"; # Ctrl+b
    escapeTime = 0;
    terminal = "screen-256color";
    extraConfig = ''
      set -g mouse on
      # make colours work correctly with nvim
      set -sa terminal-features ",xterm-256color:RGB"
    '';
  };
}
