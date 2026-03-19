local M = {}

function M.center_pad(str, width)
  local pad = width - #str
  local left = math.floor(pad / 2)
  local right = pad - left
  return string.rep(' ', left) .. str .. string.rep(' ', right)
end

function M.format_table(headers, rows)
  local widths = {}
  for i, h in ipairs(headers) do
    widths[i] = math.max(3, #h)
  end
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row) do
      widths[i] = math.max(widths[i], #cell)
    end
  end

  local hdr_cells = {}
  for i, h in ipairs(headers) do
    hdr_cells[i] = ' ' .. M.center_pad(h, widths[i]) .. ' '
  end
  local heading = '|' .. table.concat(hdr_cells, '|') .. '|'

  local sep_cells = {}
  for i = 1, #headers do
    sep_cells[i] = ':' .. string.rep('-', widths[i]) .. ':'
  end
  local separator = '|' .. table.concat(sep_cells, '|') .. '|'

  local lines = { heading, separator }
  for _, row in ipairs(rows) do
    local cells = {}
    for i, cell in ipairs(row) do
      cells[i] = ' ' .. M.center_pad(cell, widths[i]) .. ' '
    end
    lines[#lines + 1] = '|' .. table.concat(cells, '|') .. '|'
  end

  return lines
end

function M.generate_rows(n)
  local total = 2 ^ n
  local rows = {}
  for i = 0, total - 1 do
    local row = {}
    for col = 1, n do
      local bit = math.floor(i / (2 ^ (n - col))) % 2
      row[col] = tostring(bit)
    end
    rows[#rows + 1] = row
  end
  return rows
end

function M.parse_truth_table_args(args)
  local input = vim.trim(args)
  if input == '' then
    return nil, 'Usage: :TruthTable N or :TruthTable name1 name2 ...'
  end

  local n = tonumber(input)
  if n then
    if n < 1 or n > 10 or n ~= math.floor(n) then
      return nil, 'N must be an integer between 1 and 10'
    end
    local headers = {}
    for i = 1, n do
      headers[i] = string.char(64 + i)
    end
    return headers
  end

  local headers = {}
  local seen = {}
  for name in input:gmatch('%S+') do
    if not name:match('^[A-Za-z_][A-Za-z0-9_]*$') then
      return nil, 'Invalid variable name: ' .. name
    end
    if seen[name] then
      return nil, 'Duplicate variable name: ' .. name
    end
    seen[name] = true
    headers[#headers + 1] = name
  end

  if #headers > 10 then
    return nil, 'Too many variables (max 10)'
  end

  return headers
end

function M.is_table_line(line)
  return line:match('^%s*|.*|%s*$') ~= nil
end

function M.is_separator(line)
  local inner = line:match('^%s*|(.+)|%s*$')
  if not inner then return false end
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    if not cell:match('^%s*:?%-+:?%s*$') then
      return false
    end
  end
  return true
end

function M.split_row(line)
  local cells = {}
  local inner = line:match('^%s*|(.+)|%s*$')
  if not inner then return cells end
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells
end

function M.parse_table_lines(lines)
  local headers = M.split_row(lines[1])
  local rows = {}
  for i = 3, #lines do
    rows[#rows + 1] = M.split_row(lines[i])
  end
  return { headers = headers, rows = rows }
end

return M
