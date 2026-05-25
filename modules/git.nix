{ ... }:
{

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings.user = {
      name = "";
      email = "";
    };
  };

}
