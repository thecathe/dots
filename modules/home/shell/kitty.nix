{ lib, ... }:

{
  programs.kitty = lib.mkForce {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      ##
      confirm_os_window_close = 0;
      # allow_remote_control = "yes";
      ##
#      dynamic_background_opacity = true;
#      background_opacity = "0.8";
#      background_blur = 50;
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
