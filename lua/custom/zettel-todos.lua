-- Custom todo aggregation for Zettelkasten notes
local M = {}

-- Find all todos across the vault
M.find_todos = function()
  require('telescope.builtin').live_grep {
    prompt_title = 'Zettelkasten TODOs',
    cwd = vim.fn.expand '~/zettelkasten',
    default_text = '- \\[ \\]', -- Search for incomplete checkboxes
    additional_args = function()
      return { '--no-ignore' } -- Include all files
    end,
  }
end

-- Find completed todos
M.find_completed = function()
  require('telescope.builtin').live_grep {
    prompt_title = 'Zettelkasten Completed',
    cwd = vim.fn.expand '~/zettelkasten',
    default_text = '- \\[x\\]', -- Search for completed checkboxes
    additional_args = function()
      return { '--no-ignore' }
    end,
  }
end

-- Find all todos (completed and incomplete)
M.find_all_tasks = function()
  require('telescope.builtin').live_grep {
    prompt_title = 'Zettelkasten All Tasks',
    cwd = vim.fn.expand '~/zettelkasten',
    default_text = '- \\[', -- Search for any checkbox
    additional_args = function()
      return { '--no-ignore' }
    end,
  }
end

-- Find todos with specific tag
M.find_tagged_todos = function()
  vim.ui.input({ prompt = 'Tag: ' }, function(tag)
    if tag then
      require('telescope.builtin').live_grep {
        prompt_title = 'Tagged TODOs (#' .. tag .. ')',
        cwd = vim.fn.expand '~/zettelkasten',
        default_text = '- \\[ \\].*#' .. tag,
        additional_args = function()
          return { '--no-ignore' }
        end,
      }
    end
  end)
end

-- Advanced: Parse all todos into a quickfix list
M.todos_to_quickfix = function()
  local vault_path = vim.fn.expand '~/zettelkasten'

  -- Use ripgrep to find all incomplete todos
  local cmd = string.format(
    'rg --vimgrep "- \\[ \\]" %s',
    vault_path
  )

  local todos = {}
  local output = vim.fn.systemlist(cmd)

  for _, line in ipairs(output) do
    -- Parse ripgrep output: filename:line:col:text
    local filename, lnum, col, text = line:match '([^:]+):(%d+):(%d+):(.*)'
    if filename then
      table.insert(todos, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = vim.trim(text),
      })
    end
  end

  -- Set quickfix list
  vim.fn.setqflist(todos)
  vim.cmd 'copen' -- Open quickfix window

  print(string.format('Found %d incomplete todos', #todos))
end

return M
