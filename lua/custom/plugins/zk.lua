return {
  'zk-org/zk-nvim',
  config = function()
    local zk_notes_path = vim.fn.expand('~/ZKNOTES')

    require('zk').setup {
      -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
      -- or select" (`vim.ui.select`).
      picker = 'select',

      lsp = {
        -- `config` is passed to `vim.lsp.start(config)`
        config = {
          name = 'zk',
          cmd = { 'zk', 'lsp' },
          filetypes = { 'markdown' },
          root_dir = function(fname)
            -- Only attach if file is in ~/ZKNOTES directory
            local abs_fname = vim.fn.fnamemodify(fname, ':p')
            local abs_zknotes = vim.fn.fnamemodify(zk_notes_path, ':p')

            -- Check if the file starts with the ZKNOTES path
            if abs_fname:sub(1, #abs_zknotes) == abs_zknotes then
              return abs_zknotes
            end

            -- Return nil to prevent LSP from starting
            return nil
          end,
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start()`
        },

        -- auto_attach will only work when root_dir returns a valid path
        auto_attach = {
          enabled = true,
          filetypes = { 'markdown' },
        },
      },
    }

    -- Override all Zk commands to operate in ~/ZKNOTES
    local zk_commands = require('zk.commands')
    local original_make_command = zk_commands.make_command

    -- Wrap the make_command function to inject notebook_path
    zk_commands.make_command = function(name, fn_key)
      local original_fn = zk_commands.get(name)

      vim.api.nvim_create_user_command(name, function(opts)
        -- Inject the notebook_path into options
        local options = opts.fargs and vim.tbl_extend('force', opts, { notebook_path = zk_notes_path }) or { notebook_path = zk_notes_path }
        original_fn(opts, options)
      end, {
        nargs = '*',
        range = true,
        desc = 'Zk command (operates in ~/ZKNOTES)',
      })
    end

    -- Re-create all zk commands with the wrapper
    for _, cmd_name in ipairs({
      'ZkNew',
      'ZkNewFromTitleSelection',
      'ZkNewFromContentSelection',
      'ZkCd',
      'ZkNotes',
      'ZkBacklinks',
      'ZkLinks',
      'ZkInsertLink',
      'ZkInsertLinkAtSelection',
      'ZkMatch',
      'ZkTags',
    }) do
      zk_commands.make_command(cmd_name)
    end
  end,
}
