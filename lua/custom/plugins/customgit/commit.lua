--[[
  Git Co-authors Automation for Neovim
  
  This plugin automatically adds co-author trailers to Git commit messages during
  rebases by detecting authors from commits being processed in the rebase.
  
  It runs whenever a COMMIT_EDITMSG buffer is opened and adds "Co-authored-by"
  trailers for any authors (excluding yourself) from commits being rebased.
]]
--

print 'Git co-authors plugin loaded!'

vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = 'COMMIT_EDITMSG',
  callback = function()
    -- Retrieve user's email from git config
    local function get_my_email()
      local handle = io.popen 'git config user.email'
      if not handle then
        vim.notify('Failed to execute git config command', vim.log.levels.WARN)
        return nil
      end
      local email = handle:read '*l'
      handle:close()
      return email
    end

    -- Process commits in rebase todo file
    local function get_commits_from_rebase()
      -- Read from the rebase todo file to get the commits being squashed
      local rebase_todo_paths = {
        '.git/rebase-merge/git-rebase-todo',
        '.git/rebase-apply/git-rebase-todo', -- fallback for older or different modes
      }

      for _, path in ipairs(rebase_todo_paths) do
        local file = io.open(path, 'r')
        if file then
          local commits = {}
          for line in file:lines() do
            -- Extract action and SHA from lines like "pick abc123" or "squash def456"
            local action, sha = line:match '^(%w+)%s+([a-f0-9]+)'
            if action and sha then
              table.insert(commits, sha)
            end
          end
          file:close()
          return commits
        end
      end
      return {}
    end

    -- Extract co-authors from commit history
    local function get_coauthors_from_commits(commits, my_email)
      if #commits == 0 then
        return {}
      end

      local seen = {}
      local coauthors = {}

      for _, sha in ipairs(commits) do
        -- Get author name and email for this commit
        local cmd = string.format("git show -s --format='%%an <%%ae>' %s", sha)
        local handle = io.popen(cmd)

        if handle then
          local author = handle:read '*l'
          handle:close()

          -- Add author if they're not us and haven't been seen yet
          if author and not author:match(my_email, 1, true) and not seen[author] then
            seen[author] = true
            table.insert(coauthors, 'Co-authored-by: ' .. author)
          end
        else
          vim.notify('Failed to execute git show command for ' .. sha, vim.log.levels.WARN)
        end
      end

      table.sort(coauthors)
      return coauthors
    end

    -- Main execution flow
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local my_email = get_my_email()

    if not my_email then
      vim.notify('Could not determine Git user email', vim.log.levels.WARN)
      return
    end

    local commits = get_commits_from_rebase()
    local coauthors = get_coauthors_from_commits(commits, my_email)

    -- Avoid adding duplicate co-author trailers
    local existing = {}
    for _, line in ipairs(lines) do
      local match = line:match '^Co%-authored%-by: (.+)$'
      if match then
        existing[match] = true
      end
    end

    -- Collect new co-authors to add
    local to_add = {}
    for _, trailer in ipairs(coauthors) do
      local who = trailer:match '^Co%-authored%-by: (.+)$'
      if not existing[who] then
        table.insert(to_add, trailer)
      end
    end

    -- Add co-authors to commit message if any were found
    if #to_add > 0 then
      -- Ensure there's a blank line before trailers if the message has content
      if lines[#lines]:match '%S' then
        table.insert(lines, '')
      end

      vim.list_extend(lines, to_add)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      vim.notify('Added ' .. #to_add .. ' co-author(s) to commit message', vim.log.levels.INFO)
    end
  end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
