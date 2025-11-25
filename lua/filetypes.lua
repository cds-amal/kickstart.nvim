vim.filetype.add {
  extension = {
    tx = 'txtx', -- *.tx files get 'txtx' filetype
    txtx = 'txtx', -- *.txtx files get 'txtx' filetype
  },
  -- filename = {
  --   ["Jenkinsfile"] = "groovy",  -- exact filename match
  -- },
  pattern = {
    ['.*%.env%..*'] = 'sh', -- regex-like pattern
  },
}
