# A prompt segment for each layer the shell is in: `nix-shell`, `nix develop` and direnv.
# The story, the design and what was ruled out are in the devlog (dots/starship-layers.md);
# in short: each layer is a starship segment of its own between the first (orange) one and
# the directory, with a symbol, a short text and a colour per kind, and a layer never
# takes the colour of the one outside it.
#
# Starship cannot take a segment's colour from a variable, and the arrows either side of a
# segment carry its colour and its neighbour's, so this module writes one config for every
# state the prompt can be in (the deployed starship.toml with the layer segments spliced
# into its `format`), and layers.zsh points STARSHIP_CONFIG at the right one before each
# prompt. A shell with no layer keeps the unchanged config.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.shell.starship.layers;
  starship = config.programs.starship;

  # The deployed starship.toml: home-manager merges the presets into it, so it is edited
  # and not rebuilt from `settings`.
  baseConfig = config.home.file.${starship.configPath}.source;

  # Nix strings have no \u escape, and a private-use glyph is not safe to paste in a chat.
  glyph = hex: builtins.fromJSON ''"\u${hex}"'';

  hexColour = lib.types.strMatching "#[0-9a-fA-F]{6}";
  # Characters that would end or open something in a starship format string.
  plainText = lib.types.strMatching "[^][()$\\\\\"]*";

  # The defaults are on the fields, not on the kind, so that setting one field of a kind
  # (just its colours, say) keeps the others.
  kindOption = defaults: what:
    lib.mkOption {
      default = {};
      description = "The segment for ${what}.";
      type = lib.types.submodule {
        options = {
          symbol = lib.mkOption {
            type = plainText;
            default = defaults.symbol;
            description = "The glyph shown first in the segment (a Nerd Font symbol). May not contain any of `[]()$\\\"`.";
          };
          text = lib.mkOption {
            type = plainText;
            default = defaults.text;
            description = "A short word after the symbol; never the derivation's name. May not contain any of `[]()$\\\"`.";
          };
          colors = lib.mkOption {
            type = lib.types.listOf hexColour;
            default = defaults.colors;
            description = ''
              Background colours as `#rrggbb`, in order of preference. A layer takes the first
              one that differs from the layer directly outside it, so that a nested layer
              never looks like its parent and the first one is what the kind looks like on its
              own. At least two different ones are needed, and none may be the prompt's first
              segment's colour (`color_orange`) or the directory's (`color_yellow`), which sit
              either side.
            '';
          };
        };
      };
    };

  colours = k: map lib.toLower k.colors;
  kinds = cfg.kinds;

  # (kind, position in its colour list, colour): the states one segment can be in. The
  # position, not the colour, names a config, so two kinds may share a colour.
  entries = lib.concatLists (lib.mapAttrsToList (kind: k:
    lib.imap1 (j: colour: {
      inherit kind j colour;
      inherit (k) symbol text;
    }) (colours k))
  kinds);
  segName = e: "${e.kind}.${toString e.j}";

  # One config per shown state: a single segment, or (with maxShown 2) two, whose colours
  # differ because the colour rule makes the inner one differ from the one outside it.
  variants =
    map (e: {
      name = segName e;
      segs = [e];
    })
    entries
    ++ lib.optionals (cfg.maxShown >= 2) (lib.concatMap (a:
      lib.concatMap (b:
        lib.optional (a.colour != b.colour) {
          name = "${segName a}+${segName b}";
          segs = [a b];
        })
      entries)
    entries);

  gen = v: ''gen ${lib.escapeShellArg v.name} ${lib.concatMapStringsSep " " (s: lib.escapeShellArgs [s.colour s.symbol s.text]) v.segs}'';

  data = pkgs.writeText "starship-layers-data.zsh" ''
    _dots_layers_max=${toString cfg.maxShown}
    typeset -gA _dots_layer_colors
    _dots_layer_colors=(
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (kind: k: "  ${lib.escapeShellArg kind} ${lib.escapeShellArg (lib.concatStringsSep " " (colours k))}") kinds)}
    )
  '';

  package =
    pkgs.runCommand "starship-layers" {
      allColours = lib.unique (map (e: e.colour) entries);
    } ''
      # bash 5.2 reads `&` in a replacement as the matched text
      shopt -u patsub_replacement 2>/dev/null || true
      base=${baseConfig}

      palette() { sed -nE "s/^$1 = \"(#[0-9a-fA-F]{6})\".*/\1/p" "$base" | tr A-F a-f; }
      orange=$(palette color_orange)
      yellow=$(palette color_yellow)
      [[ -n $orange && -n $yellow ]] || { echo "starship-layers: the deployed starship.toml has no color_orange or color_yellow in its palette" >&2; exit 1; }
      for c in $allColours; do
        if [[ $c == "$orange" || $c == "$yellow" ]]; then
          echo "starship-layers: the colour $c is the prompt's first segment's (color_orange $orange) or the directory's (color_yellow $yellow), which sit either side of a layer: its arrow would not show" >&2
          exit 1
        fi
      done

      # The arrow glyph is a private-use character: take it from the file, never type it.
      content=$(cat "$base")
      arrow=$(sed -nE 's/.*\$os\$username\[([^]]*)\]\(bg:color_yellow fg:color_orange\)\$directory.*/\1/p' "$base")
      old="\$os\$username[$arrow](bg:color_yellow fg:color_orange)\$directory"
      if [[ -z $arrow || $content != *"$old"* ]]; then
        echo "starship-layers: the deployed starship.toml's format no longer has the first segment followed by the directory as it did (\$os\$username[arrow](bg:color_yellow fg:color_orange)\$directory); the preset changed, or programs.starship.settings.format was set. Turn dots.shell.starship.layers.enable off or update this module." >&2
        exit 1
      fi
      rest=''${content#*"$old"}
      if [[ $rest == *"$old"* ]]; then
        echo "starship-layers: that part of the format occurs twice in the deployed starship.toml" >&2
        exit 1
      fi

      mkdir -p $out/variants

      # gen NAME (COLOUR SYMBOL TEXT)...: the config with those segments, outermost first,
      # between the first segment and the directory.
      gen() {
        local name=$1; shift
        local new="\$os\$username" prev=color_orange
        while (( $# )); do
          new+="[$arrow](bg:$1 fg:$prev)[ $2 $3 ](bg:$1 fg:color_fg0)"
          prev=$1
          shift 3
        done
        new+="[$arrow](bg:color_yellow fg:$prev)\$directory"
        printf '%s\n' "''${content/"$old"/"$new"}" > "$out/variants/$name.toml"
      }

      ${lib.concatMapStringsSep "\n" gen variants}

      cat ${data} > $out/data.zsh
      printf '_dots_layers_dir=%s\n' "$out/variants" >> $out/data.zsh
      cp ${./layers.zsh} $out/layers.zsh
    '';
in {
  options.dots.shell.starship.layers = {
    enable =
      lib.mkEnableOption "a prompt segment for each nix-shell, nix develop and direnv layer the shell is in"
      // {default = true;};

    maxShown = lib.mkOption {
      type = lib.types.ints.between 1 2;
      default = 2;
      description = ''
        How many layers are shown, the innermost ones. Nested layers are shown side by side
        and the colour rule looks at all of them, shown or not. Each shown depth multiplies
        the number of generated starship configs (one per state of the prompt), so it stops
        at two.
      '';
    };

    kinds = lib.mkOption {
      type = lib.types.submodule {
        options = {
          nix-shell = kindOption {
            symbol = glyph "F120";
            text = "shell";
            colors = ["#b16286" "#cc241d"];
          } "a `nix-shell` (also `nix-shell --pure`)";
          nix-develop = kindOption {
            symbol = glyph "F0AD";
            text = "dev";
            colors = ["#458588" "#689d6a"];
          } "a `nix develop`";
          direnv = kindOption {
            symbol = glyph "ED75";
            text = "env";
            colors = ["#98971a" "#689d6a"];
          } "a directory whose `.envrc` direnv has loaded (it comes and goes as you `cd`, and wins over the `nix develop` reading, which a `use flake` directory has exactly)";
        };
      };
      default = {};
      description = ''
        The symbol, text and colours of each kind of layer. A `nix shell` (the newer command)
        sets nothing that marks it and is not covered.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      description = "The generated starship configs (variants/NAME.toml), data.zsh and the hook, layers.zsh.";
    };
  };

  config = lib.mkIf (config.dots.shell.enable && cfg.enable) {
    dots.shell.starship.layers.package = package;

    assertions =
      lib.mapAttrsToList (kind: k: {
        assertion = lib.length (lib.unique (colours k)) >= 2;
        message = "dots.shell.starship.layers.kinds.${kind}.colors needs at least two different colours: a nested layer of the same kind takes the next one, so that it does not look like its parent.";
      })
      kinds;

    # After the starship and direnv hooks (both at the default order), so that direnv has
    # loaded or unloaded by the time the prompt's config is chosen.
    programs.zsh.initContent = lib.mkOrder 1500 ''
      source ${package}/data.zsh
      source ${package}/layers.zsh
    '';
  };
}
