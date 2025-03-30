vim.filetype.add {
  extension = {
    tx = 'hcl', -- *.tx files get 'hcl' filetype
  },
  -- filename = {
  --   ["Jenkinsfile"] = "groovy",  -- exact filename match
  -- },
  pattern = {
    ['.*%.env%..*'] = 'sh', -- regex-like pattern
  },
}
