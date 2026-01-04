# zoom.nvim

Tmux-style window zoom for Neovim. Temporarily maximize the current window, press again to restore—just like `<prefix>z` in tmux.

## Install

```lua
-- lazy.nvim
{ 'tai/zoom.nvim', config = true }

-- packer
use { 'tai/zoom.nvim', config = function() require('zoom').setup() end }
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
