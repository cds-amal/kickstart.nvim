-- Multigrep: live rg search where the prompt is split on double-space into
-- `<pattern>  <glob>`. The text before the double-space is the regex; the
-- text after is an rg `-g` glob (e.g. `foo  *.lua`).
--
-- Originally a Telescope picker; ported to Snacks.picker.

local M = {}

local uv = vim.uv or vim.loop

---@param opts snacks.picker.Config
---@param ctx { filter: { search: string }, opts: fun(table): table }
local function multigrep_finder(opts, ctx)
  local search = ctx.filter.search or ''
  if search == '' then
    return function() end
  end

  local pieces = vim.split(search, '  ', { plain = true })
  local pattern = pieces[1]
  if not pattern or pattern == '' then
    return function() end
  end

  local args = {
    '--color=never',
    '--no-heading',
    '--with-filename',
    '--line-number',
    '--column',
    '--smart-case',
    '-e',
    pattern,
  }

  local glob = pieces[2]
  if glob and glob ~= '' then
    table.insert(args, '-g')
    table.insert(args, glob)
  end

  local cwd = vim.fs.normalize(opts.cwd or uv.cwd() or '.')

  return require('snacks.picker.source.proc').proc(
    ctx:opts {
      notify = false, -- rg exits non-zero on no-match; don't surface that
      cmd = 'rg',
      args = args,
      cwd = cwd,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        item.cwd = cwd
        local file, line, col, text = item.text:match '^(.-):(%d+):(%d+):(.*)$'
        if not (file and line and col) then
          return false
        end
        item.file = file
        item.pos = { tonumber(line), tonumber(col) - 1 }
        item.line = text
      end,
    },
    ctx
  )
end

function M.open(opts)
  return Snacks.picker.pick(vim.tbl_deep_extend('force', {
    source = 'multigrep',
    finder = multigrep_finder,
    format = 'file',
    live = true,
    supports_live = true,
    show_empty = true,
    title = 'Multi Grep  (pattern  glob)',
  }, opts or {}))
end

function M.setup()
  vim.keymap.set('n', '<leader>sG', M.open, { desc = '[S]earch [G]rep (pattern + glob)' })
end

return M
