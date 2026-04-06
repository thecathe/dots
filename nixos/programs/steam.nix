{ ... }:

{
  # https://mynixos.com/options/programs.steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
}
