# AGENTS.md

## Project Overview

**zoom.nvim** is a Neovim plugin that provides window zoom/maximize functionality. It allows users to temporarily maximize the current window and restore the previous layout.

## Project Structure

```
zoom.nvim/
├── lua/zoom/
│   └── init.lua      # Main plugin module (API, state, setup)
├── plugin/
│   └── zoom.lua      # Plugin loader (prevents double-loading)
└── AGENTS.md
```

## Installation & Usage

This is a Neovim plugin. Users install via their plugin manager and call:

```lua
require('zoom').setup()
```

## API

| Function | Description |
|----------|-------------|
| `M.setup(opts)` | Initialize plugin, create commands and autocmds |
| `M.zoom()` | Zoom current window (or restore if already zoomed) |
| `M.restore()` | Restore previous window layout |
| `M.toggle()` | Alias for `M.zoom()` |
| `M.is_zoomed()` | Returns boolean zoom state |

### User Commands

- `:ZoomToggle` - Toggle zoom state
- `:ZoomRestore` - Restore layout

## Code Patterns

### Module Pattern
- Standard Lua module with `local M = {}` and `return M`
- Private state in local table (`state`)
- Private helper functions as local functions
- Public API as `M.function_name`

### Neovim API Usage
- `vim.fn.winrestcmd()` - Save window layout as command string
- `vim.cmd('wincmd _')` / `vim.cmd('wincmd |')` - Maximize window
- `vim.api.nvim_create_user_command()` - Create Ex commands
- `vim.api.nvim_create_autocmd()` - Create autocommands
- `vim.api.nvim_create_augroup()` - Namespaced autocmd group (`zoom-nvim`)
- `vim.notify()` - User notifications with log levels

### Style Conventions
- 2-space indentation
- Single quotes for strings
- Trailing space before `{` in vim.cmd calls: `vim.cmd 'wincmd _'`
- Descriptive comments above functions
- `opts = opts or {}` pattern for optional parameters

## State Management

The plugin maintains internal state:
```lua
local state = {
  is_zoomed = false,      -- Current zoom status
  saved_layout = nil,     -- winrestcmd() output for restore
  zoomed_buf = nil,       -- Buffer that was zoomed (currently unused)
}
```

State is reset when:
- User calls `restore()`
- Any window closes while zoomed (via `WinClosed` autocmd)

## Gotchas

1. **Single window check**: `zoom()` exits early if only one window exists
2. **WinClosed resets state**: If any window closes while zoomed, state resets (may not restore to original layout)
3. **zoomed_buf tracked but unused**: The buffer ID is saved but not currently used for validation
4. **toggle() is just zoom()**: They're functionally identical since `zoom()` already toggles

## Testing

No test framework is set up. To manually test:
1. Open Neovim with this plugin loaded
2. Split windows (`:vs`, `:sp`)
3. Call `:ZoomToggle` and verify maximization
4. Call `:ZoomToggle` again and verify restore

## Development

### Adding Features
- Add public functions to `M` table in `lua/zoom/init.lua`
- Add new commands in `M.setup()` if needed
- Use existing patterns for Neovim API calls

### File Roles
- `lua/zoom/init.lua` - All plugin logic goes here
- `plugin/zoom.lua` - Only contains load guard, don't add logic here
