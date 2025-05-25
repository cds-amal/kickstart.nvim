local M = {}

local last_abi_cmd = nil
local last_output_buf = nil
local use_last_output_buf = false

local abi_commands = {
  {
    name = 'Function and Constructor Types',
    cmd = [[jq '.abi | .[] | select(.type != "error" and .type != "event") | .type']],
  },
  {
    name = 'Function and Constructor Names',
    cmd = [[jq '.abi | .[] | select(.type != "error" and .type != "event") | .name']],
  },
  {
    name = 'Struct Internal Types',
    cmd = [[jq '.. | objects | select(has("internalType")) | .internalType' | grep '^struct ' | sort -u]],
  },
}

local function run_cmd_into_buf(cmd)
  if not cmd or cmd == '' then
    vim.notify('Empty shell command. Skipping.', vim.log.levels.ERROR)
    return
  end

  vim.notify('Running: ' .. cmd)

  local output = vim.fn.systemlist(cmd)
  local ok = vim.v.shell_error == 0

  if not ok then
    vim.notify('Shell command failed:\n' .. table.concat(output, '\n'), vim.log.levels.ERROR)
    return
  end

  -- Set buffer
  if use_last_output_buf and last_output_buf and vim.api.nvim_buf_is_valid(last_output_buf) then
    vim.api.nvim_set_current_buf(last_output_buf)
    vim.cmd '%d'
  else
    vim.cmd 'enew'
    last_output_buf = vim.api.nvim_get_current_buf()
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  vim.bo.filetype = 'json'
end

function M.pick_internal_type()
  local file = vim.fn.expand '%:p'
  if file == '' or vim.fn.filereadable(file) == 0 then
    vim.notify('No valid file to run jq against', vim.log.levels.ERROR)
    return
  end

  -- Collect internalTypes from both inputs and outputs
  local raw = vim.fn.systemlist([[
    jq -r '[.abi[]? | .inputs[]?.internalType, .outputs[]?.internalType] | .[]' ]] .. vim.fn.shellescape(file) .. [[ | grep -E '^contract ' | sort -u ]])

  if vim.v.shell_error ~= 0 or not raw or #raw == 0 then
    vim.notify('No matching contract internalTypes found.', vim.log.levels.WARN)
    return
  end

  vim.ui.select(raw, { prompt = 'Select internalType to search' }, function(choice)
    if not choice then
      return
    end
    local interface = choice:match 'contract (%S+)'
    if not interface then
      vim.notify('Invalid selection', vim.log.levels.ERROR)
      return
    end

    -- Match against both inputs and outputs
    local jq_query = string.format(
      [[jq '.abi[] | select(
        any(.inputs[]?; .internalType | test("%s")) or
        any(.outputs[]?; .internalType | test("%s"))
      )' %s]],
      interface,
      interface,
      vim.fn.shellescape(file)
    )

    last_abi_cmd = jq_query
    run_cmd_into_buf(jq_query)
  end)
end

function M.run_picker()
  local file = vim.fn.expand '%:p'
  if file == '' or vim.fn.filereadable(file) == 0 then
    vim.notify('No valid file to run jq against', vim.log.levels.ERROR)
    return
  end

  local choices = {}
  for i, entry in ipairs(abi_commands) do
    table.insert(choices, string.format('%d. %s', i, entry.name))
  end

  vim.ui.select(choices, { prompt = 'Select ABI query' }, function(choice)
    if not choice then
      return
    end
    local idx = tonumber(choice:match '^(%d+)')
    local cmd = abi_commands[idx].cmd .. ' ' .. vim.fn.shellescape(file)
    last_abi_cmd = cmd
    run_cmd_into_buf(cmd)
  end)
end

function M.rerun_last()
  if not last_abi_cmd then
    vim.notify('No previous ABI jq command run', vim.log.levels.WARN)
    return
  end
  run_cmd_into_buf(last_abi_cmd)
end

function M.toggle_target()
  use_last_output_buf = not use_last_output_buf
  vim.notify('Output will go to ' .. (use_last_output_buf and 'last buffer' or 'new buffer'))
end

-- Setup keymaps when module loads
vim.keymap.set('n', '<leader>jq', M.run_picker, { desc = 'Run ABI jq picker' })
vim.keymap.set('n', '<leader>j.', M.rerun_last, { desc = 'Re-run last ABI jq' })
vim.keymap.set('n', '<leader>jt', M.toggle_target, { desc = 'Toggle ABI output buffer target' })
vim.keymap.set('n', '<leader>ji', M.pick_internal_type, { desc = 'Find ABI entries by internalType' })
return M
