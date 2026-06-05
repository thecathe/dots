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

