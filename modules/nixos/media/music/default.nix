{pkgs, ...}: {
  home.packages = with pkgs; [
    strawberry # # local library player, MPRIS-native
  ];
}
