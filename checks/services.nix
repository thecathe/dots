# The `services` command's behaviour against fake services under a throwaway
# directory (services-test.sh): its listing and JSON, states, switching, short
# names, extra actions and the window for a terminal one, the timeout, and its
# refusals. It builds the same script the module installs. A real build, but
# nothing in it is heavier than a few `sh -c` and a handful of one-second sleeps.
#
# What reaches the command from Nix (the ids, the short names, the slug of a
# label, the options) is evaluated in consumer.nix (consumer-services).
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  services = import ../modules/home/services/package.nix {inherit pkgs;};
in {
  services = pkgs.runCommand "services-behaviour" {nativeBuildInputs = [services pkgs.jq];} ''
    bash ${./services-test.sh}
    touch $out
  '';
}
