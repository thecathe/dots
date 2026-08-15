{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    yzhang.markdown-all-in-one
  ];
  settings = {
    "[markdown]" = {
      "editor" = {
        "tabSize" = 4;
        "indentSize" = "tabSize";
        "detectIndentation" = false;
        "foldingStrategy" = "indentation";
        "wordWrap" = "on";
      };
      "markdown" = {
        "extension" = {
          "list.indentationSize" = "inherit";
          "toc.orderedList" = true;
          "print.pureHtml" = true;
        };
        "preview" = {
          "fontFamily" = "UbuntuSans Nerd Font";
          "fontSize" = 16.0;
        };
      };
    };
  };
}
