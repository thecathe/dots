# The system side of dots.services (modules/shared/services.nix): install the
# CLIs, and let the dots user start and stop the entries' system units without
# a password, so the CLIs and the services menu need no sudo. The rule names
# each unit and each verb; it grants nothing else.
{
  config,
  lib,
  ...
}: let
  units = lib.unique (lib.concatMap (s: lib.optional (s.unit != null && !s.userUnit) s.unit) (lib.attrValues config.dots.services));
in {
  environment.systemPackages = config.dots.servicesPackages;

  security.polkit.extraConfig = lib.mkIf (units != []) ''
    // dots.services: the dots user may start and stop these units.
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == ${builtins.toJSON config.dots.user.name} &&
          ${builtins.toJSON units}.indexOf(action.lookup("unit")) >= 0 &&
          ["start", "stop", "restart"].indexOf(action.lookup("verb")) >= 0) {
        return polkit.Result.YES;
      }
    });
  '';
}
