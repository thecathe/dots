{ ... }:
{
  # https://mynixos.com/options/programs.git
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };
}
