{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.nvim.enable {
    xdg.configFile."nvim/lua/lang/erlang.lua".source = ./erlang.lua;
    programs.neovim.initLua = lib.mkAfter "require('lang.erlang')";
  };
}
