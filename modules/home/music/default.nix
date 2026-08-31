{pkgs, ...}: {
  home.packages = with pkgs; [
    strawberry # # local library player, MPRIS-native
    playerctl # # niri's XF86Audio* binds spawn this; only present as waybar's build dep otherwise
  ];
}
