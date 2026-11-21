{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.nvim.enable {
    xdg.configFile."nvim/lua/lang/go.lua".source = ./go.lua;
    programs.neovim.initLua = lib.mkAfter "require('lang.go')";
  };
}
