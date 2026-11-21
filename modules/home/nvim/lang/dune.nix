{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.nvim.enable {
    xdg.configFile."nvim/lua/lang/dune.lua".source = ./dune.lua;
    programs.neovim.initLua = lib.mkAfter "require('lang.dune')";
  };
}
