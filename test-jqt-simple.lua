-- Simple test script for jq-treesitter
local test_json = [[{
  "abi": [
    {
      "type": "function",
      "name": "modifyAllocations"
    }
  ]
}]]

-- Create a test buffer
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(test_json, '\n'))
vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
vim.api.nvim_set_current_buf(buf)

-- Test the plugin
print("Testing JqtList with simple JSON...")
vim.cmd('JqtList')

-- Print location list contents
local items = vim.fn.getloclist(0)
print("Location list items:", #items)
for i, item in ipairs(items) do
  print("  Item", i, ":", item.text, "at line", item.lnum)
end