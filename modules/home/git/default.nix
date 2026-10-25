{
  config,
  lib,
  ...
}: let
  inherit (config.dots.user) git;
in {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings.user =
      lib.optionalAttrs (git.name != null) {inherit (git) name;}
      // lib.optionalAttrs (git.email != null) {inherit (git) email;};
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
