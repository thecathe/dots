# dots.rebuild: the `rebuild` and `rebuild-pinned` zsh aliases, for a machine built
# from a hosts flake that consumes dots. Each host says how it switches and which
# output it is; `rebuild` takes dots (and any localInputs) from local checkouts,
# `rebuild-pinned` uses the hosts flake's lock file. Until 2026-11-21 this lived in
# the hosts repository as `hosts.rebuild`.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.dots.rebuild;

  switch =
    if cfg.switch == "nixos"
    then "sudo nixos-rebuild switch"
    else "home-manager switch";
  # Over ssh there is no session bus, so home-manager's dconf step starts its own
  # with Nix's dbus-run-session. Nix's dbus-daemon reads /etc/dbus-1/session.conf,
  # which Ubuntu does not ship (it keeps it under /usr/share), so that bus never
  # starts ("EOF reading address from bus daemon") and the dconf keys are not
  # loaded. So a standalone home-manager switch is pointed at the user's real
  # bus when there is one: only if the variable is unset (a desktop session sets
  # it) and the socket exists (otherwise the private bus is still the better
  # try). The alias runs in a subshell, so this never leaks into the shell.
  # One line, because it sits in an && chain.
  sessionBus =
    if cfg.switch == "home-manager"
    then ''if [ -z "''${DBUS_SESSION_BUS_ADDRESS-}" ] && [ -S "/run/user/$(id -u)/bus" ]; then export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"; fi && ''
    else "";
  # dots comes from a snapshot commit of the checkout, never its working tree:
  # dots' DMS settings.json has a git clean filter, so git can call the tree
  # clean while the file on disk differs, and nix then caches the on-disk
  # copy under the public commit's hash (a later fetch of that commit, from
  # GitHub too, fails with a NAR hash mismatch). `git stash create` records
  # the tracked files' current state as a commit (through the filter) without
  # touching the working tree or the stash list; on a clean tree it is HEAD.
  # Untracked files are left out, as flakes always did.
  # The script is a plain file so `check` can run the very same one.
  dotsSnapshot = import ./snapshot-package.nix {inherit pkgs;};
  # The snapshot is taken in its own step ahead of the build, and the build only
  # runs if that succeeded: written inline as "$(dots-snapshot)", a failure would
  # leave an empty argument that nix quietly reads as the current directory.
  # dots-snapshot retries and says so; if it still fails the build does not start.
  localInputs = {${cfg.input} = "\"$dots_ref\"";} // cfg.localInputs;
  overrides = lib.concatStrings (lib.mapAttrsToList (input: ref: " --override-input ${input} ${ref}") localInputs);
  alias = prelude: flags: ''
    (cd ${lib.escapeShellArg cfg.flake} && ${prelude}${sessionBus}${switch} --flake .#${cfg.target}${flags});
    printf "Press Enter to continue...";
    read -r _
  '';
in {
  imports = [../checkout.nix];

  options.dots.rebuild = {
    enable = lib.mkEnableOption "the `rebuild` and `rebuild-pinned` aliases, which switch this machine from its hosts flake";

    flake = mkOption {
      type = types.str;
      example = "/home/alice/src/hosts";
      description = "The absolute path of the local checkout of the hosts flake this machine is built from.";
    };
    dots = mkOption {
      type = types.str;
      default = config.dots.checkout;
      defaultText = lib.literalExpression "config.dots.checkout";
      description = "The dots checkout that `rebuild` builds with (as a snapshot of its tracked files).";
    };
    input = mkOption {
      type = types.str;
      default = "dots";
      description = "The name of the hosts flake's input that is dots.";
    };
    switch = mkOption {
      type = types.enum ["nixos" "home-manager"];
      description = "How the host switches: nixos-rebuild, or standalone home-manager.";
    };
    target = mkOption {
      type = types.str;
      example = "nixos";
      description = "The host's output: its nixosConfigurations or homeConfigurations name.";
    };
    localInputs = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {minecraft = "path:$HOME/src/minecraft";};
      description = "Inputs besides dots (always included) that `rebuild` takes from local checkouts (input name -> flake ref) instead of the lock file.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [dotsSnapshot];

    programs.zsh = {
      enable = true;
      shellAliases = {
        # Builds with the local checkouts in localInputs (uncommitted edits to
        # tracked files included), so editing them and rebuilding needs no pin bump.
        rebuild = alias "dots_ref=$(dots-snapshot ${lib.escapeShellArg cfg.dots}) && " "${overrides} --no-write-lock-file";
        # Builds with the revisions pinned in the hosts flake's lock file.
        rebuild-pinned = alias "" "";
      };
    };
  };
}
