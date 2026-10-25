{pkgs, ...}: {
  home.packages = with pkgs; [
    playerctl # # niri's XF86Audio* binds spawn this; only present as waybar's build dep otherwise
  ];
}
