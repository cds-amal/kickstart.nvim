return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  event = {
    'BufReadPre ' .. vim.fn.expand '~' .. '/zettelkasten/**.md',
    'BufNewFile ' .. vim.fn.expand '~' .. '/zettelkasten/**.md',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'saghen/blink.cmp', -- for completion
  },
  opts = {
    workspaces = {
      {
        name = 'zettelkasten',
        path = '~/zettelkasten',
      },
    },

    -- Daily notes configuration
    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      alias_format = '%B %-d, %Y',
      template = nil, -- Optional: set to template name for daily notes
    },

    -- Completion configuration for blink.cmp
    completion = {
      nvim_cmp = false, -- Disable nvim-cmp
      -- blink.cmp will automatically pick up obsidian sources
    },

    -- Template configuration
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
      -- Substitutions for templates
      substitutions = {},
    },

    -- Note ID generation (for new notes)
    note_id_func = function(title)
      -- Use timestamp-based IDs: YYYYMMDDHHMMSS-title
      local suffix = ''
      if title ~= nil then
        suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        -- If no title, just use timestamp
        suffix = 'untitled'
      end
      return tostring(os.time()) .. '-' .. suffix
    end,

    -- Note frontmatter (new API)
    frontmatter = {
      func = function(note)
        local out = {
          id = note.id,
          aliases = note.aliases,
          tags = note.tags,
          created = os.date '%Y-%m-%d %H:%M',
        }
        -- Add title if it exists
        if note.title then
          out.title = note.title
        end
        return out
      end,
    },

    -- Preferred link style: use [[wiki-links]]
    preferred_link_style = 'wiki',

    -- Disable some features that might conflict
    disable_frontmatter = false,

    -- Use new command format (not legacy)
    legacy_commands = false,

    -- Checkbox order
    checkbox = {
      order = { ' ', 'x', '>', '~' },
    },

    -- Markdown link handling
    follow_url_func = function(url)
      vim.fn.jobstart { 'xdg-open', url }
    end,

    -- Image handling
    attachments = {
      img_folder = 'attachments',
    },

    -- UI configuration
    ui = {
      enable = true,
      -- Note: ui.checkboxes no longer affects order (use checkbox.order above)
      -- This config only affects visual rendering
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

  -- Keymaps using <localleader> for zettelkasten commands
  keys = {
    -- Daily notes
    { '<localleader>t', '<cmd>Obsidian today<cr>', desc = 'Zettel: Today' },
    { '<localleader>y', '<cmd>Obsidian yesterday<cr>', desc = 'Zettel: Yesterday' },
    { '<localleader>m', '<cmd>Obsidian tomorrow<cr>', desc = 'Zettel: Tomorrow' },

    -- Create and navigate
    { '<localleader>n', '<cmd>Obsidian new<cr>', desc = 'Zettel: New note' },
    { '<localleader>s', '<cmd>Obsidian quick_switch<cr>', desc = 'Zettel: Quick switch' },
    { '<localleader>f', '<cmd>Obsidian search<cr>', desc = 'Zettel: Find/Search' },

    -- Links and navigation
    { 'gf', '<cmd>Obsidian follow_link<cr>', desc = 'Zettel: Follow link', ft = 'markdown' },
    { 'gb', '<C-o>', desc = 'Zettel: Go back', ft = 'markdown' },
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

    -- Visual mode operations (using :<C-u> to properly handle range)
    { '<localleader>x', ":<C-u>'<,'>Obsidian extract_note<cr>", desc = 'Zettel: Extract to new note', mode = 'v' },
    { '<localleader>l', ":<C-u>'<,'>Obsidian link<cr>", desc = 'Zettel: Link selection', mode = 'v' },
    { '<localleader>N', ":<C-u>'<,'>Obsidian link_new<cr>", desc = 'Zettel: New note from selection', mode = 'v' },
  },
}
