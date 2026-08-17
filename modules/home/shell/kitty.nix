{lib, ...}: {
  programs.kitty = lib.mkForce {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    keybindings = {
      "alt+enter" = "launch --cwd=current --location=vsplit";
      "alt+shift+enter" = "launch --cwd=current --location=hsplit";
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
