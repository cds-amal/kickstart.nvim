-- rest.nvim pulls its Lua deps (nvim-nio, mimetypes, xml2lua, fidget,
-- tree-sitter-http) as luarocks via lazy.nvim's rockspec support.
-- The http parser Neovim actually loads comes from nvim-treesitter
-- (init.lua install list): lazy.nvim puts the rocks tree on package.cpath
-- only, so the luarocks-built parser/http.so is never on the runtimepath.
-- Building the tree-sitter-http rock also needs luarocks-build-treesitter-parser
-- installed in the hererocks tree (lazy-rocks/hererocks), not just the
-- plugin's own rock tree where lazy.nvim puts it.
return {
  'rest-nvim/rest.nvim',
  ft = { 'http' },
  cmd = 'Rest',
  init = function()
    ---@type rest.Opts
    vim.g.rest_nvim = {}
  end,
  keys = {
    { '<leader>Rs', '<cmd>Rest run<cr>', desc = '[R]equest [S]end request under cursor' },
    { '<leader>Rr', '<cmd>Rest last<cr>', desc = '[R]equest [R]eplay last request' },
    { '<leader>Ro', '<cmd>Rest open<cr>', desc = '[R]equest [O]pen result pane' },
    { '<leader>Re', '<cmd>Rest env select<cr>', desc = '[R]equest select [E]nv file' },
    { '<leader>Rl', '<cmd>Rest logs<cr>', desc = '[R]equest [L]ogs' },
  },
}
