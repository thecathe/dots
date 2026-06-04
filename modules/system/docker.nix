{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
  };
  users.users.cathe.extraGroups = [ "docker" ];
  # compose2nix
  environment.systemPackages = with pkgs; [
    compose2nix
    docker-compose
    lazydocker
  ];
}
