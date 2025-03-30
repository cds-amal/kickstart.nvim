-- runbook-navigator.lua
-- A Neovim plugin to navigate between runbook files

local M = {}

-- Store configuration globally
M.config = {
  runbook_files = { 'runbooks.yml', 'runbooks.yaml' },
  tx_extension = '.tx',
}

-- Check if a YAML file has the "runbooks:" top-level entry
local function has_runbooks_entry(content)
  for _, line in ipairs(content) do
    if line:match '^runbooks:' then
      return true
    end
  end
  return false
end

-- Simple YAML parsing for runbook entries
local function parse_runbooks(content)
  local runbooks = {}
  local current_runbook = nil
  local in_runbooks_section = false

  for _, line in ipairs(content) do
    -- Look for runbooks: section
    if line:match '^runbooks:' then
      in_runbooks_section = true
    -- Look for a new section that would end the runbooks section
    elseif in_runbooks_section and line:match '^%S+:' and not line:match '^%s*-%s*name:' then
      in_runbooks_section = false
    end

    if in_runbooks_section then
      local name_match = line:match '^%s*-%s*name:%s*(.+)$'
      local location_match = line:match '^%s*location:%s*(.+)$'
      local description_match = line:match '^%s*description:%s*(.+)$'

      if name_match then
        current_runbook = name_match:gsub('^%s*(.-)%s*$', '%1') -- trim whitespace
        runbooks[current_runbook] = runbooks[current_runbook] or { description = '', location = '' }
      elseif location_match and current_runbook then
        runbooks[current_runbook].location = location_match:gsub('^%s*(.-)%s*$', '%1') -- trim whitespace
      elseif description_match and current_runbook then
        runbooks[current_runbook].description = description_match:gsub('^%s*(.-)%s*$', '%1') -- trim whitespace
      end
    end
  end

  return runbooks
end

-- Find all .tx files in a directory
local function find_tx_files(dir, extension)
  extension = extension or M.config.tx_extension
  local files = {}
  local glob_pattern = dir .. '/*' .. extension

  for _, file in ipairs(vim.fn.glob(glob_pattern, false, true)) do
    table.insert(files, file)
  end

  -- Sort files but prioritize main.tx
  table.sort(files, function(a, b)
    local a_is_main = vim.fn.fnamemodify(a, ':t') == 'main' .. extension
    local b_is_main = vim.fn.fnamemodify(b, ':t') == 'main' .. extension

    if a_is_main and not b_is_main then
      return true
    elseif not a_is_main and b_is_main then
      return false
    else
      return a < b
    end
  end)

  return files
end

-- Find project root and YAML file
local function get_yaml_info()
  -- If current file is YAML and has runbooks, use it
  local current_file = vim.fn.expand '%:p'
  local is_yaml = vim.fn.fnamemodify(current_file, ':e'):match '^ya?ml$'

  if is_yaml then
    local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    if has_runbooks_entry(content) then
      local project_root = vim.fn.fnamemodify(current_file, ':h')
      local runbooks = parse_runbooks(content)
      return project_root, current_file, runbooks
    end
  end

  -- Otherwise, look for YAML files in parent directories
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local dir = current_dir

  while dir ~= '/' do
    for _, filename in ipairs(M.config.runbook_files) do
      local path = dir .. '/' .. filename
      if vim.fn.filereadable(path) == 1 then
        local content = vim.fn.readfile(path)
        if has_runbooks_entry(content) then
          local runbooks = parse_runbooks(content)
          return dir, path, runbooks
        end
      end
    end

    dir = vim.fn.fnamemodify(dir, ':h')
  end

  return nil, nil, {}
end

-- Get the current runbook name from file path
local function get_current_runbook(project_root, runbooks)
  local current_file = vim.fn.expand '%:p'

  for name, rb in pairs(runbooks) do
    local rb_dir = project_root .. '/' .. rb.location
    if string.find(current_file, rb_dir, 1, true) then
      return name, rb
    end
  end

  return nil, nil
end

