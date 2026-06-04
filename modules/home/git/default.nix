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
      name = "thecathe";
      email = "pearsandcabbage@gmail.com";
    };
    ignores = [
      "_opam/" # opam local switches
      "_build/" # build files
      ".direnv/" # direnv cache
      ".vscode/" # vscode settings
      "*.sw?" # vim swap files
      ".DS_store" # mac stuff
    ];
  };

}
