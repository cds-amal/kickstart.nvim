-- Markdown List Workflow
--
-- SNIPPETS (type trigger + Ctrl-y to expand):
--   todo → - [ ]    done → - [x]    arrow → - [>]    tilde → - [~]
--   li   → -        ol   → 1.
--
-- SMART ENTER:
--   - Press Enter on a list item to auto-continue the list
--   - Press Enter on empty list item to exit list mode
--   - Numbered lists auto-increment
--
-- INDENT/DEDENT:
--   Insert mode: Tab/Shift-Tab on list items
--   Normal mode:  Tab/Shift-Tab on any line
--   Visual mode:  Tab/Shift-Tab on selection

-- Smart list continuation on Enter
local function smart_enter()
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Match patterns for different list types
  local checkbox_pattern = "^(%s*)- %[.%]%s+"
  local bullet_pattern = "^(%s*)- %S"
  local numbered_pattern = "^(%s*)(%d+)%. %S"

  -- Check if we're on an empty list item (remove it and exit list mode)
  if line:match("^%s*- %[ %]%s*$") or line:match("^%s*- %[x%]%s*$") or line:match("^%s*- %[>%]%s*$") or line:match("^%s*- %[~%]%s*$") then
    -- Empty checkbox - remove checkbox and exit
    vim.api.nvim_set_current_line("")
    return
  elseif line:match("^%s*- %s*$") then
    -- Empty bullet - exit list
    vim.api.nvim_set_current_line("")
    return
  elseif line:match("^%s*%d+%. %s*$") then
    -- Empty numbered list - exit list
    vim.api.nvim_set_current_line("")
    return
  end

  -- Continue checkbox list
  if line:match(checkbox_pattern) then
    local indent = line:match("^(%s*)")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>" .. indent .. "- [ ] ", true, false, true), "n", false)
    return
  end

  -- Continue bullet list
  if line:match(bullet_pattern) then
    local indent = line:match("^(%s*)")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>" .. indent .. "- ", true, false, true), "n", false)
    return
  end

  -- Continue numbered list
  if line:match(numbered_pattern) then
    local indent, num = line:match("^(%s*)(%d+)%. ")
    num = tonumber(num) + 1
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>" .. indent .. num .. ". ", true, false, true), "n", false)
    return
  end

  -- Default behavior
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
end

-- Keymaps for smart list handling
vim.keymap.set("i", "<CR>", smart_enter, { buffer = true, desc = "Smart list continuation" })

-- Tab/Shift-Tab for indent/dedent in insert mode (only for list items)
vim.keymap.set("i", "<Tab>", function()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*- ") or line:match("^%s*%d+%. ") then
    return "<C-t>" -- Indent
  end
  return "<Tab>" -- Normal tab behavior
end, { buffer = true, expr = true, desc = "Smart indent for lists" })

vim.keymap.set("i", "<S-Tab>", function()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*- ") or line:match("^%s*%d+%. ") then
    return "<C-d>" -- Dedent
  end
  return "<S-Tab>" -- Normal shift-tab behavior
end, { buffer = true, expr = true, desc = "Smart dedent for lists" })

-- Normal mode: Tab/Shift-Tab for indent/dedent
vim.keymap.set("n", "<Tab>", ">>", { buffer = true, desc = "Indent line" })
vim.keymap.set("n", "<S-Tab>", "<<", { buffer = true, desc = "Dedent line" })

-- Visual mode: Tab/Shift-Tab for block indent/dedent (and stay in visual mode)
vim.keymap.set("v", "<Tab>", ">gv", { buffer = true, desc = "Indent selection" })
vim.keymap.set("v", "<S-Tab>", "<gv", { buffer = true, desc = "Dedent selection" })
