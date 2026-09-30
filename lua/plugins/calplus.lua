-- Local plugin: calplus, which turns a line in a note into a calendar event and writes a link to the
-- event back into the line. Loaded from the working checkout, so an edit there is live on the next
-- start. `lazy = false` even though `keys` is set: the plugin file only defines `:Calplus` and two
-- <Plug> mappings (every module is required on use), and `:checkhealth calplus` finds the health
-- module only while the plugin is on the runtimepath.
--
-- A line is an event when it has an `@` with whitespace before it: `- [ ] Review finances @ next friday
-- 9-9:30 ET`. The README's "Writing a line" section has the table of forms.
--
-- A `:task` line (`:task Review finances @ next friday`) goes to the task adapter instead: Google
-- Tasks here, which shows up on the calendar's Tasks list rather than as an all-day event.
--
-- Google needs CALPLUS_GOOGLE_CLIENT_ID and CALPLUS_GOOGLE_CLIENT_SECRET in the environment Neovim
-- starts from, and `:Calplus login google` once; the token lives in the store `security` names
-- (the macOS keychain there, 1Password here). Both
-- adapters share that login, so the Cloud project needs the Calendar API and the Tasks API enabled.
local root = vim.fn.expand '~/dev/nvim-plugins/calplus'

return {
  dir = root,
  main = 'calplus',
  lazy = false,
  opts = {
    adapter = { event = 'google', task = 'google-tasks' },
    -- While the plugin is under development: every line read and every HTTP request, as well as
    -- runs and outcomes. `:Calplus log` (or <leader>kl) opens the file.
    log = 'debug',
    -- Every calplus message goes through this. Snacks toasts float, so they leave cmdheight alone;
    -- the built-in vim.notify echoes into the message area, which auto-cmdheight makes room for by
    -- pushing the statusline up a row until the next key press.
    notify = function(msg, level, opts)
      require('snacks').notifier.notify(msg, level, opts)
    end,
    adapters = {
      -- The os-key-store backend exists only on macOS; on Linux the token lives in 1Password via
      -- `op`. google-tasks leaves `security` unset and inherits google's store, so one login
      -- serves both.
      google = { calendar_id = 'primary', security = { backend = 'op', vault = 'Private' } },
      ['google-tasks'] = { tasklist = '@default' },
    },
  },
  keys = {
    -- remap: the right-hand sides are the plugin's own <Plug> mappings.
    { '<leader>ks', '<Plug>(CalplusSchedule)', mode = { 'n', 'x' }, remap = true, desc = 'Calendar: [S]chedule this line or the selection' },
    { '<leader>ko', '<Plug>(CalplusOpen)', remap = true, desc = "Calendar: [O]pen this line's event" },
    { '<leader>kp', '<Plug>(CalplusPreview)', mode = { 'n', 'x' }, remap = true, desc = 'Calendar: [P]review how this line reads' },
    { '<leader>kS', '<cmd>Calplus schedule!<CR>', desc = 'Calendar: [S]chedule again, forcing a pending line' },
    { '<leader>kl', '<cmd>Calplus log<CR>', desc = 'Calendar: open the development [L]og' },
    { '<leader>ke', '<Plug>(CalplusEvents)', remap = true, desc = 'Calendar: list upcoming [E]vents' },
    { '<leader>kt', '<Plug>(CalplusTasks)', remap = true, desc = 'Calendar: list open [T]asks' },
  },
}
