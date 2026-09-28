-- rest.nvim pulls its Lua deps (nvim-nio, mimetypes, xml2lua, fidget,
-- tree-sitter-http) as luarocks via lazy.nvim's rockspec support.
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
