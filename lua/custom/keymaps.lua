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

local run_and_capture = function(command)
  return vim.fn.systemlist { 'sh', '-c', command }
end

vim.api.nvim_create_user_command('CastInspectTransaction', function()
  local word = vim.fn.expand '<cword>'
  local linenr = vim.fn.line '.'

  -- collect output
  local lines = {}
  table.insert(lines, '=====')
  table.insert(lines, 'CALLDATA:')

  local calldata = run_and_capture('cast tx ' .. word .. ' --json --rpc-url http://localhost:8545 | jq -r .input')
  vim.list_extend(lines, calldata)

  table.insert(lines, '------------')
  table.insert(lines, '')
  table.insert(lines, 'RUN:')

  local trace = run_and_capture('cast run ' .. word .. ' -vvvvv --rpc-url http://localhost:8545')
  vim.list_extend(lines, trace)

  table.insert(lines, '------------')
  table.insert(lines, '')
  table.insert(lines, 'RECEIPTS:')

  local receipt = run_and_capture('cast receipt ' .. word .. ' --json --rpc-url http://localhost:8545 | yq -P eval')
  vim.list_extend(lines, receipt)

  table.insert(lines, '=====')

  -- insert the block into the buffer
  vim.api.nvim_buf_set_lines(0, linenr, linenr, false, lines)
end, {})

vim.keymap.set('n', '<leader>it', '<cmd>CastInspectTransaction<CR>', { desc = '[I]nspect [T]ransaction' })
vim.keymap.set('n', '<leader>cb', clean_buffer, { desc = '[C]lean [Buffer]' })
