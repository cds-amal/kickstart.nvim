local M = {}

-- Function to display messages in the quickfix window
M.Messages = function()
  -- Get the messages using the `:messages` command
  local messages = vim.fn.execute 'messages'
  local lines = vim.split(messages, '\n') -- Split the messages into lines

  -- Create a list of quickfix items
  local items = {}
  for i, line in ipairs(lines) do
    table.insert(items, {
      filename = '', -- No filename associated with the message
      lnum = i, -- Line number, here we're just using the index
      col = 0, -- Column is not used, set to 0
      text = line, -- The message content
    })
  end

  -- Set the quickfix list with the messages
  vim.fn.setqflist({}, 'r', { items = items })

  -- Open the quickfix window
  vim.cmd 'copen'
end

local function toggle_zoom()
  local current_win = vim.api.nvim_get_current_win()

  -- Check if we already have zoom state for this window
  if vim.w[current_win].zoomed then
    -- Restore the previous window layout
    local cmd = vim.w[current_win].zoom_restore
    vim.cmd(cmd)
    vim.w[current_win].zoomed = false
  else
    -- Save current window layout
    vim.w[current_win].zoom_restore = vim.fn.winrestcmd()

    -- Maximize the window
    vim.cmd 'resize'
    vim.cmd 'vertical resize'
    vim.w[current_win].zoomed = true
  end
end

-- Define the :Messages command
-- vim.api.nvim_create_user_command('Messages', M.Messages, {})
vim.keymap.set('n', '<leader>M', M.Messages, { noremap = true, silent = true, desc = 'See last [M]essage' })

-- Set a keymapping to toggle zoom
vim.keymap.set('n', '<leader>z', toggle_zoom, { noremap = true, silent = true, desc = 'Toggle window zoom' })
return M
