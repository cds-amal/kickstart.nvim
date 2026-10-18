return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    -- Around/Inside textobjects: va) yinq ci'
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings: saiw) sd' sr)'
    require('mini.surround').setup {
      -- Linewise adds (V sa, or a linewise motion like sa_ / sa2j) place
      -- each delimiter on its own line and indent the wrapped lines;
      -- charwise adds stay inline. Prefer `}` over `{` for linewise braces:
      -- the `{` builtin pads with inner spaces, which linewise placement
      -- turns into a trailing space after the brace.
      respect_selection_type = true,
      custom_surroundings = {

        -- - saiw c - surround inner word with console code fence
        -- - sa2j c - surround current line and next line with console code fence
        -- - In visual mode: select your text, then sa c
        ['c'] = {
          output = { left = '```console\n', right = '\n```' },
        },
        ['r'] = {
          output = { left = '```rust\n', right = '\n```' },
        },
        ['C'] = {
          output = { left = '/*\n', right = '\n*/' },
        },

        -- - V sa l (or sa_ l) - wrap line(s) in an indented `loop { }` block
        ['l'] = {
          output = { left = 'loop {', right = '}' },
        },
      },
    }

    -- The fence surrounds above embed `\n` in their output, which only
    -- works through the charwise insert path: the linewise branch that
    -- respect_selection_type enables feeds the string to `append()`, where
    -- the `\n` becomes a literal NUL, and the fenced lines pick up an
    -- indent level they shouldn't have. Keep the old behavior in markdown,
    -- where the fences live.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        vim.b.minisurround_config = { respect_selection_type = false }
      end,
      desc = 'Inline surround adds in markdown (fence surrounds embed \\n)',
    })

    -- Disable mini.operators' `replace` operator: its default `gr` prefix
    -- collides with Neovim 0.11+'s reserved LSP namespace (grD, grr, gri,
    -- gra, grn, ...). Keeping the other operators on their defaults.
    require('mini.operators').setup { replace = { prefix = '' } }

    -- Auto-pair brackets/quotes (replaces nvim-autopairs)
    require('mini.pairs').setup()

    -- mini.pairs maps <CR> without remapping, and a key that is not
    -- remapped skips abbreviation expansion, so `def@<CR>` would keep its
    -- `def@`. <C-]> is exempt from that rule: it expands a pending
    -- abbreviation and inserts nothing, so it goes in front.
    vim.keymap.set('i', '<CR>', function()
      return vim.keycode '<C-]>' .. require('mini.pairs').cr()
    end, { expr = true, replace_keycodes = false, desc = 'Expand abbreviation, then MiniPairs <CR>' })

    -- Don't autopair `'` in Rust buffers. mini.pairs' neigh_pattern guard
    -- (skip when preceded by a letter) handles English contractions, but a
    -- lifetime `'a` is preceded by `<`, `&`, `,`, etc., so it slips through
    -- and you get `<'info'>`. `'` is a global mapping, so the documented way
    -- to revert it for a buffer is to shadow it with a buffer-local mapping
    -- that just inserts the literal quote. (Costs nothing: the `closeopen`
    -- autopair saved no keystrokes for char literals anyway.)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'rust',
      desc = "Disable mini.pairs ' autopairing for Rust lifetimes",
      callback = function(args)
        vim.keymap.set('i', "'", "'", { buffer = args.buf })
      end,
    })

    require('mini.comment').setup {
      options = {
        custom_commentstring = function(ref_position)
          -- Get current buffer's filetype
          local ft = vim.bo.filetype

          -- For Cue files, use the appropriate comment string
          if ft == 'cue' or ft == 'hcl' then
            return '// %s'
          end

          -- For embedded Cue code in other files, check the tree-sitter context
          if vim.fn.has 'nvim-0.9' == 1 then
            local has_parser, parser = pcall(vim.treesitter.get_parser, 0)
            if has_parser and parser then
              -- Check if we're in Cue language context at the reference position
              local row, col = ref_position[1] - 1, ref_position[2] - 1
              local lang_tree = parser:language_for_range { row, col, row, col + 1 }
              if lang_tree and lang_tree:lang() == 'cue' then
                return '// %s'
              end
            end
          end

          -- For other cases, use the default detection
          return nil
        end,
      },
    }

    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }

    -- Cursor location as LINE:COLUMN, prefixed with plugin activity.
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      -- The plugins' runs out (`⟳ roots surfpool 14s`, `⟳ events google 2s`) ahead of
      -- the cursor position while a projection, the roots list, a calendar page or a
      -- create is being waited on; each plugin redraws the statusline once a second
      -- while anything of its own is out.
      local has_crosscut, crosscut = pcall(require, 'crosscut')
      local has_calplus, calplus = pcall(require, 'calplus')
      local segments = {}
      for _, segment in ipairs { has_crosscut and crosscut.activity() or '', has_calplus and calplus.activity() or '' } do
        if segment ~= '' then
          segments[#segments + 1] = segment
        end
      end
      local activity = table.concat(segments, ' · ')
      if activity ~= '' then
        return activity:gsub('%%', '%%%%') .. '  %2l:%-2v'
      end
      return '%2l:%-2v'
    end

    -- Explicit split and join instead of mini's single toggle: gS is the
    -- toggle's default key, reused here for split, and gJ shadows Vim's
    -- join-without-spaces, which the treesitter-aware join supersedes.
    -- treesj keeps its own <space>m/j/s family for node-aware splits.
    require('mini.splitjoin').setup {
      mappings = {
        toggle = '',
        split = 'gS',
        join = 'gJ',
      },
    }
  end,
}
