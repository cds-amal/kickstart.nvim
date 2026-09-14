-- TLA+ support: a TLC runner and optional Unicode input mappings.
-- Highlighting comes from the nvim-treesitter `tlaplus` parser (installed and
-- aliased to filetype `tla` in init.lua) and is started in ftplugin/tla.lua.
return {
  {
    -- :TlaInstall downloads tla2tools.jar; :TlaCheck runs TLC on the current
    -- buffer; :TlaTranslate runs the PlusCal translator.
    'susliko/tla.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ft = { 'tla' },
    opts = function()
      return {
        -- The plugin only looks at JAVA_HOME, which is unset here; resolve
        -- from PATH so the Homebrew JDK is found.
        java_executable = vim.fn.exepath 'java',
      }
    end,
    config = function(_, opts)
      require('tla').setup(opts)
    end,
  },
  {
    -- Rewrites ASCII operators to Unicode as you type (\in -> ∈). Off by
    -- default so specs stay ASCII like the books and forums; toggle per buffer
    -- with <leader>tm (see ftplugin/tla.lua).
    'tlaplus-community/tlaplus-nvim-plugin',
    ft = { 'tla' },
    init = function()
      vim.g.tlaplus_mappings_enable = false
    end,
  },
}
