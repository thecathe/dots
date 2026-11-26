# services (see services.sh), as its own file so the module and the behaviour
# check in checks/services.nix build the very same script. The entries travel as
# one JSON file (SERVICES_DEFAULT_CONFIG), the manifest default.nix builds from
# dots.services: the commands are argv lists, which a file carries without any
# quoting. SERVICES_CONFIG in the environment names another file (the check
# writes its own).
{
  pkgs,
  manifest ? {
    name = "services";
    timeout = 3;
    window = null;
    services = [];
  },
}:
pkgs.writeShellApplication {
  name = manifest.name;
  runtimeInputs = with pkgs; [jq coreutils util-linux];
  runtimeEnv.SERVICES_DEFAULT_CONFIG = pkgs.writeText "services-config.json" (builtins.toJSON manifest);
  text = builtins.readFile ./services.sh;
}
