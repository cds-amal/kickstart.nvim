-- Test script to verify DAP setup
-- Run this with :luafile %

local dap = require('dap')

print("=== DAP Debug Info ===")
print("Go adapter exists:", dap.adapters.go ~= nil)

if dap.adapters.go then
  print("Adapter type:", vim.inspect(dap.adapters.go))
end

print("\nGo configurations count:", dap.configurations.go and #dap.configurations.go or 0)

if dap.configurations.go then
  for i, config in ipairs(dap.configurations.go) do
    print("Config " .. i .. ":", config.name)
  end
end

print("\nDelve executable path:", vim.fn.exepath('dlv'))
print("Delve exists:", vim.fn.executable('dlv') == 1)

-- Try to manually set up if missing
if not dap.adapters.go then
  print("\n!!! Setting up adapter manually !!!")
  dap.adapters.go = {
    type = 'server',
    port = '${port}',
    executable = {
      command = 'dlv',
      args = {'dap', '-l', '127.0.0.1:${port}'},
      detached = true,
    },
  }
  print("Adapter created")
end

-- Ensure basic config exists
if not dap.configurations.go or #dap.configurations.go == 0 then
  print("\n!!! Setting up configurations manually !!!")
  dap.configurations.go = {
    {
      type = 'go',
      name = 'Debug',
      request = 'launch',
      program = '${file}',
    },
  }
  print("Configuration created")
end

print("\n=== Setup Complete ===")
print("Try debugging with :DapContinue or <F5>")