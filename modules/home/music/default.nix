{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.music.enable = lib.mkEnableOption "music playback support (playerctl)" // {default = true;};

  config = lib.mkIf config.dots.music.enable {
    home.packages = with pkgs; [
      playerctl # # niri's XF86Audio* binds spawn this; only present as waybar's build dep otherwise
    ];
  };
}
