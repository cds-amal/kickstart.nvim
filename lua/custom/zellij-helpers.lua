-- Helper commands for working with Zellij when OSC52 doesn't work
local M = {}

function M.setup()
  if not vim.env.ZELLIJ then
    return
  end
  
  -- Command to show yanked text for manual copying
  vim.api.nvim_create_user_command('YankShow', function()
    local content = vim.fn.getreg('"')
    if content and content ~= '' then
      -- Show in a floating window
      local lines = vim.split(content, '\n')
      table.insert(lines, 1, '=== Yanked Text ===')
      table.insert(lines, '')
      table.insert(lines, 'Use Ctrl+Shift+Space to enter Zellij copy mode')
      table.insert(lines, 'Then select this text to copy')
      
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      
      local width = math.min(80, math.max(20, math.max(unpack(vim.tbl_map(function(line) return #line end, lines)))) + 4)
      local height = math.min(20, #lines + 2)
      
      local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
        style = 'minimal',
        border = 'rounded',
        title = ' Yanked Content ',
        title_pos = 'center',
      }
      
      local win = vim.api.nvim_open_win(buf, true, opts)
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
      
      -- Make text selectable
      vim.api.nvim_win_set_option(win, 'cursorline', true)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    else
      vim.notify('Nothing yanked', vim.log.levels.WARN)
    end
  end, { desc = 'Show yanked text in a window for Zellij copy mode' })
  
  -- Add keybinding for quick access
  vim.keymap.set('n', '<leader>ys', ':YankShow<CR>', { desc = '[Y]ank [S]how - display yanked text' })
  
  -- Auto-command to remind about Zellij copy mode after yanking
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('zellij-yank-notify', { clear = true }),
    callback = function()
      if vim.v.event.operator == 'y' and #vim.v.event.regcontents > 0 then
        vim.notify('Yanked! Use <leader>ys to show or Ctrl+Shift+Space for Zellij copy', vim.log.levels.INFO)
      end
    end,
  })
end

return M