-- List all available runbooks in a floating window
function M.list_runbooks()
  local project_root, yaml_path, runbooks = get_yaml_info()
  if not project_root or vim.tbl_isempty(runbooks) then
    vim.notify('No runbooks found in project', vim.log.levels.WARN)
    return
  end

  -- Format the runbooks for display
  local lines = {}
  local runbook_names = {}

  for name, _ in pairs(runbooks) do
    table.insert(runbook_names, name)
  end

  table.sort(runbook_names)

  for _, name in ipairs(runbook_names) do
    local rb = runbooks[name]
    table.insert(lines, name .. ' - ' .. rb.description)
  end

  -- Create a popup window
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local width = 80
  local height = #lines
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = 'minimal',
    border = 'rounded',
  }

  local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)

  -- Set mappings for the popup window
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    '<CR>',
    string.format([[<cmd>lua require('custom.plugins.txtx.txtx').open_runbook('%s')<CR>]], vim.fn.fnameescape(project_root)),
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })

  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'runbook-list')

  -- Store runbook data in buffer variable
  vim.b[bufnr].runbooks = runbooks
  vim.b[bufnr].runbook_names = runbook_names
end

-- Open a specific runbook
function M.open_runbook(project_root)
  local bufnr = vim.api.nvim_get_current_buf()
  local runbooks = vim.b[bufnr].runbooks
  local runbook_names = vim.b[bufnr].runbook_names

  local cursor = vim.api.nvim_win_get_cursor(0)
  local selected_idx = cursor[1]
  local selected_name = runbook_names[selected_idx]

  if not selected_name then
    return
  end

  local rb = runbooks[selected_name]
  local rb_dir = project_root .. '/' .. rb.location

  -- Find TX files in the runbook directory
  local tx_files = find_tx_files(rb_dir)

  if #tx_files == 0 then
    vim.notify('No ' .. M.config.tx_extension .. ' files found in ' .. rb_dir, vim.log.levels.WARN)
    return
  end

  -- If only one file, open it directly
  if #tx_files == 1 then
    vim.cmd 'close' -- Close the selection window
    vim.cmd('edit ' .. tx_files[1])
    return
  end

  -- Otherwise show file selection window
  vim.cmd 'close' -- Close the runbook selection window

  local file_names = {}
  for _, file in ipairs(tx_files) do
    table.insert(file_names, vim.fn.fnamemodify(file, ':t'))
  end

  local file_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(file_bufnr, 0, -1, false, file_names)

  local width = 60
  local height = #file_names
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = 'minimal',
    border = 'rounded',
  }

  local file_winnr = vim.api.nvim_open_win(file_bufnr, true, win_opts)

  -- Set mappings for file selection
  vim.api.nvim_buf_set_keymap(file_bufnr, 'n', '<CR>', '<cmd>lua require("custom.plugins.txtx.txtx").open_tx_file()<CR>', { noremap = true, silent = true })

  vim.api.nvim_buf_set_keymap(file_bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })

  -- Set buffer options
  vim.api.nvim_buf_set_option(file_bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(file_bufnr, 'filetype', 'runbook-file-list')

  -- Store file data in buffer variable
  vim.b[file_bufnr].tx_files = tx_files
end

-- Open selected TX file
function M.open_tx_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local tx_files = vim.b[bufnr].tx_files

  local cursor = vim.api.nvim_win_get_cursor(0)
  local selected_idx = cursor[1]
  local selected_file = tx_files[selected_idx]

  if not selected_file then
    return
  end

  vim.cmd 'close' -- Close the selection window
  vim.cmd('edit ' .. selected_file)
end

-- List alternate files for current runbook
function M.list_alternate_files()
  local project_root, yaml_path, runbooks = get_yaml_info()
  if not project_root or vim.tbl_isempty(runbooks) then
    vim.notify('No runbooks found in project', vim.log.levels.WARN)
    return
  end

  local runbook_name, runbook = get_current_runbook(project_root, runbooks)

  if not runbook_name then
    vim.notify('Current file is not part of a known runbook', vim.log.levels.WARN)
    return
  end

  local rb_dir = project_root .. '/' .. runbook.location
  local tx_files = find_tx_files(rb_dir)

  if #tx_files <= 1 then
    vim.notify('No alternate files found for this runbook', vim.log.levels.INFO)
    return
  end

  -- Show file selection window
  local file_names = {}
  for _, file in ipairs(tx_files) do
    table.insert(file_names, vim.fn.fnamemodify(file, ':t'))
  end

  local file_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(file_bufnr, 0, -1, false, file_names)

  local width = 60
  local height = #file_names
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = 'minimal',
    border = 'rounded',
  }

  local file_winnr = vim.api.nvim_open_win(file_bufnr, true, win_opts)

  -- Set mappings for file selection
  vim.api.nvim_buf_set_keymap(file_bufnr, 'n', '<CR>', '<cmd>lua require("custom.plugins.txtx.txtx").open_tx_file()<CR>', { noremap = true, silent = true })

  vim.api.nvim_buf_set_keymap(file_bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })

  -- Set buffer options
  vim.api.nvim_buf_set_option(file_bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(file_bufnr, 'filetype', 'runbook-file-list')

  -- Store file data in buffer variable
  vim.b[file_bufnr].tx_files = tx_files
end

-- Cycle through alternate files for current runbook
function M.cycle_alternate_files(direction)
  direction = direction or 'next' -- 'next' or 'prev'

  local project_root, yaml_path, runbooks = get_yaml_info()
  if not project_root or vim.tbl_isempty(runbooks) then
    vim.notify('No runbooks found in project', vim.log.levels.WARN)
    return
  end

  local runbook_name, runbook = get_current_runbook(project_root, runbooks)

  if not runbook_name then
    vim.notify('Current file is not part of a known runbook', vim.log.levels.WARN)
    return
  end

  local rb_dir = project_root .. '/' .. runbook.location
  local tx_files = find_tx_files(rb_dir)

  if #tx_files <= 1 then
    vim.notify('No alternate files for this runbook', vim.log.levels.INFO)
    return
  end

  -- Find current file index
  local current_file = vim.fn.expand '%:p'
  local current_idx = nil

  for i, file in ipairs(tx_files) do
    if file == current_file then
      current_idx = i
      break
    end
  end

  if not current_idx then
    -- Current file might not be in the list (maybe it's not a .tx file)
    -- In this case, just open the first file
    vim.cmd('edit ' .. tx_files[1])
    return
  end

  -- Calculate next/previous index
  local next_idx
  if direction == 'next' then
    next_idx = current_idx % #tx_files + 1
  else
    next_idx = (current_idx - 2) % #tx_files + 1
  end

  vim.cmd('edit ' .. tx_files[next_idx])
end

-- Set up the plugin
function M.setup(opts)
  opts = opts or {}

  -- Update global config with user options
  if opts.runbook_files then
    M.config.runbook_files = opts.runbook_files
  end

  if opts.tx_extension then
    M.config.tx_extension = opts.tx_extension
  end

  -- Create user commands
  vim.api.nvim_create_user_command('RunbookList', function()
    M.list_runbooks()
  end, {})

  vim.api.nvim_create_user_command('RunbookAlternates', function()
    M.list_alternate_files()
  end, {})

  vim.api.nvim_create_user_command('RunbookNext', function()
    M.cycle_alternate_files 'next'
  end, {})

  vim.api.nvim_create_user_command('RunbookPrev', function()
    M.cycle_alternate_files 'prev'
  end, {})

  -- Set default keymappings unless disabled
  if opts.keymaps ~= false then
    local keymap_opts = { noremap = true, silent = true }

    -- Default keymappings (can be overridden by opts.keymaps)
    local keymaps = opts.keymaps
      or {
        list_runbooks = '<leader>rr',
        list_alternates = '<leader>ra',
        next_alternate = '<leader>rn',
        prev_alternate = '<leader>rp',
      }

    vim.keymap.set('n', keymaps.list_runbooks, M.list_runbooks, keymap_opts)
    vim.keymap.set('n', keymaps.list_alternates, M.list_alternate_files, keymap_opts)
    vim.keymap.set('n', keymaps.next_alternate, function()
      M.cycle_alternate_files 'next'
    end, keymap_opts)
    vim.keymap.set('n', keymaps.prev_alternate, function()
      M.cycle_alternate_files 'prev'
    end, keymap_opts)
  end

  -- Create a filetype detection autocommand for YAML files
  vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
    pattern = { '*.yml', '*.yaml' },
    callback = function()
      local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      if has_runbooks_entry(content) then
        vim.b.has_runbooks = true
        vim.notify('Runbook navigation enabled for this file', vim.log.levels.INFO)
      end
    end,
  })
end

return M
