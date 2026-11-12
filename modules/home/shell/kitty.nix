{lib, ...}: {
  programs.kitty = lib.mkForce {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    keybindings = {
      "alt+enter" = "launch --cwd=current --location=vsplit";
      "alt+shift+enter" = "launch --cwd=current --location=hsplit";
      # vim-flavoured pane and tab keys, as two prefixes (kitty waits `map_timeout` for the second key):
      #   alt+w  panes, like vim's ctrl+w     alt+g  tabs, like vim's g
      # Not alt+hjkl (nvim mini.move) or ctrl+hjkl/ctrl+w (nvim, readline). Reminders: navi/cheats/kitty.cheat.
      "alt+w>h" = "neighboring_window left";
      "alt+w>j" = "neighboring_window down";
      "alt+w>k" = "neighboring_window up";
      "alt+w>l" = "neighboring_window right";
      "alt+w>shift+h" = "layout_action move_to_screen_edge left";
      "alt+w>shift+j" = "layout_action move_to_screen_edge bottom";
      "alt+w>shift+k" = "layout_action move_to_screen_edge top";
      "alt+w>shift+l" = "layout_action move_to_screen_edge right";
      "alt+w>x" = "move_window_forward";
      "alt+w>r" = "layout_action rotate"; # flips the split's axis, not vim's ctrl+w r
      "alt+w>equal" = "layout_action equalize";
      "alt+w>z" = "layout_action maximize horizontal";
      "alt+w>shift+z" = "layout_action maximize vertical";
      "alt+w>v" = "launch --cwd=current --location=vsplit";
      "alt+w>s" = "launch --cwd=current --location=hsplit";
      "alt+w>c" = "close_window";
      "alt+w>w" = "next_window";
      "alt+w>shift+t" = "detach_window new-tab";
      "alt+w>m" = "detach_window ask"; # also turns a one-pane tab into a pane of another tab
      "alt+w>shift+o" = "detach_window"; # into its own OS window
      "alt+g>t" = "next_tab";
      "alt+g>shift+t" = "previous_tab";
      "alt+g>o" = "detach_tab"; # into its own OS window
      "alt+g>shift+o" = "detach_tab ask"; # into another OS window

      "ctrl+shift+d" = ''
        launch --type=overlay --title='nvim dots' zsh -c 'tmux attach -t dots:0.0 2>/dev/null || tmux new-session -s dots -c ~/dots nvim'
      '';
      # launch --type=overlay --title='nvim dots' zsh -c 'tmux attach -t dots:0.0 2>/dev/null || (tmux new-session -d -s dots -c ~/dots nvim && tmux split-window -v -t dots:0 -c ~/dots && tmux resize-pane -t dots:0.1 -y 2 && tmux attach -t dots)'

      # free up so these can be used for select
      # just use ctrl+tab/ctrl+shift+tab
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
      # stop kitty intercepting these
      "ctrl+shift+up" = "no_op";
      "ctrl+shift+down" = "no_op";
      "ctrl+shift+home" = "no_op";
      "ctrl+shift+end" = "no_op";
    };
    settings = {
      ##
      confirm_os_window_close = 0;
      map_timeout = "2.0";
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-{kitty_pid}";
      ##
      dynamic_background_opacity = true;
      background_opacity = "0.9";
      background_blur = 5;
      ##
      enable_audio_bell = false;
      ##
      enabled_layouts = "splits";
      #      window_padding_width = 5;
      #      window_border_width = "0.2pt";
      ##
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
      ##
      cursor_trail = 10;
      cursor_trail_decay = "0.1 0.4";
      cursor_blink_interval = "1.0";
      cursor_stop_blinking_after = "0";
    };
  };
}
