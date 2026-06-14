{pkgs, ...}: {
  imports = [
    ./lang
  ];

  xdg.configFile = {
    "nvim/lua/options.lua".source = ./lua/options.lua;
    "nvim/lua/lsp.lua".source = ./lua/lsp.lua;
    "nvim/lua/diagnostics.lua".source = ./lua/diagnostics.lua;
    "nvim/lua/utils.lua".source = ./lua/utils.lua;
    "nvim/lua/config/conform.lua".source = ./lua/config/conform.lua;
    "nvim/lua/config/bufferline.lua".source = ./lua/config/bufferline.lua;
    "nvim/lua/config/blink-cmp.lua".source = ./lua/config/blink-cmp.lua;
    "nvim/lua/config/render-markdown.lua".source = ./lua/config/render-markdown.lua;
    "nvim/lua/config/resession.lua".source = ./lua/config/resession.lua;
    "nvim/lua/config/mini.lua".source = ./lua/config/mini.lua;
    "nvim/lua/config/snacks.lua".source = ./lua/config/snacks.lua;
    # "nvim/lua/config/treesitter.lua".source = ./lua/config/treesitter.lua;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Tools that are truly global — i.e. not version-coupled to a project.
    # Language-specific LSP servers (ocamllsp, erlang_ls) belong in your
    # project devShells so direnv can put the right version on PATH.
    extraPackages = with pkgs; [
      git
      ### nix
      nix
      nixd
      alejandra
      nix-search-cli
      nix-index
      ### latex
      # texlab
      # tectonic
      # zathura ## pdf viewer
      ### lua formatter
      stylua
    ];

    plugins = with pkgs.vimPlugins; [
      #### basics
      direnv-vim
      vim-fugitive
      vim-gitgutter
      nvim-lspconfig

      lazygit-nvim
      lazydocker-nvim

      #### theme
      {
        plugin = gruvbox-nvim;
        type = "lua";
        config = ''
          require("gruvbox").setup({
            contrast = "hard", -- or "soft"
          })
          vim.cmd("colorscheme gruvbox")
        '';
      }

      #### bundles
      {
        plugin = mini-nvim;
        type = "lua";
        config = "require('config.mini')";
      }
      {
        plugin = snacks-nvim;
        type = "lua";
        config = "require('config.snacks')";
      }

      #### show keymaps
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          require('which-key').setup({ delay = 500 })
        '';
      }

      #### treesitter
      {
        plugin = nvim-treesitter.withPlugins (
          p:
            with p; [
              tree-sitter-nix
              tree-sitter-lua
              #
              tree-sitter-ocaml
              tree-sitter-ocaml-interface
              tree-sitter-erlang
              tree-sitter-markdown
              tree-sitter-markdown-inline
              tree-sitter-go
              tree-sitter-python
              tree-sitter-sql
              # tree-sitter-haskell
              # tree-sitter-java
              # tree-sitter-rust
              # tree-sitter-menhir
              #
              tree-sitter-ini
              tree-sitter-toml
              tree-sitter-yaml
              tree-sitter-xml
              tree-sitter-csv
              tree-sitter-regex
              #
              tree-sitter-gitignore
              tree-sitter-dockerfile
              #
              tree-sitter-kitty
              tree-sitter-zsh
              tree-sitter-tmux
              #
              tree-sitter-bash
              tree-sitter-make
              #
              tree-sitter-html
              tree-sitter-javascript
              tree-sitter-css
              # tree-sitter-php
              tree-sitter-json
              #
              tree-sitter-typescript
              tree-sitter-json5
              #
              tree-sitter-latex
              tree-sitter-bibtex
              #
              # tree-sitter-julia
              # tree-sitter-arduino
            ]
        );
        type = "lua";
        config = "require('nvim-treesitter').setup()";
      }
      nvim-treesitter-textobjects

      #### sessions
      {
        plugin = resession-nvim;
        type = "lua";
        config = "require('config.resession')";
      }

      #### formatting
      {
        plugin = conform-nvim;
        type = "lua";
        config = "require('config.conform')";
      }

      #### completion
      {
        plugin = blink-cmp;
        type = "lua";
        config = "require('config.blink-cmp')";
      }
      blink-emoji-nvim

      #### visual
      # blink-pairs
      {
        plugin = render-markdown-nvim;
        type = "lua";
        config = "require('config.render-markdown')";
      }

      # ── Project-local overrides (.neoconf.json) ─────────────────────────
      # Lets you drop a .neoconf.json in a project root to override LSP
      # settings without touching this config. Must be set up before lspconfig.
      {
        plugin = neoconf-nvim;
        type = "lua";
        config = ''
          require('neoconf').setup()
        '';
      }

      #### bufferline
      {
        plugin = bufferline-nvim;
        type = "lua";
        config = "require('config.bufferline')";
      }

      #### lualine
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup({ options = { theme = 'auto' } })
        '';
      }

      #### cursor
      {
        plugin = smear-cursor-nvim;
        type = "lua";
        config = ''
          require('smear_cursor').setup()
        '';
      }
    ];

    initLua = ''
      require('options')
      require('lsp')
      require('diagnostics')
      require('utils')
    '';
  };
}
