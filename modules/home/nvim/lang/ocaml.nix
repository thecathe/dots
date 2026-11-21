{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.nvim.enable {
    xdg.configFile."nvim/lua/lang/ocaml.lua".source = ./ocaml.lua;
    programs.neovim.initLua = lib.mkAfter "require('lang.ocaml')";
  };
}
