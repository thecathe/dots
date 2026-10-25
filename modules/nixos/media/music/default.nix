{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    strawberry # # local library player, MPRIS-native
  ];
}
