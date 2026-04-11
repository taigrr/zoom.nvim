# zoom.nvim

Tmux-style window zoom for Neovim. Temporarily maximize the current window, press again to restore—just like `<prefix>z` in tmux.

## Install

```lua
-- lazy.nvim
{ 'taigrr/zoom.nvim', config = true }

-- packer
use { 'taigrr/zoom.nvim', config = function() require('zoom').setup() end }
```

## Keybinding

```lua
vim.keymap.set('n', '<leader>z', '<cmd>ZoomToggle<cr>')
```

## Commands

- `:ZoomToggle` — maximize or restore
- `:ZoomRestore` — restore layout

## API

```lua
require('zoom').toggle()     -- toggle zoom
require('zoom').is_zoomed()  -- check state
```

## Events

A `User ZoomChanged` autocmd fires whenever zoom state changes. Use it to update your statusline or other UI:

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'ZoomChanged',
  callback = function()
    -- Example: refresh lualine
    local ok, lualine = pcall(require, 'lualine')
    if ok then lualine.refresh() end
  end,
})
```

Statusline component example:

```lua
local function zoom_status()
  if require('zoom').is_zoomed() then return '🔍' end
  return ''
end
```

## Configuration

```lua
require('zoom').setup({
  key = '<leader>z',   -- optional: bind a keymap automatically
  notify = true,       -- optional: show notifications (default true)
})
```

## Health Check

Run `:checkhealth zoom` to verify your installation.

## License

[0BSD](LICENSE)
