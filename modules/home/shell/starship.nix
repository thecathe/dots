{
  config,
  lib,
  ...
}: {
  options.dots.shell.starship.palette = lib.mkOption {
    type = lib.types.attrsOf (lib.types.strMatching "#[0-9a-fA-F]{6}");
    description = ''
      The prompt's palette: starship colour names (`color_orange`) and their `#rrggbb`. It is
      handed to starship as its `gruvbox_dark` palette, so every segment draws from it, and
      the layer and ssh segments (`dots.shell.starship.layers`) name their colours from it.
      Entries set here are added to the defaults (in `palette.nix` beside this module) and
      replace the one of the same name. The preset's segments use `color_fg0`, `color_bg1`,
      `color_bg3`, `color_blue`, `color_aqua`, `color_orange` and `color_yellow`; leave
      those names in.
    '';
  };

  config = lib.mkMerge [
    # One entry at a time, so that setting a single colour keeps the rest.
    {dots.shell.starship.palette = lib.mapAttrs (_: lib.mkDefault) (import ./palette.nix);}

    (lib.mkIf config.dots.shell.enable {
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        presets = [
          "nerd-font-symbols"
          "gruvbox-rainbow"
          # "catppuccin-powerline"
        ];
        settings = {
          add_newline = true;

          # The preset's palette, with ours in its place (merged after the presets, so ours wins).
          palette = "gruvbox_dark";
          palettes.gruvbox_dark = config.dots.shell.starship.palette;

          directory = {
            disabled = false;

            substitutions = {
              "Documents" = "DOCS";
              "Downloads" = "DOWN";
              "Music" = "MUSI";
              "Pictures" = "PICS";
            };
          };
        };
      };
    })
  ];
}
