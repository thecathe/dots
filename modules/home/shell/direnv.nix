{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.shell.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
