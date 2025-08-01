-- Smart clipboard configuration that works both locally and over SSH
local M = {}

function M.setup()
  -- Check if we're in an SSH session
  if vim.env.SSH_CONNECTION then
    -- OSC52 clipboard for SSH sessions
    local function osc52_copy(lines)
      local text = table.concat(lines, '\n')
      local base64 = vim.base64.encode(text)
      local osc52 = string.format('\027]52;c;%s\007', base64)
      
      -- Handle tmux wrapping if needed
      if vim.env.TMUX then
        osc52 = string.format('\027Ptmux;\027%s\027\\', osc52)
      end
      
      -- Write to stderr (most reliable for SSH)
      pcall(function()
        io.stderr:write(osc52)
        io.stderr:flush()
      end)
    end
    
    vim.g.clipboard = {
      name = 'OSC52',
      copy = {
        ['+'] = osc52_copy,
        ['*'] = osc52_copy,
      },
      paste = {
        ['+'] = function() return {}, 'v' end,
        ['*'] = function() return {}, 'v' end,
      },
    }
    
    vim.defer_fn(function()
      vim.notify('OSC52 clipboard enabled for SSH', vim.log.levels.INFO)
    end, 100)
  end
  
  -- Always set clipboard to unnamedplus
  vim.opt.clipboard = 'unnamedplus'
end

return M