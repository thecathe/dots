{
  config,
  lib,
  ...
}: {
  options.dots.git.enable = lib.mkEnableOption "git with LFS and dots' defaults" // {default = true;};

  config = lib.mkIf config.dots.git.enable {
    # https://mynixos.com/options/programs.git
    programs.git = {
      enable = true;
      lfs.enable = true;
      config = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };
  };
}
