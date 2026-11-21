{
  config,
  lib,
  options,
  pkgs,
  ...
}: {
  # Where stylix's home-manager module comes from depends on how home-manager
  # runs, so `homeModules.default` does not import it (flake.nix says why). When
  # it is absent the theming is skipped and the build says so, instead of failing
  # on options that do not exist.
  options.dots.stylix.enable = lib.mkEnableOption "stylix theming (colours, fonts and the per-application targets)" // {default = true;};

  config = lib.mkIf config.dots.stylix.enable (lib.mkMerge [
    {
      warnings = lib.optional (!(options ? stylix)) ''
        dots: stylix's home-manager module is not imported, so the theme is skipped.
        Import inputs.stylix.homeModules.stylix (dots.lib.mkHome does), or run
        home-manager through a NixOS system that enables stylix.
      '';
    }
    (lib.optionalAttrs (options ? stylix) {
      stylix = {
        enable = true;
        autoEnable = true;
        polarity = "dark";
        targets = {
          firefox.profileNames = [config.dots.firefox.profile];
          kitty.enable = true;
          ## disable
          starship.enable = false;
          # neovim.enable = false;
          zathura.enable = false;
          ## disable for gnome
          gnome.enable = false;
          gtk.enable = false;
          ## gnome-shell.enable = false;
          vscode.enable = false;
        };

        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

        #base16Scheme = {
        #  base00 = "282828"; # bg ----
        #  base01 = "3c3836"; # bg ---
        #  base02 = "504945"; # bg --
        #  base03 = "665c54"; # bg -
        #  base04 = "bdae93"; # fg +
        #  base05 = "d5c4a1"; # fg ++
        #  base06 = "ebdbb2"; # fg +++
        #  base07 = "fbf1c7"; # fg ++++
        #  base08 = "cc241d"; # red
        #  base09 = "d65d0e"; # orange
        #  base0A = "d79921"; # yellow
        #  base0B = "98971a"; # green
        #  base0C = "689d6a"; # aqua
        #  base0D = "458588"; # blue
        #  base0E = "b16286"; # purple
        #  base0F = "d65d0e"; # brown
        #};

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
            #        package = pkgs.nerd-fonts.fira-code;
            #        name = "FiraCode Nerd Font Mono";
          };
          sansSerif = {
            package = pkgs.nerd-fonts.ubuntu-sans;
            name = "UbuntuSans Nerd Font";
          };
          serif = {
            package = pkgs.nerd-fonts.ubuntu;
            name = "Ubuntu Nerd Font";
          };
        };
      };
    })
  ]);
}
