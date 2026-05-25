{ pkgs, lib, ... }:

{
  programs.kitty = lib.mkForce {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      dynamic_background_opacity = true;
      background_opacity = "0.8";
      background_blur = 50;
    };
  };
}
