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
    settings.push.recurseSubmodules = "check"; # refuse to push a superproject whose submodule commits aren't pushed
    ignores = [
      "_opam/" # opam local switches
      ".opam-root/" # a project's own opam root (its dev shell sets OPAMROOT to it)
      "_build/" # build files
      ".direnv/" # direnv cache
      ".vscode/" # vscode settings
      "*.sw?" # vim swap files
      ".DS_store" # mac stuff
    ];
  };
}
