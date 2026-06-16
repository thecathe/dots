{...}: {
  ## pdf reader
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard"; # copy to system clipboard
      recolor = false; # dark mode
    };
  };
}
