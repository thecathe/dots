# The prompt's palette, in one place. Starship draws every segment from it: starship.nix hands
# it to starship as `[palettes.gruvbox_dark]`, which is the name the gruvbox-rainbow preset
# uses, so these entries replace the preset's (the first ten are the preset's own values, so
# the prompt looks the same) and add the faded ones. The layer and ssh segments
# (starship-layers/defaults.nix) take their colours from it by name, so there is one list of
# colours to look at, and to change. Both can still use a literal "#rrggbb" instead.
#
# This file is only what applies when nothing overrides it: `dots.shell.starship.palette`
# (a host's own entries are added to these, and replace one of the same name).
#
# The names are starship's: a segment uses `bg:color_faded_red`. Gruvbox has three tiers of
# each accent (bright, neutral, faded); the preset uses the neutral one, and the faded
# entries below are the expansion points, added where the prompt has room for a darker
# shade. To add another, copy it from gruvbox (the faded tier: red 9d0006, green 79740e,
# yellow b57614, blue 076678, purple 8f3f71, aqua 427b58, orange af3a03) and give it a
# `color_faded_*` name. Contrast of the segment text (`color_fg0`) on a colour: faded
# ones 4.3 to 7.6, neutral ones 2.2 to 4.8.
{
  # Text, and the two dark greys of the context and time segments.
  color_fg0 = "#fbf1c7";
  color_bg1 = "#3c3836";
  color_bg3 = "#665c54";

  # The spectrum, in the order it runs along the prompt: the first segment is orange and the
  # directory is yellow, and what sits between them (the ssh and layer segments) draws from
  # the faded orange and red; the faded green sits between the yellow and the green.
  color_orange = "#d65d0e";
  color_faded_orange = "#af3a03";
  color_faded_red = "#9d0006";
  color_yellow = "#d79921";
  color_faded_green = "#79740e";
  color_green = "#98971a";
  color_aqua = "#689d6a";
  color_blue = "#458588";

  # In the preset but on no segment: only the `❯` character uses them.
  color_purple = "#b16286";
  color_red = "#cc241d";
}
