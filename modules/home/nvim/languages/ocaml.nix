{ lib, ... }:
{
  xdg.configFile."nvim/lua/lang/ocaml.lua".source = ./ocaml.lua;
  programs.neovim.initLua = lib.mkAfter "require('lang.ocaml')";
}
