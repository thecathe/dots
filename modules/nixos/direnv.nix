{
  config,
  lib,
  ...
}: {
  options.dots.direnv.enable = lib.mkEnableOption "direnv with nix-direnv" // {default = true;};

  config = lib.mkIf config.dots.direnv.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
