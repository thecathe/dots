# Where this machine's working copy of dots lives.
#
# Most of dots is read-only Nix, but a few files have to stay writable, so home-manager
# points at them in the checkout instead of copying them into the store: DMS's
# settings.json (its settings app writes it), the Claude Code settings, the wallpaper
# favourites, the zsh alias files. The modules that need the checkout import this file
# (keyed by path, so any number of them is fine) and read `config.dots.checkout`, so a
# machine with the checkout elsewhere sets one option rather than nine strings.
{
  config,
  lib,
  ...
}: {
  options.dots.checkout = lib.mkOption {
    type = lib.types.pathWith {
      absolute = true;
      inStore = false;
    };
    default = "${config.home.homeDirectory}/dots";
    defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/dots"'';
    example = "/home/alice/src/dots";
    description = ''
      The absolute path of the mutable working copy of dots on this machine. It must be a
      real checkout of the repository, not a path in the Nix store.
    '';
  };
}
