{ ... }:
{
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
}
