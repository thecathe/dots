# repos (see repos.sh), as its own file so the module and the behaviour check
# in checks/repos.nix build the very same script. The options travel as one
# JSON file (REPOS_CONFIG) rather than environment strings: shellcheck objects
# to JSON in a variable, and a file is easier to inspect.
{
  pkgs,
  root ? null,
  integration ? {},
  exclude ? [],
  owners ? [],
}:
pkgs.writeShellApplication {
  name = "repos";
  runtimeInputs = with pkgs; [git jq coreutils gawk gnugrep util-linux];
  # The default; REPOS_CONFIG in the environment names another file.
  runtimeEnv.REPOS_DEFAULT_CONFIG = pkgs.writeText "repos-config.json" (builtins.toJSON {
    inherit root integration exclude owners;
  });
  text = builtins.readFile ./repos.sh;
}
