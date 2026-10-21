return {
  { -- Install and manage tree-sitter parsers (highlighting/indent are built into Neovim 0.12+)
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      vim.treesitter.language.register('bash', 'zsh')
      vim.treesitter.language.register('tlaplus', 'tla')
      require('nvim-treesitter').install {
        'bash',
        'c',
        'css',
        'cue',
        'diff',
        'html',
        'http',
        'javascript',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'rust',
        'svelte',
        'tlaplus',
        'typescript',
        'vim',
        'vimdoc',
      }

      -- Scopes after/queries/html/injections.scm to Claude Code's prompt
      -- buffer (filetype markdown.claudeprompt): there the markdown parser
      -- hands the whole <prompt> block to html, which captures section
      -- bodies as @none, and the query injects markdown back into them.
      -- Registered here, not in a ftplugin: Neovim validates predicate names
      -- when a query compiles, so an .html file opened before any prompt
      -- buffer would otherwise lose every html injection. The source is a
      -- string, not a buffer number, under get_string_parser (plugins parse
      -- html and markdown strings for menus and previews), and a string has
      -- no filetype. `force` lets :Lazy reload re-register without an error.
      vim.treesitter.query.add_predicate('claudeprompt?', function(_, _, source)
        return type(source) == 'number' and vim.bo[source].filetype:find('claudeprompt', 1, true) ~= nil
      end, { force = true })

      -- Neovim only auto-starts treesitter highlighting for the filetypes
      -- whose bundled ftplugin does so (lua, help, markdown, query); the
      -- nvim-treesitter main branch never does it for you. Everything else
      -- here still looked highlighted only because a legacy syntax/*.vim
      -- ships in the runtime, which svelte lacks. Start the highlighter for
      -- any buffer that has an installed parser.
      --
      -- Require the highlights query too, not just the parser. Starting the
      -- highlighter switches the legacy syntax off, so a parser with no
      -- queries (a parser/ dir left over from the master branch, say)
      -- would leave the buffer with no highlighting at all.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('ts-highlight', { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and pcall(vim.treesitter.get_parser, args.buf, lang) and vim.treesitter.query.get(lang, 'highlights') then
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end,
      })

      -- Use treesitter's AST-aware indentexpr wherever a parser AND indent
      -- queries are both available. Without the queries check, a parser with
      -- no indents.scm makes indentexpr return 0, sending <CR> to column 0.
      -- Queries are keyed by parser language, not filetype, so resolve
      -- through the alias table (zsh->bash, tla->tlaplus).
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('ts-indent', { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and pcall(vim.treesitter.get_parser, args.buf) and vim.treesitter.query.get(lang, 'indents') then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = {
          lookahead = true,
          selection_modes = {
            ['@parameter.outer'] = 'v', -- charwise
            ['@function.outer'] = 'V', -- linewise
            ['@class.outer'] = '<c-v>', -- blockwise
          },
          include_surrounding_whitespace = false,
        },
      }

      -- Select keymaps
      local select = require('nvim-treesitter-textobjects.select').select_textobject
      for _, m in ipairs {
        { 'af', '@function.outer', 'outer function' },
        { 'if', '@function.inner', 'inner function' },
        { 'ac', '@class.outer', 'outer class' },
        { 'ic', '@class.inner', 'inner class' },
      } do
        vim.keymap.set({ 'x', 'o' }, m[1], function()
          select(m[2], 'textobjects')
        end, { desc = m[3] })
      end

      -- Swap keymaps
      local swap = require 'nvim-treesitter-textobjects.swap'
      vim.keymap.set('n', '<leader>a', function()
        swap.swap_next '@parameter.inner'
      end, { desc = 'Swap next parameter' })
      vim.keymap.set('n', '<leader>A', function()
        swap.swap_previous '@parameter.inner'
      end, { desc = 'Swap previous parameter' })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    enabled = false, -- disabled until it supports Neovim 0.12
  },
}
