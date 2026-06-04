{ pkgs, lib, ... }:

{
  imports = [
    ./languages
  ];

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

      # ── Snacks (replaces telescope; add before other plugins) ────────────
      {
        plugin = snacks-nvim;
        type = "lua";
        config = ''
          require('snacks').setup({
            picker    = { enabled = true },  -- replaces telescope
            explorer  = { enabled = true },  -- sidebar file tree
            terminal  = { enabled = true },  -- toggleable terminal
            notifier  = { enabled = true },  -- replaces vim.notify
            indent    = { enabled = true },  -- indent guides
            words     = { enabled = true },  -- highlight word under cursor
            quickfile = { enabled = true },  -- faster file loading
            bigfile   = { enabled = true },  -- disable heavy features on large files
          })

          -- Picker (replaces the telescope keymaps you had)
          vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files() end,            { desc = 'Find files' })
          vim.keymap.set('n', '<leader>fg', function() Snacks.picker.grep() end,             { desc = 'Grep' })
          vim.keymap.set('n', '<leader>fb', function() Snacks.picker.buffers() end,          { desc = 'Buffers' })
          vim.keymap.set('n', '<leader>fd', function() Snacks.picker.diagnostics() end,      { desc = 'Diagnostics' })
          vim.keymap.set('n', '<leader>fr', function() Snacks.picker.lsp_references() end,   { desc = 'LSP references' })
          vim.keymap.set('n', '<leader>fs', function() Snacks.picker.lsp_symbols() end,      { desc = 'LSP symbols' })

          -- Explorer
          vim.keymap.set('n', '<leader>e', function() Snacks.explorer() end, { desc = 'File explorer' })

          -- Terminal toggle
          vim.keymap.set('n', '<leader>t',   function() Snacks.terminal() end, { desc = 'Toggle terminal' })
          vim.keymap.set('t', '<Esc><Esc>',  '<C-\\><C-n>',                    { desc = 'Exit terminal mode' })
        '';
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

      # ── LSP ─────────────────────────────────────────────────────────────
      nvim-lspconfig

      # ── Completion ──────────────────────────────────────────────────────
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip

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

      # ── Colourscheme ─────────────────────────────────────────────────────
      # Uncomment one and add the colorscheme call in initLua below.
      # catppuccin-nvim
      # tokyonight-nvim
      gruvbox-nvim
    ];

    initLua = ''
      -- ── Options ───────────────────────────────────────────────────────────
      local opt = vim.opt
      opt.number         = true
      opt.relativenumber = true
      opt.tabstop        = 2
      opt.shiftwidth     = 2
      opt.expandtab      = true
      opt.termguicolors  = true
      opt.signcolumn     = 'yes'   -- always show, prevents layout shifts
      opt.updatetime     = 250     -- faster CursorHold (used by LSP hover)
      opt.splitright     = true
      opt.splitbelow     = true
      opt.undofile       = true    -- persistent undo across sessions

      vim.cmd.colorscheme('gruvbox')

      -- ── Shared LSP utilities ──────────────────────────────────────────────
      -- Exposed as _G globals so language modules (merged in via lib.mkAfter)
      -- can reference them without requiring a separate Lua module.

      _G.lsp_on_attach = function(_, bufnr)
        local o = { buffer = bufnr, silent = true }
        vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,        o)
        vim.keymap.set('n', 'gD',         vim.lsp.buf.declaration,       o)
        vim.keymap.set('n', 'gr',         vim.lsp.buf.references,        o)
        vim.keymap.set('n', 'gi',         vim.lsp.buf.implementation,    o)
        vim.keymap.set('n', 'K',          vim.lsp.buf.hover,             o)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,            o)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,       o)
        vim.keymap.set('n', '[d',         vim.diagnostic.goto_prev,      o)
        vim.keymap.set('n', ']d',         vim.diagnostic.goto_next,      o)
        vim.keymap.set('n', '<leader>f',  function()
          require('conform').format({ bufnr = bufnr })
        end, vim.tbl_extend('force', o, { desc = 'Format buffer' }))
      end

      _G.lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- ── nixd (Nix LSP) — always globally available ──────────────────────
      require('lspconfig').nixd.setup({
        on_attach    = lsp_on_attach,
        capabilities = lsp_capabilities,
        settings = {
          nixd = {
            formatting = { command = { 'alejandra' } },
            nixpkgs = {
              -- Lets nixd evaluate nixpkgs for accurate package completions
              expr = 'import <nixpkgs> { }',
            },
            options = {
              nixos = {
                expr = '(builtins.getFlake "/home/cathe/dots").nixosConfigurations.mymachine.options',
              },
              home_manager = {
                expr = '(builtins.getFlake "/home/cathe/dots").homeConfigurations.cathe.options',
              },
            },
          },
        },
      })

      -- ── Completion ────────────────────────────────────────────────────────
      local cmp     = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>']     = cmp.mapping.scroll_docs(-4),
          ['<C-f>']     = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>']     = cmp.mapping.abort(),
          -- Tab cycles through completion items and luasnip jump points
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
          -- Explicit confirm only; <CR> does not auto-select
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    '';
  };
}
