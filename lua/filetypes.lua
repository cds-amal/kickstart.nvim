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
  },
}
