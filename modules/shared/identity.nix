# Who the machine's dots user is. dots is public, so it names nobody: each
# machine (its own flake) sets these. Imported by both the NixOS and the
# home-manager module sets; mkNixos sets `name` on the NixOS side, and
# home-manager defaults it to home.username.
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.dots.user = {
    name = mkOption {
      type = types.str;
      description = "The dots user's login name.";
    };
    git = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The name git records on commits. Unset leaves git's user.name alone.";
      };
      email = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The email git records on commits. Unset leaves git's user.email alone.";
      };
    };
  };
}
