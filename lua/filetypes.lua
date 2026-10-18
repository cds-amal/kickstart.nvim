vim.filetype.add {
  extension = {
    tx = 'txtx', -- *.tx files get 'txtx' filetype
    txtx = 'txtx', -- *.txtx files get 'txtx' filetype
    -- PlantUML sources. Neovim has no built-in detection for these, so the
    -- preview.nvim `ft = 'plantuml'` trigger (and syntax) won't fire without it.
    puml = 'plantuml',
    plantuml = 'plantuml',
    pu = 'plantuml',
    iuml = 'plantuml',
    -- TLA+ specs. The treesitter alias (tla -> tlaplus) lives in the
    -- nvim-treesitter spec.
    tla = 'tla',
  },
  -- filename = {
  --   ["Jenkinsfile"] = "groovy",  -- exact filename match
  -- },
  pattern = {
    ['.*%.env%..*'] = 'sh', -- regex-like pattern
    -- Claude Code's C-x C-e editor file: <tmp>/claude-<uid>/claude-prompt-<hex>.md
    -- (<hex> is a UUID or a 16-char content hash). The compound filetype keeps
    -- the markdown ftplugin, treesitter highlighting and indent, and makes
    -- LuaSnip load lua/snippets/claudeprompt.lua on top. Lazy specs and
    -- FileType autocmds keyed on plain 'markdown' (md-table-mode, touchup,
    -- preview) do not fire here, which suits a throwaway prompt buffer. The
    -- name is the only marker the file carries.
    ['.*/claude%-prompt%-[%x%-]+%.md'] = 'markdown.claudeprompt',
  },
}
