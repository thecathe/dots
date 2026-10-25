{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.docker.enable = lib.mkEnableOption ''
    Docker. Membership of the docker group is root-equivalent: anyone in it
    can start a privileged container'';

  config = lib.mkIf config.dots.docker.enable {
    virtualisation.docker = {
      enable = true;
    };
    users.users.${config.dots.user.name}.extraGroups = ["docker"];
    # compose2nix
    environment.systemPackages = with pkgs; [
      compose2nix
      docker-compose
      lazydocker
    ];
  };
}
