local opt = vim.opt
opt.number         = true
opt.relativenumber = true
opt.tabstop        = 2     -- tab size
opt.shiftwidth     = 2     -- indentation size
opt.smarttab       = true  -- tab snaps to next indent
opt.expandtab      = true  -- replace tab with spaces
opt.termguicolors  = true
opt.signcolumn     = 'yes'   -- always show, prevents layout shifts
opt.updatetime     = 250     -- faster CursorHold (used by LSP hover)
opt.splitright     = true
opt.splitbelow     = true
opt.undofile       = true    -- persistent undo across sessions

--vim.cmd.colorscheme('gruvbox')

vim.keymap.set('n', '<leader>w+', '5<C-w>>', { desc = 'Widen window' })
vim.keymap.set('n', '<leader>w-', '5<C-w><', { desc = 'Narrow window' })

-- format 
vim.keymap.set('n', '<leader>f', function()
  require('conform').format({ async = true })
end, { desc = 'Format buffer' })
