⏺ Summary of DAP/Delve Configuration Updates

  I've significantly enhanced your Go debugging setup with Delve:

  1. Extended Keymaps (debug.lua:31-191)

  - Function Keys: F1-F7 for basic debugging (step in/over/out, continue, terminate, REPL, UI toggle)
  - Leader Keys: <leader>d* prefix for advanced debugging:
    - <leader>dr: Restart debugging session
    - <leader>dl: Run last debug configuration
    - <leader>dc: Run to cursor
    - <leader>dh: Hover variables
    - <leader>dp: Preview expressions
    - <leader>df: View call frames
    - <leader>ds: View scopes
    - <leader>dt: Debug Go test at cursor
    - <leader>dT: Debug last Go test

  2. Enhanced DAP UI Layout (debug.lua:237-269)

  - Left Panel (40% width): Scopes, Breakpoints, Call Stack, Watches
  - Bottom Panel (10 lines): REPL and Console output
  - Floating Windows: Rounded borders with q/Esc to close
  - Better Rendering: Up to 100 value lines for complex objects

  3. Go-Specific Debug Configurations (debug.lua:289-360)

  Multiple debug launch configurations:
  - Standard: Debug current file/package
  - Remote Attach: Connect to running Delve server
  - Test Debugging: Debug tests in current directory
  - With Arguments: Prompt for program arguments
  - With Environment: Set custom environment variables
  - Package Debug: Debug entire package

  4. Visual Enhancements (debug.lua:284-294)

  - Enabled breakpoint icons (red dots for breakpoints, yellow for stopped position)
  - Color-coded indicators for different breakpoint types
  - Support for conditional breakpoints and log points

  5. Delve Configuration (debug.lua:305-317)

  - Auto-detects Windows for attached mode
  - 20-second initialization timeout
  - Dynamic port allocation
  - Support for custom build flags and arguments

  Usage:

  1. Start Debugging: Open a Go file and press <F5> or use <leader>dt for tests
  2. Set Breakpoints: Use <leader>b to toggle breakpoints
  3. Navigate: Use F1-F3 for stepping, <leader>dc to run to cursor
  4. Inspect: Use <leader>dh to hover over variables
  5. UI: Press <F7> to toggle the debug UI panels

  The configuration now provides a comprehensive debugging experience for Go with proper Delve integration, visual feedback, and extensive
  keyboard shortcuts.
