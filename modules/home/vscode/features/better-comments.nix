{pkgs, ...}: {
  extensions = [pkgs.vscode-extensions.aaron-bond.better-comments];
  settings = {
    "better-comments.tags" = [
      {
        "tag" = "!";
        "color" = "#FF2D00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "?";
        "color" = "#3498DB";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "*";
        "color" = "#98C379";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "~";
        "color" = "#44CCBB";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "&";
        "color" = "#4f44cc";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "$";
        "color" = "#9844cc";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "£";
        "color" = "#cc8a44";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      # {
      #   "tag" = "//";
      #   "color" = "#474747";
      #   "strikethrough" = true;
      #   "underline" = false;
      #   "backgroundColor" = "transparent";
      #   "bold" = false;
      #   "italic" = false;
      # }
      {
        "tag" = "todo";
        "color" = "#FF8C00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "bug";
        "color" = "#FF5E00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "hack";
        "color" = "#0062FF";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "fixme";
        "color" = "#FFCC00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "rewrite";
        "color" = "#FFCC55";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
    ];
  };
}
