# orient (see orient.sh), as its own file so the module and the behaviour check
# in checks/orient.nix build the very same script. It calls dlsync, so that
# keeps its locking and merge logic; python3Minimal is only for reading the
# registry's TOML (tomllib is in its standard library).
{
  pkgs,
  devlogDir ? "",
}: let
  dlsync = import ./package.nix {inherit pkgs;};
in
  pkgs.writeShellApplication {
    name = "orient";
    runtimeInputs = [dlsync] ++ (with pkgs; [git gh jq python3Minimal coreutils gawk gnused]);
    runtimeEnv = {
      ORIENT_DEFAULT_DEVLOG_DIR = devlogDir;
      ORIENT_DEFAULT_REGISTRY =
        if devlogDir == ""
        then ""
        else "${devlogDir}/registry.toml";
    };
    text = builtins.readFile ./orient.sh;
  }
