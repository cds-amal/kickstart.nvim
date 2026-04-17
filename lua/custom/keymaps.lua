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

-- Function to open URLs in default browser
local function open_url()
  local url = vim.fn.expand('<cfile>')

  -- Check if the URL starts with http:// or https://
  if url:match('^https?://') then
    vim.fn.jobstart({ 'open', url }, { detach = true })
    vim.notify('Opening URL: ' .. url)
  -- Check if it's a GitHub repo in format 'owner/repo'
  elseif url:match('^[%w%-_%.]+/[%w%-_%.]+$') then
    local github_url = 'https://github.com/' .. url
    vim.fn.jobstart({ 'open', github_url }, { detach = true })
    vim.notify('Opening GitHub repo: ' .. github_url)
  else
    vim.notify('No valid URL or GitHub repo under cursor', vim.log.levels.WARN)
  end
end

-- Map gx to open URLs in default browser
vim.keymap.set('n', 'gx', open_url, { desc = 'Open URL in browser' })

vim.keymap.set('n', '<leader>jj', ':%!jq .<CR>', { desc = 'Format JSON with jq' })

-- Indent-aware paste: after pasting a linewise register, re-indent the pasted
-- region via `=` (which uses indentexpr, now treesitter-backed where possible).
-- Charwise/blockwise pastes are left alone.
local function smart_paste(cmd)
  return function()
    vim.cmd('normal! ' .. vim.v.count1 .. '"' .. vim.v.register .. cmd)
    if vim.fn.getregtype(vim.v.register) == 'V' then
      vim.cmd('silent normal! `[=`]')
    end
  end
end

vim.keymap.set({ 'n', 'x' }, 'p', smart_paste('p'), { desc = 'Paste (indent-aware)' })
vim.keymap.set({ 'n', 'x' }, 'P', smart_paste('P'), { desc = 'Paste before (indent-aware)' })

-- Multigrep: `<pattern>  <glob>` live picker via Snacks.picker
require('custom.multigrep').setup()

-- Fuzzy-finder keymaps (migrated from Telescope to Snacks.picker)
local map = vim.keymap.set
map('n', '<leader>sh', function() Snacks.picker.help() end, { desc = '[S]earch [H]elp' })
map('n', '<leader>sk', function() Snacks.picker.keymaps() end, { desc = '[S]earch [K]eymaps' })
map('n', '<leader>sf', function() Snacks.picker.files() end, { desc = '[S]earch [F]iles' })
map('n', '<leader>ss', function() Snacks.picker() end, { desc = '[S]earch [S]elect picker' })
map('n', '<leader>sw', function() Snacks.picker.grep_word() end, { desc = '[S]earch current [W]ord' })
map('n', '<leader>sg', function() Snacks.picker.grep() end, { desc = '[S]earch by [G]rep' })
map('n', '<leader>sm', function() Snacks.picker.git_status() end, { desc = '[S]earch Git [M]odified' })
map('n', '<leader>sd', function() Snacks.picker.diagnostics() end, { desc = '[S]earch [D]iagnostics' })
map('n', '<leader>sr', function() Snacks.picker.resume() end, { desc = '[S]earch [R]esume' })
map('n', '<leader>s.', function() Snacks.picker.recent() end, { desc = '[S]earch Recent Files ("." for repeat)' })
map('n', '<leader><leader>', function() Snacks.picker.buffers() end, { desc = '[ ] Find existing buffers' })
map('n', '<leader>/', function() Snacks.picker.lines() end, { desc = '[/] Fuzzily search in current buffer' })
map('n', '<leader>s/', function() Snacks.picker.grep_buffers() end, { desc = '[S]earch [/] in Open Files' })
map('n', '<leader>sn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
map('n', '<leader>ep', function()
  Snacks.picker.files { cwd = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy') }
end, { desc = '[P]lugin path search' })
