{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.shell.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
