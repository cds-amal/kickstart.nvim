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

-- Define the :Messages command
vim.api.nvim_create_user_command('Messages', M.Messages, {})

return M
