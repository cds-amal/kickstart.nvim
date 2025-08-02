-- Smart clipboard configuration
-- This is now mostly handled by ojroques/nvim-osc52 plugin
-- Kept for backwards compatibility and non-plugin fallback
local M = {}

function M.setup()
  -- Always set clipboard to unnamedplus
  vim.opt.clipboard = 'unnamedplus'
  
  -- The ojroques/nvim-osc52 plugin handles SSH clipboard
  -- This file is kept for potential future enhancements
end

return M