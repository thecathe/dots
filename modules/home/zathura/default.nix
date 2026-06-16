{...}: {
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard"; # copy to system clipboard
      recolor = true; # dark mode recolour (optional)
    };
  };
}
