vim.filetype.add {
  extension = {
    tx = 'hcl', -- *.tx files get 'hcl' filetype
    txtx = 'txtx', -- *.txtx files get 'txtx' filetype
  },
  -- filename = {
  --   ["Jenkinsfile"] = "groovy",  -- exact filename match
  -- },
  pattern = {
    ['.*%.env%..*'] = 'sh', -- regex-like pattern
  },
}
