{ pkgs, ... }:
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

      nix_shell = {
        format = "[$symbol$state( ($name))]($style) ";
        disabled = false;
        impure_msg = "[impure](bold red)";
        pure_msg = "[pure](bold green)";
        style = "bold blue";
        symbol = " ";
      };

      ocaml = {
        format = "[$symbol($version )(($switch_indicator$switch_name) )]($style)";
        global_switch_indicator = "";
        local_switch_indicator = "*";
        style = "bold yellow";
        symbol = "🐫 ";
        version_format = "v$raw";
        disabled = false;
        detect_extensions = [
          "opam"
          "ml"
          "mli"
          "re"
          "rei"
        ];
        detect_files = [
          "dune"
          "dune-project"
          "jbuild"
          "jbuild-ignore"
          ".merlin"
        ];
        detect_folders = [
          "_opam"
          "esy.lock"
        ];
      };
    };
  };
}
