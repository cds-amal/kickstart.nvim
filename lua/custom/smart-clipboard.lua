-- Smart clipboard configuration that works both locally and over SSH
local M = {}

function M.setup()
  -- Skip if ojroques/nvim-osc52 plugin will handle clipboard
  -- The plugin is loaded after this, so we check if it's in the plugin list
  local has_osc52_plugin = false
  local ok, lazy = pcall(require, 'lazy.core.config')
  if ok and lazy.plugins and lazy.plugins['nvim-osc52'] then
    has_osc52_plugin = true
  end
  
  if vim.env.SSH_CONNECTION and has_osc52_plugin then
    -- Let ojroques/nvim-osc52 handle clipboard
    vim.opt.clipboard = 'unnamedplus'
    return
  end
  
  -- Check if we're in an SSH session
  if vim.env.SSH_CONNECTION then
    -- OSC52 clipboard for SSH sessions
    local function osc52_copy(lines)
      local text = table.concat(lines, '\n')
      local base64 = vim.base64.encode(text)
      
      -- Use different OSC52 format depending on environment
      local osc52
      if vim.env.ZELLIJ then
        -- Zellij uses ESC\ terminator, not BEL
        osc52 = string.format('\027]52;c;%s\027\\', base64)
      else
        -- Standard OSC52 with BEL terminator
        osc52 = string.format('\027]52;c;%s\007', base64)
      end
      
      -- Handle tmux wrapping if needed
      if vim.env.TMUX then
        osc52 = string.format('\027Ptmux;\027%s\027\\', osc52)
      end
      
      -- Write OSC52 sequence to stderr
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
      local msg = 'OSC52 clipboard enabled for SSH'
      if vim.env.ZELLIJ then
        msg = msg .. ' (inside Zellij - may not work due to forwarding issues)'
        vim.notify(msg, vim.log.levels.WARN)
        vim.notify('Alternative: Use Ctrl+Shift+Space for Zellij copy mode', vim.log.levels.INFO)
      else
        vim.notify(msg, vim.log.levels.INFO)
      end
    end, 100)
  end
  
  -- Always set clipboard to unnamedplus
  vim.opt.clipboard = 'unnamedplus'
end

return M