-- Obfuscated comments: ROT-13 and base64 encoding into comment blocks
-- Useful for hiding spoilers, puzzle answers, or sensitive notes in plain sight

local function rot13(str)
  return str:gsub('[%a]', function(c)
    local base = c:match('[a-z]') and string.byte('a') or string.byte('A')
    return string.char((string.byte(c) - base + 13) % 26 + base)
  end)
end

local function get_comment_parts()
  local cs = vim.bo.commentstring
  if not cs or cs == '' then
    cs = '# %s'
  end
  local left, right = cs:match('^(.-)%%s(.-)$')
  if left and not left:match('%s$') then
    left = left .. ' '
  end
  return left or '# ', right or ''
end

local function is_commented(line, left, right)
  local escaped_left = vim.pesc(vim.trim(left))
  local escaped_right = vim.pesc(vim.trim(right))
  local pattern
  if escaped_right ~= '' then
    pattern = '^%s*' .. escaped_left .. '.*' .. escaped_right .. '$'
  else
    pattern = '^%s*' .. escaped_left
  end
  return line:match(pattern) ~= nil
end

local function strip_comment(line, left, right)
  local escaped_left = vim.pesc(vim.trim(left))
  local escaped_right = vim.pesc(vim.trim(right))
  local pattern
  if escaped_right ~= '' then
    pattern = '^(%s*)' .. escaped_left .. '%s?(.-)%s?' .. escaped_right .. '$'
  else
    pattern = '^(%s*)' .. escaped_left .. '%s?(.*)'
  end
  local indent, content = line:match(pattern)
  if indent then
    return indent, content
  end
  return nil, nil
end

-- Encode: ROT-13 each line and wrap in comments
local function rot13_encode(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local left, right = get_comment_parts()
  local result = {}

  for _, line in ipairs(lines) do
    if not line:match('%S') then
      table.insert(result, line)
    else
      local indent = line:match('^(%s*)')
      local content = line:sub(#indent + 1)
      table.insert(result, indent .. left .. rot13(content) .. right)
    end
  end

  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, result)
end

-- Encode: base64 the whole block as one blob, split into 76-char comment lines
local B64_MARKER = '[b64]'

local function b64_encode(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local left, right = get_comment_parts()

  local indent = ''
  for _, line in ipairs(lines) do
    if line:match('%S') then
      indent = line:match('^(%s*)')
      break
    end
  end

  local blob = table.concat(lines, '\n')
  local encoded = vim.base64.encode(blob)

  local result = { indent .. left .. B64_MARKER .. right }
  for i = 1, #encoded, 76 do
    table.insert(result, indent .. left .. encoded:sub(i, i + 75) .. right)
  end

  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, result)
end

-- Decode: find the commented block around the cursor and auto-detect encoding
local function find_commented_block_at_cursor()
  local left, right = get_comment_parts()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(0)

  -- Verify cursor is on a commented line
  local cur_line = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, false)[1]
  if not cur_line:match('%S') or not is_commented(cur_line, left, right) then
    return nil
  end

  -- Scan upward for the start of contiguous comments
  local start_row = cursor_row
  for row = cursor_row - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not line:match('%S') or not is_commented(line, left, right) then
      break
    end
    start_row = row
  end

  -- Scan downward for the end of contiguous comments
  local end_row = cursor_row
  for row = cursor_row + 1, total do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not line:match('%S') or not is_commented(line, left, right) then
      break
    end
    end_row = row
  end

  return start_row, end_row
end

local function decode_at_cursor()
  local start_row, end_row = find_commented_block_at_cursor()
  if not start_row then
    vim.notify('Not inside a commented block', vim.log.levels.WARN)
    return
  end

  local left, right = get_comment_parts()

  -- Check first line for [b64] marker
  local first = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
  local _, first_content = strip_comment(first, left, right)

  if first_content == B64_MARKER then
    -- Base64 decode
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local chunks = {}
    for i, line in ipairs(lines) do
      local _, content = strip_comment(line, left, right)
      if content and not (i == 1 and content == B64_MARKER) then
        chunks[#chunks + 1] = vim.trim(content)
      end
    end

    local ok, decoded = pcall(vim.base64.decode, table.concat(chunks))
    if not ok then
      vim.notify('Failed to decode base64 block', vim.log.levels.ERROR)
      return
    end
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, vim.split(decoded, '\n', { plain = true }))
  else
    -- ROT-13 decode
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local result = {}
    for _, line in ipairs(lines) do
      local indent, content = strip_comment(line, left, right)
      if indent then
        table.insert(result, indent .. rot13(content))
      else
        table.insert(result, line)
      end
    end
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, result)
  end
end

-- Commands
vim.api.nvim_create_user_command('Rot13Encode', function(opts)
  rot13_encode(opts.line1, opts.line2)
end, { range = true, desc = 'ROT-13 encode and comment out lines' })

vim.api.nvim_create_user_command('B64Encode', function(opts)
  b64_encode(opts.line1, opts.line2)
end, { range = true, desc = 'Base64 encode and comment out lines' })

vim.api.nvim_create_user_command('CipherDecode', function()
  decode_at_cursor()
end, { desc = 'Decode commented block at cursor (auto-detects ROT-13 or base64)' })

-- Keymaps
vim.keymap.set('v', '<leader>cr', ':Rot13Encode<CR>', { desc = 'ROT-13 encode + comment', silent = true })
vim.keymap.set('v', '<leader>cb', ':B64Encode<CR>', { desc = 'Base64 encode + comment', silent = true })
vim.keymap.set('n', '<leader>cd', decode_at_cursor, { desc = 'Decode cipher block at cursor', silent = true })

return {}
