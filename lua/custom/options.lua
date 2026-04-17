-- Editor options. Required from init.lua before lazy.nvim loads so that
-- vim.g.have_nerd_font and similar are visible to plugin specs.

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- Line numbers
vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = 'a'

-- Mode already shown by the statusline
vim.o.showmode = false

-- Sync clipboard with the OS. Deferred past UiEnter to avoid startup cost.
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true
vim.o.undofile = true

-- Case-insensitive unless \C or a capital letter is in the pattern
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split'

vim.o.cursorline = true
vim.o.cursorcolumn = true
vim.o.scrolloff = 10

-- Ask to save unsaved changes on :q instead of failing outright
vim.o.confirm = true

vim.o.conceallevel = 2

-- Default to 4-space indent; vim-sleuth / ftplugins override per-filetype.
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4

-- vim-sleuth's heuristics mis-detect cue files; turn them off there.
vim.g.sleuth_cue_heuristics = 0

-- Makefiles need real tabs.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'make',
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
    vim.opt_local.softtabstop = 0
  end,
})
