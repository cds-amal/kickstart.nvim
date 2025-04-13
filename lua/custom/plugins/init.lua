-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  require 'custom.plugins.telescope.multigrep',
  require 'custom.plugins.ai.codecompanion',

  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup()
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  -- 'sigmasd/deno-nvim',
  {
    'Wansmer/treesj',
    keys = { '<leader>m', '<leader>j', '<leader>s' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' }, -- if you install parsers with `nvim-treesitter`
    config = function()
      require('treesj').setup {
        langs = {
          javascript = {
            array = {},
            object = {},
            ['function'] = { target_nodes = {} },
          },
        },
      }
    end,
  },
  {
    'LeonHeidelbach/trailblazer.nvim',
    config = function()
      require('trailblazer').setup {}
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
    opts = {},
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    ft = { 'markdown' },
  },
  --- nvim v0.8.0
  {
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },
  --'tpope/vim-fugitive',
  {
    'jake-stewart/auto-cmdheight.nvim',
    lazy = false,
    opts = {
      -- max cmdheight before displaying hit enter prompt.
      max_lines = 5,

      -- number of seconds until the cmdheight can restore.
      duration = 2,

      -- whether key press is required to restore cmdheight.
      remove_on_key = true,

      -- always clear the cmdline after duration and key press.
      -- by default it will only happen when cmdheight changed.
      clear_always = false,
    },
  },
  {
    'f-person/git-blame.nvim',
    -- load the plugin at startup
    event = 'VeryLazy',
    -- Because of the keys part, you will be lazy loading this plugin.
    -- The plugin wil only load once one of the keys is used.
    -- If you want to load the plugin at startup, add something like event = "VeryLazy",
    -- or lazy = false. One of both options will work.
    opts = {
      -- your configuration comes here
      -- for example
      enabled = true, -- if you want to enable the plugin
      message_template = ' <summary> • <date> • <author> • <<sha>>', -- template for the blame message, check the Message template section for more options
      date_format = '%m-%d-%Y %H:%M:%S', -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },
    keys = {
      { '<leader>gt', '<cmd>GitBlameToggle<cr>', desc = '[G]it [T]oggle Blame' },
    },
  },
  {
    'swaits/zellij-nav.nvim',
    lazy = true,
    event = 'VeryLazy',
    keys = {
      { '<c-h>', '<cmd>ZellijNavigateLeftTab<cr>', { silent = true, desc = 'navigate left or tab' } },
      { '<c-j>', '<cmd>ZellijNavigateDown<cr>', { silent = true, desc = 'navigate down' } },
      { '<c-k>', '<cmd>ZellijNavigateUp<cr>', { silent = true, desc = 'navigate up' } },
      { '<c-l>', '<cmd>ZellijNavigateRightTab<cr>', { silent = true, desc = 'navigate right or tab' } },
    },
    opts = {},
  },
  {
    'MagicDuck/grug-far.nvim',
    config = function()
      -- optional setup call to override plugin options
      -- alternatively you can set options with vim.g.grug_far = { ... }
      require('grug-far').setup {
        -- options, see Configuration section below
        -- there are no required options atm
        -- engine = 'ripgrep' is default, but 'astgrep' or 'astgrep-rules' can
        -- be specified
      }
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    config = function()
      require('nvim-treesitter.configs').setup {
        build = ':TSUpdate',
        textobjects = {
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          },
          select = {
            enable = true,

            -- Automatically jump forward to textobjects, similar to targets.vim
            lookahead = true,

            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              -- you can optionally set descriptions to the mappings (used in the desc parameter of nvim_buf_set_keymap
              ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class region' },
            },
            -- You can choose the select mode (default is charwise 'v')
            selection_modes = {
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V', -- linewise
              ['@class.outer'] = '<c-v>', -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`. Can also be a function (see above).
            include_surrounding_whitespace = false,
          },
        },
      }
    end,
  },
}

-- install with yarn or npm
