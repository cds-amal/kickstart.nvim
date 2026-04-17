local M = {}

M.copy_with_virtual_text = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local mode = vim.fn.mode()
  local start_line, end_line

  if mode == 'v' or mode == 'V' then
    vim.cmd 'normal! <Esc>' -- exit visual mode
    local _, s_lnum, _, _ = unpack(vim.fn.getpos "'<")
    local _, e_lnum, _, _ = unpack(vim.fn.getpos "'>")
    start_line = math.min(s_lnum, e_lnum) - 1
    end_line = math.max(s_lnum, e_lnum)
  else
    start_line = 0
    end_line = vim.api.nvim_buf_line_count(bufnr)
  end

  local ns_ids = vim.api.nvim_get_namespaces()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  local output = {}

  for i, line in ipairs(lines) do
    local lnum = start_line + i - 1
    local virt_texts = {}

    for _, ns in pairs(ns_ids) do
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { lnum, 0 }, { lnum, -1 }, { details = true })
      for _, mark in ipairs(extmarks) do
        local vt = mark[4].virt_text
        if vt then
          -- print('VIRT:', vim.inspect(vt))
          for _, chunk in ipairs(vt) do
            local text = chunk[1]
            -- Remove lines with *only* symbols or whitespace
            if text:match '[%w%p]' and not text:match '^%s*[▎│┃╏┆]?$' then
              table.insert(virt_texts, text)
            end
          end
        end
      end
    end

    local virt = #virt_texts > 0 and ('  ▶ ' .. table.concat(virt_texts, ' | ')) or ''
    table.insert(output, string.format('%s%s', line, virt))
  end

  vim.cmd 'new'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
end

-- 🔑 Keymap (normal + visual)
vim.keymap.set({ 'n', 'v' }, '<leader>cv', M.copy_with_virtual_text, {
  desc = 'Copy buffer or selection with virtual text',
  silent = true,
})

return M
