{lib, ...}: {
  programs.kitty = lib.mkForce {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    config = ''
      map alt+enter kitten split-window --cwd=current --direction=vertical
      map alt+shift+enter kitten split-window --cwd=current --direction=horizontal
    '';
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
