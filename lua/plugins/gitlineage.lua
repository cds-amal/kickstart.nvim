return {
  'LionyxML/gitlineage.nvim',
  dependencies = {
    -- the maintained fork; same module names, see plugins/diffview.lua
    'dlyongemallo/diffview-plus.nvim',
  },
  config = function()
    require('gitlineage').setup {
      -- The default <leader>gl runs git in nvim's global cwd, so a buffer
      -- from any other repo is reported as untracked. Disabled here and
      -- rebound below with a cwd fix.
      keymap = false,
      keys = {
        next_commit = ']h',
        prev_commit = '[h',
      },
    }

    -- lcd to the file's repo root so gitlineage's git calls hit the file's
    -- repo. The root specifically: the plugin passes root-relative paths to
    -- git, and pathspecs resolve against cwd. The lineage split inherits the
    -- local cwd, which also keeps the <CR> diffview binding pointed at the
    -- right repo; the original window's cwd state is restored afterwards.
    vim.keymap.set({ 'n', 'v' }, '<leader>gl', function()
      local gitlineage = require 'gitlineage'
      local file = vim.api.nvim_buf_get_name(0)
      local root = file ~= '' and vim.fs.root(file, '.git') or nil
      if not root then
        -- no file or no repo: let the plugin produce its own diagnostics
        return gitlineage.show_history()
      end

      local win = vim.api.nvim_get_current_win()
      local prev_cwd = vim.fn.getcwd(win)
      local had_local = vim.fn.haslocaldir(win) == 1
      vim.cmd.lcd(vim.fn.fnameescape(root))

      local ok, err = pcall(gitlineage.show_history)

      -- Restore the original window's cwd state. A real window switch, on
      -- purpose: nvim_win_call snapshots the effective cwd and "restores" it
      -- on exit with a global chdir, so any :cd/:lcd inside it clobbers the
      -- global cwd.
      local cur = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        if had_local then
          vim.cmd.lcd(vim.fn.fnameescape(prev_cwd))
        else
          -- :cd is the only way to drop the window-local dir the lcd above
          -- created; prev_cwd is the (untouched) global cwd, so this
          -- re-asserts it unchanged
          vim.cmd.cd(vim.fn.fnameescape(prev_cwd))
        end
        if cur ~= win and vim.api.nvim_win_is_valid(cur) then
          vim.api.nvim_set_current_win(cur)
        end
      end

      if not ok then
        error(err)
      end
    end, { desc = 'Git history for selected lines' })
  end,
}
