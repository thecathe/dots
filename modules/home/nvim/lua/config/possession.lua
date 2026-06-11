require('possession').setup({
  session_dir = get_session_dir(),
  -- rest of config...
})

vim.api.nvim_create_autocmd('VimEnter', {
  nested = true,
  callback = function()
    if vim.fn.argc() ~= 0 then return end

    local session_dir = require('possession.config').session_dir
    local sessions = vim.fn.glob(session_dir .. '/*.json', false, true)

    if #sessions == 0 then return end

    if #sessions == 1 then
      local name = vim.fn.fnamemodify(sessions[1], ':t:r')
      require('possession.session').load(name)
    else
      vim.cmd('SList')
    end
  end,
})
