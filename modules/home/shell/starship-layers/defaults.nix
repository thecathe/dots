# What the prompt's layer segments look like when nothing overrides it: the symbols, the short
# words and the colours, kept apart from the machinery in default.nix so that they are easy to
# change for yourself. default.nix takes every default of the options
# `dots.shell.starship.layers.*` from here; a host can still override any of them (set the
# option in its home configuration), and this file is only what applies when it does not.
#
# Symbols: a Nerd Font glyph, written literally or by codepoint with `glyph "F120"` (hex digits
# without the U+; a codepoint above FFFF, the Material icons, works too). Private-use glyphs
# often do not survive a chat or an editor, so the codepoint is the safe way.
#
# Colours: names of the prompt's palette, which starship draws every segment from too (the
# list is in ../palette.nix, one level up, and a host can add to it with
# `dots.shell.starship.palette`), or a literal "#rrggbb". Each kind needs two different ones,
# the second for a layer nested in another of the same kind (a layer takes the first colour of
# its kind's list that differs from the layer outside it). The ssh colour may be no layer's.
# None may be the prompt's first segment's (`color_orange`) or the directory's
# (`color_yellow`), which sit either side; whichever rule is broken, the build says so.
#
# The layers sit between that orange and yellow, so they take the warm, faded end of the
# palette: faded orange (ssh), faded red (a nix-shell), faded green (direnv).
#
# Strings may not contain any of `[ ] ( ) $ \ "`, which a starship format reads.
{glyph}: {
  # How many layers are shown, the innermost ones (1 or 2).
  maxShown = 2;

  kinds = {
    # `nix-shell`, also `nix-shell --pure`.
    nix-shell = {
      symbol = glyph "F120";
      text = "";
      colors = ["color_faded_red" "color_red"];
    };
    # `nix develop`.
    nix-develop = {
      symbol = glyph "F0AD";
      text = "dev";
      colors = ["color_blue" "color_aqua"];
    };
    # A directory whose `.envrc` direnv manages (also one that is not allowed: direnv sets
    # the same variables for it).
    direnv = {
      symbol = glyph "ED75";
      text = "env";
      colors = ["color_faded_green" "color_green"];
    };
  };

  # While the shell is in an ssh session, on the machine you ssh into.
  ssh = {
    symbol = glyph "F031A";
    text = "ssh";
    color = "color_faded_orange";

    # Machines that show something other than `text`, by their own short host name in lower
    # case (the prompt is drawn on the machine you ssh into, so this table can be the same
    # on every machine). Each is `{}` (shows its host name after the symbol), or sets `text`
    # and/or `symbol`. For example:
    #   worklaptop.text = "work";
    #   nixos-laptop = {};
    #   cluster1 = {symbol = "C"; text = "cluster";};
    hosts = {
      worklaptop.text = "worklaptop";
      nixos.text = "nixos";
      nixos-laptop.text = "nixos-laptop";
    };
  };
}
