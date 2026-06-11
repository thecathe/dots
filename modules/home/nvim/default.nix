{ pkgs,... }:

{
  imports = [
    ./lang
  ];

  xdg.configFile = {
    "nvim/lua/options.lua".source = ./lua/options.lua;
    "nvim/lua/lsp.lua".source = ./lua/lsp.lua;
    "nvim/lua/diagnostics.lua".source = ./lua/diagnostics.lua;
    "nvim/lua/config/snacks.lua".source = ./lua/config/snacks.lua;
    "nvim/lua/config/blink-cmp.lua".source = ./lua/config/blink-cmp.lua;
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
      nix
      # nil # Nix LSP
      nixd
      # nixfmt
      alejandra
      nix-search-cli
      nix-index
    ];

    plugins = with pkgs.vimPlugins; [

      # ── Dependencies ────────────────────────────────────────────────────
      # plenary-nvim # lua library

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

      # ── Snacks (replaces telescope; add before other plugins) ────────────
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

      gitignore-nvim # git ignore

      {plugin =direnv-vim;}

      # ── LSP ─────────────────────────────────────────────────────────────
      nvim-lspconfig

      # ── Completion ──────────────────────────────────────────────────────
      {
        plugin = blink-cmp;
        type   = "lua";
        config = "require('config.blink-cmp')";
      }
      {
        plugin = blink-emoji-nvim;
        type = "lua";
#        config = 
      }
  

      # ── Treesitter ──────────────────────────────────────────────────────
      # Add grammars here as you add languages. LaTeX is omitted because
      # vimtex (in latex.nix) handles highlighting better for that filetype.
      {
        plugin = nvim-treesitter.withPlugins (
          p: with p; [
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

      # ── Formatting ──────────────────────────────────────────────────────
      # Language modules register their formatters via:
      #   require('conform').formatters_by_ft.<ft> = { 'tool' }
      # after this setup() call, using lib.mkAfter in their initLua.
      {
        plugin = conform-nvim;
        type = "lua";
        config = ''
          require('conform').setup({
            format_on_save = {
              timeout_ms   = 500,
              lsp_fallback = true,
            },
          })
        '';
      }

      # ── Fuzzy Finding ───────────────────────────────────────────────────
      # {
      #   plugin = telescope-nvim;
      #   type = "lua";
      #   config = ''
      #     local telescope = require('telescope')
      #     local builtin   = require('telescope.builtin')
      #     telescope.setup({})
      #     vim.keymap.set('n', '<leader>ff', builtin.find_files,   { desc = 'Find files' })
      #     vim.keymap.set('n', '<leader>fg', builtin.live_grep,    { desc = 'Live grep' })
      #     vim.keymap.set('n', '<leader>fb', builtin.buffers,      { desc = 'Find buffers' })
      #     vim.keymap.set('n', '<leader>fd', builtin.diagnostics,  { desc = 'Diagnostics' })
      #     vim.keymap.set('n', '<leader>fr', builtin.lsp_references, { desc = 'LSP references' })
      #   '';
      # }

      # ── File Navigation ─────────────────────────────────────────────────
      {
        plugin = oil-nvim;
        type = "lua";
        config = ''
          require('oil').setup({ default_file_explorer = true })
          vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })
        '';
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
  type   = "lua";
  config = ''
    require('smear_cursor').setup()
  '';
}

      # ── Colourscheme ─────────────────────────────────────────────────────
      # Uncomment one and add the colorscheme call in initLua below.
      # catppuccin-nvim
      # tokyonight-nvim
      gruvbox-nvim
    ];

    initLua = ''
      require('options')
      require('lsp')
      require('diagnostics')
    '';
  };
}
