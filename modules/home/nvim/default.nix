{pkgs, ...}: {
  imports = [
    ./lang
  ];

  xdg.configFile = {
    "nvim/lua/options.lua".source = ./lua/options.lua;
    "nvim/lua/lsp.lua".source = ./lua/lsp.lua;
    "nvim/lua/diagnostics.lua".source = ./lua/diagnostics.lua;
    "nvim/lua/config/conform.lua".source = ./lua/config/conform.lua;
    "nvim/lua/config/bufferline.lua".source = ./lua/config/bufferline.lua;
    "nvim/lua/config/blink-cmp.lua".source = ./lua/config/blink-cmp.lua;
    "nvim/lua/config/resession.lua".source = ./lua/config/resession.lua;
    "nvim/lua/config/mini.lua".source = ./lua/config/mini.lua;
    "nvim/lua/config/snacks.lua".source = ./lua/config/snacks.lua;
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
      # ── Dependencies ────────────────────────────────────────────────────

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

      # show keymaps
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          require('which-key').setup({ delay = 500 })
        '';
      }

      {
        plugin = gruvbox-nvim;
        type = "lua";
        config = ''
          require("gruvbox").setup({
            contrast = "hard", -- or "soft", depending on your taste
          })
          vim.cmd("colorscheme gruvbox")
        '';
      }
      {
        plugin = bufferline-nvim;
        type = "lua";
        config = "require('config.bufferline')";
      }

      direnv-vim
      vim-gitgutter

      # ── LSP ─────────────────────────────────────────────────────────────
      nvim-lspconfig

      ## sessions
      {
        plugin = resession-nvim;
        type = "lua";
        config = "require('config.resession')";
      }

      # ── Completion ──────────────────────────────────────────────────────
      {
        plugin = blink-cmp;
        type = "lua";
        config = "require('config.blink-cmp')";
      }
      blink-emoji-nvim

      # ── Treesitter ──────────────────────────────────────────────────────
      # Add grammars here as you add languages. LaTeX is omitted because
      # vimtex (in latex.nix) handles highlighting better for that filetype.
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
        config = ''
          require('nvim-treesitter.configs').setup({
            highlight = { enable = true },
            indent    = { enable = true },
          })
        '';
      }
      nvim-treesitter-textobjects

      # ── Formatting ──────────────────────────────────────────────────────
      # Language modules register their formatters via:
      #   require('conform').formatters_by_ft.<ft> = { 'tool' }
      # after this setup() call, using lib.mkAfter in their initLua.
      {
        plugin = conform-nvim;
        type = "lua";
        config = "require('config.conform')";
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

      # ── Statusline ──────────────────────────────────────────────────────
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup({ options = { theme = 'auto' } })
        '';
      }

      {
        plugin = smear-cursor-nvim;
        type = "lua";
        config = ''
          require('smear_cursor').setup()
        '';
      }

      # ── Colourscheme ─────────────────────────────────────────────────────
      # Uncomment one and add the colorscheme call in initLua below.
      # catppuccin-nvim
      # tokyonight-nvim
      #      gruvbox-nvim
    ];

    initLua = ''
      require('options')
      require('lsp')
      require('diagnostics')
    '';
  };
}
