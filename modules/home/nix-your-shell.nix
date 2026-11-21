# Stay in zsh inside `nix-shell` and `nix develop`. Both start bash whatever
# $SHELL says (nix-shell builds a bash rcfile), so an interactive one dropped
# into bash, without the prompt, keys or suggestions configured here.
# nix-your-shell defines `nix` and `nix-shell` functions in interactive zsh that
# rerun them with the current shell; scripts, shebangs and `--run`/`--command`
# are untouched. `command nix-shell ...` bypasses the wrapper.
{
  config,
  lib,
  ...
}: {
  options.dots.nixYourShell.enable = lib.mkEnableOption "nix-your-shell, which keeps zsh inside nix-shell and nix develop" // {default = true;};

  config = lib.mkIf config.dots.nixYourShell.enable {
    programs.nix-your-shell.enable = true;
  };
}
