-- lua/custom/plugins/languages/zsh-utils.lua
-- Utility functions for ZSH file manipulation

local M = {}

-- Function to split zsh commands at dashes
function M.split_at_dashes(confirm)
  local pattern = [[\(\s\{1,}\)\(-\+\)]]
  local replacement = [[ \\\r  \2]]
  local flags = confirm and 'cg' or 'g'
  vim.cmd('s:' .. pattern .. ':' .. replacement .. ':' .. flags)
  vim.cmd 'noh | retab'
end

-- Function to join multiline commands using TreeSitter
function M.join_with_treesitter()
  -- Check if TreeSitter is available
  local has_parser, parser = pcall(vim.treesitter.get_parser, 0)
  if not has_parser or parser == nil then
    print 'TreeSitter parser not available'
    return
  end

  -- Get current cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1] - 1
  local col = cursor_pos[2]

  -- Find the current node at cursor position
  local current_node = vim.treesitter.get_node { pos = { row, col } }
  if not current_node then
    print 'No node found at cursor position'
    return
  end

  -- Find the command node by traversing up the tree
  local command_node = current_node

  -- Use a safer traversal approach with nil checks
  while command_node and command_node:type() ~= 'command' do
    local parent = command_node:parent()
    if not parent then
      break
    end
    command_node = parent
  end

  if not command_node or command_node:type() ~= 'command' then
    print 'No command node found'
    return
  end

  -- Get the range of the command node
  local start_row, _start_col, end_row, _end_col = command_node:range()

  -- Extract all arguments from the command
  local command_parts = {}

  -- Collect ALL parts
  for child in command_node:iter_children() do
    local child_text = vim.treesitter.get_node_text(child, 0)
    table.insert(command_parts, child_text)
  end

  -- Join all parts with a single space
  local joined_line = table.concat(command_parts, ' ')

  -- Replace the lines with the joined line
  vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, { joined_line })

  -- Position cursor at the beginning of the joined line
  vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
end

-- Function to split a command line intelligently
function M.split_command_line(line)
  local parts = {}
  local in_progress = ''
  local in_quotes = false
  local quote_char = nil

  for i = 1, #line do
    local char = line:sub(i, i)

    if (char == '"' or char == "'") and (i == 1 or line:sub(i - 1, i - 1) ~= '\\') then
      if not in_quotes then
        in_quotes = true
        quote_char = char
        in_progress = in_progress .. char
      elseif char == quote_char then
        in_quotes = false
        quote_char = nil
        in_progress = in_progress .. char
      else
        in_progress = in_progress .. char
      end
    elseif char == ' ' and not in_quotes then
      if in_progress ~= '' then
        table.insert(parts, in_progress)
        in_progress = ''
      end
    else
      in_progress = in_progress .. char
    end
  end

  if in_progress ~= '' then
    table.insert(parts, in_progress)
  end

  -- Create the split command with continuation characters
  local result = parts[1]
  for i = 2, #parts do
    result = result .. ' \\\n  ' .. parts[i]
  end

  return result
end

-- Toggle split/join functionality
function M.toggle_split_join()
  local line = vim.fn.getline '.'

  -- Check if current line or previous line has a continuation character
  if line:match '\\%s*$' or vim.fn.getline(vim.fn.line '.' - 1):match '\\%s*$' then
    -- If continuation character exists, join
    M.join_with_treesitter()
  else
    -- Otherwise, split
    local cmd = line
    -- Check if it has dashes with spaces before them
    if cmd:match '%s%-' then
      -- If it has dashes, use the dash-specific splitting
      M.split_at_dashes(false)
    else
      -- Otherwise use a more general approach for any command
      local result = M.split_command_line(cmd)
      -- Replace the current line with the split version
      vim.fn.setline(vim.fn.line '.', result)
    end
  end
end

-- Simple split command for user commands
function M.split_command_simple(confirm)
  local pattern = [[\(\s\{1,}\)\(-\+\)]]
  local replacement = [[ \\\r\t\t\2]]
  local flags = confirm and 'cg' or 'g'
  vim.cmd('s:' .. pattern .. ':' .. replacement .. ':' .. flags .. ' | noh | retab')
end

return M

