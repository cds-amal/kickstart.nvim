local M = {}

-- Pattern matching for Ethereum addresses and transaction hashes
local ETH_ADDRESS_PATTERN = '0x[a-fA-F0-9]\\{40\\}'
local ETH_HASH_PATTERN = '0x[a-fA-F0-9]\\{64\\}'

-- Function to get the word under cursor or expand selection
local function get_hex_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Find start of hex string (look for 0x)
  local start_col = col
  while start_col > 0 and line:sub(start_col, start_col + 1) ~= '0x' do
    start_col = start_col - 1
  end

  -- If we didn't find 0x, try looking forward
  if line:sub(start_col, start_col + 1) ~= '0x' then
    start_col = col
    while start_col <= #line - 1 and line:sub(start_col, start_col + 1) ~= '0x' do
      start_col = start_col + 1
    end
  end

  -- If still no 0x found, return nil
  if line:sub(start_col, start_col + 1) ~= '0x' then
    return nil
  end

  -- Find end of hex string
  local end_col = start_col + 2
  while end_col <= #line and line:sub(end_col, end_col):match '[a-fA-F0-9]' do
    end_col = end_col + 1
  end

  return line:sub(start_col, end_col - 1)
end

-- Function to search for txtx.yml upwards from current directory
local function find_txtx_yml()
  local current_dir = vim.fn.expand '%:p:h'
  local root = '/'

  -- Search upwards until we reach root
  while current_dir ~= root and current_dir ~= '' do
    local txtx_path = current_dir .. '/txtx.yml'
    if vim.fn.filereadable(txtx_path) == 1 then
      return txtx_path
    end

    -- Also check for txtx.yaml
    txtx_path = current_dir .. '/txtx.yaml'
    if vim.fn.filereadable(txtx_path) == 1 then
      return txtx_path
    end

    -- Move up one directory
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end

  return nil
end

-- Function to read YAML and extract RPC URL
local function get_rpc_base_url()
  local yaml_file = find_txtx_yml()

  if not yaml_file then
    return nil
  end

  -- Use yq to extract the RPC URL
  local cmd = string.format("yq '.environments.buildbear.rpc_api_url' %s", vim.fn.shellescape(yaml_file))
  local handle = io.popen(cmd)
  local result = handle:read '*a'
  handle:close()

  if result and result:match '^https?://' then
    return result:gsub('%s+', '') -- trim whitespace
  end

  return nil
end

-- Function to determine if hex string is address or transaction hash
local function classify_hex_string(hex_str)
  if not hex_str or not hex_str:match '^0x[a-fA-F0-9]+$' then
    return nil
  end

  local hex_part = hex_str:sub(3) -- remove 0x

  if #hex_part == 40 then
    return 'address'
  elseif #hex_part == 64 then
    return 'transaction'
  else
    return nil
  end
end

-- Function to convert RPC URL to explorer base URL
local function rpc_to_explorer_url(rpc_url)
  -- Extract the unique sandbox_id from the RPC URL
  -- Expected format: https://rpc.buildbear.io/interim-ikaris-251f528b
  local sandbox_id = rpc_url:match 'buildbear%.io/([^/]+)'

  if sandbox_id then
    -- BuildBear explorer URL format
    return 'https://explorer.buildbear.io/' .. sandbox_id
  else
    -- Fallback for non-BuildBear URLs
    local base = rpc_url:gsub('/$', ''):gsub('/rpc$', ''):gsub('/v1$', '')
    return base
  end
end

-- Main function to handle gx override
function M.ethereum_gx()
  local hex_str = get_hex_under_cursor()
  if not hex_str then
    -- Fall back to default gx behavior
    vim.cmd 'normal! gx'
    return
  end

  local hex_type = classify_hex_string(hex_str)
  if not hex_type then
    vim.cmd 'normal! gx'
    return
  end

  local rpc_url = get_rpc_base_url()
  if not rpc_url then
    vim.notify('No txtx.yml found or no RPC URL in txtx.yml', vim.log.levels.WARN)
    return
  end

  local explorer_base = rpc_to_explorer_url(rpc_url)
  local url

  if hex_type == 'address' then
    url = explorer_base .. '/address/' .. hex_str
  elseif hex_type == 'transaction' then
    url = explorer_base .. '/tx/' .. hex_str
  end

  if url then
    vim.notify('Opening: ' .. url)

    -- Determine OS and use appropriate command
    local open_cmd
    if vim.fn.has 'mac' == 1 or vim.fn.has 'osx' == 1 then
      open_cmd = string.format("open '%s'", url)
    elseif vim.fn.has 'unix' == 1 then
      open_cmd = string.format("xdg-open '%s' 2>/dev/null", url)
    elseif vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1 then
      open_cmd = string.format('start "" "%s"', url)
    else
      vim.notify('Unsupported OS for opening URLs', vim.log.levels.ERROR)
      return
    end

    vim.fn.system(open_cmd)
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Override gx mapping
  vim.keymap.set('n', 'go', M.ethereum_gx, {
    desc = 'Open Ethereum address/hash in explorer or default gx',
  })
end

return M
