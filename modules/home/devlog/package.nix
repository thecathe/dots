# dlsync (see dlsync.sh), as its own file so the module and the behaviour check
# in checks/dlsync.nix build the very same script.
{
  pkgs,
  defaultDir ? "",
}:
pkgs.writeShellApplication {
  name = "dlsync";
  runtimeInputs = with pkgs; [git coreutils util-linux gnused];
  runtimeEnv.DLSYNC_DEFAULT_DIR = defaultDir;
  text = builtins.readFile ./dlsync.sh;
}
