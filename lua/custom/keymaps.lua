local function clean_buffer()
  local cmds = {
    -- Add a line break after 'Chain sepolia'
    [[%s/\(Chain sepolia\)/\1\r/g]],

    -- Add a line break before arrows
    [[%s/\(→\)/\r\1/g]],

    -- Remove lines that only contain whitespace
    [[%s/^\s\+$//g]],

    -- Replace multiple spaces with a single space
    [[%s/\s\+/ /g]],

    -- Remove leading spaces before checkmarks
    [[%s/^\s\+✓/✓/g]],

    -- Replace a specific status line
    [[%s/^→ Pending...Checking/→ Checking/g]],

    -- Normalize repeated "Confirmed Confirmed"
    [[%s/✓ Confirmed Confirmed /✓ Confirmed Confirmed /g]],
    [[%s/✓ Confirmed Confirmed /\r✓ Confirmed /g]],

    -- Delete lines starting with two characters and "Pending"
    [[g/^..Pending/d]],

    -- Replace blank lines (multiple newlines) with a single newline
    [[%s/^\n\+/\r/g]],
  }

  for _, cmd in ipairs(cmds) do
    vim.cmd(cmd)
  end
end

-- Lint keymaps
vim.keymap.set('n', '<leader>ll', function()
  require('lint').try_lint()
end, { desc = '[L]int current buffer' })

-- Tdo (todo) keymaps for markdown files in ~/NOTES
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*/NOTES/*.md', '*/NOTES/*.markdown' },
  callback = function()
    vim.keymap.set('n', '<Space>', ':Tdo toggle<CR>', {
      buffer = true,
      desc = 'Toggle todo state',
      silent = true,
    })
  end,
  desc = 'Set spacebar to toggle todos in NOTES markdown files',
})
