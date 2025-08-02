-- Workaround for OSC52 clipboard in Zellij over SSH
local M = {}

function M.setup()
  -- Only setup if in SSH session
  if not vim.env.SSH_CONNECTION then
    return
  end

  local function osc52_copy(lines)
    local text = table.concat(lines, '\n')
    local base64 = vim.base64.encode(text)
    
    -- When inside Zellij over SSH, we need to be more creative
    if vim.env.ZELLIJ then
      -- Zellij might be intercepting or modifying escape sequences
      -- Try different approaches
      
      -- Approach 1: Use Zellij's action system to write to stdout
      -- This bypasses some of Zellij's processing
      local escaped_osc52 = string.format('\027]52;c;%s\007', base64)
      
      -- Write to a temp file and then cat it
      -- This ensures the raw bytes get through
      local tmpfile = os.tmpname()
      local f = io.open(tmpfile, 'wb')
      if f then
        f:write(escaped_osc52)
        f:close()
        os.execute('cat ' .. tmpfile .. ' >&2')
        os.remove(tmpfile)
      end
    else
      -- Standard SSH without Zellij - use normal OSC52
      local osc52 = string.format('\027]52;c;%s\007', base64)
      
      if vim.env.TMUX then
        osc52 = string.format('\027Ptmux;\027%s\027\\', osc52)
      end
      
      io.stderr:write(osc52)
      io.stderr:flush()
    end
  end

  vim.g.clipboard = {
    name = 'OSC52_Zellij_Workaround',
    copy = {
      ['+'] = osc52_copy,
      ['*'] = osc52_copy,
    },
    paste = {
      ['+'] = function() return {}, 'v' end,
      ['*'] = function() return {}, 'v' end,
    },
  }

  vim.opt.clipboard = 'unnamedplus'
  
  vim.defer_fn(function()
    local env = {}
    if vim.env.ZELLIJ then table.insert(env, 'Zellij') end
    if vim.env.SSH_CONNECTION then table.insert(env, 'SSH') end
    vim.notify('OSC52 workaround enabled for: ' .. table.concat(env, '+'), vim.log.levels.INFO)
  end, 100)
end

return M