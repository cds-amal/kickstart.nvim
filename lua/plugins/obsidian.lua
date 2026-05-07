local function create_project(name)
  local client = require('obsidian').get_client()
  local vault_root = tostring(client.dir)
  local filepath = vault_root .. '/' .. name .. '.md'

  if vim.fn.filereadable(filepath) == 1 then
    vim.notify('Project "' .. name .. '" already exists', vim.log.levels.WARN)
    vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
    return
  end

  local today = os.date '%Y-%m-%d'
  local lines = {
    '---',
    'scheduled: ' .. today,
    'due: ""',
    'tags:',
    '  - project',
    'state: planning',
    '---',
    '- [ ] ',
  }

  vim.fn.writefile(lines, filepath)
  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
  -- Cursor on the task line, ready to type
  vim.api.nvim_win_set_cursor(0, { 8, 6 })
end

return {
  'obsidian-nvim/obsidian.nvim',
  version = 'v3.15.10',
  lazy = true,
  event = {
    'BufReadPre ' .. vim.fn.expand '~' .. '/Journal/**.md',
    'BufNewFile ' .. vim.fn.expand '~' .. '/Journal/**.md',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'folke/snacks.nvim',
    'saghen/blink.cmp',
  },
  opts = {
    picker = {
      name = 'snacks.pick',
    },

    workspaces = {
      {
        name = 'journal',
        path = '~/.obsidian-arch/ArchJournal/',
      },
    },

    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      alias_format = '%B %-d, %Y',
      template = 'daily note template',
      default_tags = { 'daily' },
    },

    completion = {
      nvim_cmp = false,
    },

    templates = {
      folder = 'meta/templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
      substitutions = {
        -- Fills {{VALUE}} in fleeting/atomic templates (mirrors QuickAdd behavior)
        VALUE = function()
          return vim.fn.input 'Value: '
        end,
        -- {{date_long}} -> "Thursday, May 7, 2026". For daily notes, derives the
        -- date from the note id (set to date_format); otherwise falls back to today.
        date_long = function(ctx)
          local t = os.time()
          local id = ctx and ctx.partial_note and ctx.partial_note.id
          if type(id) == 'string' then
            local y, m, d = id:match '^(%d%d%d%d)-(%d%d)-(%d%d)$'
            if y then
              t = os.time { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }
            end
          end
          return (os.date('%A, %B %e, %Y', t):gsub('  ', ' '))
        end,
      },
    },

    -- Vault convention: filenames ARE the descriptive titles
    note_id_func = function(title)
      if title ~= nil and title ~= '' then
        return title
      end
      return os.date '%Y-%m-%d' .. ' untitled'
    end,

    -- Minimal frontmatter to match the vault's tag-based system.
    -- Project notes keep their scheduled/due/state via metadata passthrough.
    frontmatter = {
      enabled = true,
      func = function(note)
        local out = {}
        if note.tags and #note.tags > 0 then
          out.tags = note.tags
        end
        if note.metadata then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,
    },

    preferred_link_style = 'wiki',
    legacy_commands = false,

    checkbox = {
      order = { ' ', 'x', '>', '~' },
    },

    attachments = {
      folder = 'attachments',
    },

    ui = {
      enable = true,
      checkboxes = {
        [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
        ['x'] = { char = '', hl_group = 'ObsidianDone' },
        ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
        ['~'] = { char = '󰰱', hl_group = 'ObsidianTilde' },
      },
      external_link_icon = { char = '', hl_group = 'ObsidianExtLinkIcon' },
      reference_text = { hl_group = 'ObsidianRefText' },
      highlight_text = { hl_group = 'ObsidianHighlightText' },
      tags = { hl_group = 'ObsidianTag' },
    },
  },

  config = function(_, opts)
    -- Filter out workspaces whose paths don't exist on this machine
    opts.workspaces = vim.tbl_filter(function(ws)
      return vim.fn.isdirectory(vim.fn.expand(ws.path)) == 1
    end, opts.workspaces or {})

    if #opts.workspaces == 0 then
      vim.notify('obsidian.nvim: no valid workspace directories found, skipping setup', vim.log.levels.WARN)
      return
    end

    require('obsidian').setup(opts)

    vim.api.nvim_create_user_command('NewProject', function(cmd_opts)
      local name = cmd_opts.args
      if name == '' then
        vim.ui.input({ prompt = 'Project name: ' }, function(input)
          if input and input ~= '' then
            create_project(input)
          end
        end)
      else
        create_project(name)
      end
    end, {
      nargs = '?',
      desc = 'Create a new project note',
    })
  end,

  keys = {
    -- Create and navigate
    { '<localleader>n', '<cmd>Obsidian new<cr>', desc = 'Zettel: New note' },
    { '<localleader>s', '<cmd>Obsidian quick_switch<cr>', desc = 'Zettel: Quick switch' },
    { '<localleader>f', '<cmd>Obsidian search<cr>', desc = 'Zettel: Find/Search' },
    { '<localleader>P', '<cmd>NewProject<cr>', desc = 'Zettel: New project' },

    -- Links and navigation
    { 'gf', '<cmd>Obsidian follow_link<cr>', desc = 'Zettel: Follow link', ft = 'markdown' },
    { '<localleader>b', '<cmd>Obsidian backlinks<cr>', desc = 'Zettel: Backlinks' },

    -- Organization
    { '<localleader>g', '<cmd>Obsidian tags<cr>', desc = 'Zettel: Tags' },
    { '<localleader>c', '<cmd>Obsidian toggle_checkbox<cr>', desc = 'Zettel: Toggle checkbox', ft = 'markdown' },

    -- Templates and media
    { '<localleader>p', '<cmd>Obsidian template<cr>', desc = 'Zettel: Paste template' },
    { '<localleader>i', '<cmd>Obsidian paste_img<cr>', desc = 'Zettel: Insert image' },

    -- File operations
    { '<localleader>r', '<cmd>Obsidian rename<cr>', desc = 'Zettel: Rename note' },
    { '<localleader>o', '<cmd>Obsidian open<cr>', desc = 'Zettel: Open in Obsidian app' },

    -- Daily notes
    { '<localleader>t', '<cmd>Obsidian today<cr>', desc = 'Zettel: Today' },
    { '<localleader>y', '<cmd>Obsidian yesterday<cr>', desc = 'Zettel: Yesterday' },
    { '<localleader>m', '<cmd>Obsidian tomorrow<cr>', desc = 'Zettel: Tomorrow' },

    -- Visual mode operations
    { '<localleader>x', ":<C-u>'<,'>Obsidian extract_note<cr>", desc = 'Zettel: Extract to new note', mode = 'v' },
    { '<localleader>l', ":<C-u>'<,'>Obsidian link<cr>", desc = 'Zettel: Link selection', mode = 'v' },
    { '<localleader>N', ":<C-u>'<,'>Obsidian link_new<cr>", desc = 'Zettel: New note from selection', mode = 'v' },
  },
}
