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

-- gx URL opener: extracts the URL/repo from <cfile>, then delegates to the
-- shared platform opener. Recognizes http(s):// directly and `owner/repo`
-- shorthand (expanded to github.com/owner/repo).
local url_opener = require 'url-opener'

local function open_url()
  local url = vim.fn.expand '<cfile>'

  if url:match '^https?://' then
    url_opener.open(url)
  elseif url:match '^[%w%-_%.]+/[%w%-_%.]+$' then
    url_opener.open('https://github.com/' .. url, 'GitHub repo')
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
      vim.cmd 'silent normal! `[=`]'
    end
  end
end

vim.keymap.set({ 'n', 'x' }, 'p', smart_paste 'p', { desc = 'Paste (indent-aware)' })
vim.keymap.set({ 'n', 'x' }, 'P', smart_paste 'P', { desc = 'Paste before (indent-aware)' })

-- Multigrep: `<pattern>  <glob>` live picker via Snacks.picker
require('multigrep').setup()

-- Fuzzy-finder keymaps (migrated from Telescope to Snacks.picker)
local map = vim.keymap.set

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- NOTE: <C-hjkl> window navigation is handled by vim-herdr-navigation
-- (falls back to vim-tmux-navigator under tmux); see plugins/tmux-navigator.lua
-- Snacks.picker bindings. picker(name, opts) defers the lookup to keypress
-- time; Snacks is a global the snacks plugin installs at startup. A bare
-- Snacks.picker() falls through to the 'pickers' source, hence <leader>ss.
local function picker(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end

local pickers = {
  { '<leader>sh', picker 'help', '[S]earch [H]elp' },
  { '<leader>sk', picker 'keymaps', '[S]earch [K]eymaps' },
  { '<leader>sf', picker('files', { hidden = true }), '[S]earch [F]iles' },
  { '<leader>ss', picker 'pickers', '[S]earch [S]elect picker' },
  { '<leader>sw', picker 'grep_word', '[S]earch current [W]ord' },
  { '<leader>sg', picker 'grep', '[S]earch by [G]rep' },
  { '<leader>sm', picker 'git_status', '[S]earch Git [M]odified' },
  { '<leader>sd', picker 'diagnostics', '[S]earch [D]iagnostics' },
  { '<leader>sr', picker 'resume', '[S]earch [R]esume' },
  { '<leader>s.', picker 'recent', '[S]earch Recent Files ("." for repeat)' },
  { '<leader><leader>', picker 'buffers', '[ ] Find existing buffers' },
  { '<leader>/', picker 'lines', '[/] Fuzzily search in current buffer' },
  { '<leader>s/', picker 'grep_buffers', '[S]earch [/] in Open Files' },
  { '<leader>sn', picker('files', { cwd = vim.fn.stdpath 'config', hidden = true }), '[S]earch [N]eovim files' },
  { '<leader>ep', picker('files', { cwd = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy'), hidden = true }), '[P]lugin path search' },
}
for _, m in ipairs(pickers) do
  map('n', m[1], m[2], { desc = m[3] })
end

-- Yank the current buffer's path to the system clipboard (the `%` register
-- already holds the relative form for "%p / <C-r>%; these get it off-editor).
map('n', '<leader>yp', function()
  vim.fn.setreg('+', vim.fn.expand '%:p')
end, { desc = '[Y]ank absolute file [P]ath' })
map('n', '<leader>yr', function()
  vim.fn.setreg('+', vim.fn.expand '%')
end, { desc = '[Y]ank [R]elative file path' })
