---@class ZoomOpts
---@field key string|nil Keymap to bind toggle (e.g. "<leader>z")
---@field notify boolean Whether to show notifications (default true)

---@class ZoomState
---@field is_zoomed boolean
---@field saved_layout string|nil
---@field zoomed_buf integer|nil
---@field original_wins table<integer, boolean>

---@class ZoomModule
---@field setup fun(opts?: ZoomOpts)
---@field zoom fun()
---@field restore fun()
---@field toggle fun()
---@field is_zoomed fun(): boolean
local M = {}

---@type ZoomOpts
local config = {
	key = nil,
	notify = true,
}

---@type ZoomState
local state = {
	is_zoomed = false,
	saved_layout = nil,
	zoomed_buf = nil,
	original_wins = {},
}

--- Save the current window layout
---@return string
local function save_layout()
	return vim.fn.winrestcmd()
end

--- Restore a saved window layout
---@param layout string|nil
local function restore_layout(layout)
	if layout then
		vim.cmd(layout)
	end
end

--- Zoom the current window (or restore if already zoomed)
---@return nil
function M.zoom()
	if state.is_zoomed then
		-- Already zoomed, restore
		M.restore()
	else
		-- Save layout and zoom
		if vim.fn.winnr("$") == 1 then
			-- Only one window, nothing to zoom
			if config.notify then
				vim.notify("Already at single window", vim.log.levels.INFO)
			end
			return
		end

		state.saved_layout = save_layout()
		state.zoomed_buf = vim.api.nvim_get_current_buf()
		state.original_wins = {}
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			state.original_wins[win] = true
		end
		state.is_zoomed = true

		-- Maximize current window
		vim.cmd("wincmd _")
		vim.cmd("wincmd |")

		vim.api.nvim_exec_autocmds("User", { pattern = "ZoomChanged" })
	end
end

--- Restore the previous layout
---@return nil
function M.restore()
	if not state.is_zoomed then
		return
	end

	restore_layout(state.saved_layout)
	state.is_zoomed = false
	state.saved_layout = nil
	state.zoomed_buf = nil
	state.original_wins = {}

	vim.api.nvim_exec_autocmds("User", { pattern = "ZoomChanged" })
end

--- Check if currently zoomed
---@return boolean
function M.is_zoomed()
	return state.is_zoomed
end

--- Toggle zoom (alias for zoom)
---@return nil
function M.toggle()
	M.zoom()
end

--- Initialize the plugin
---@param opts? ZoomOpts
---@return nil
function M.setup(opts)
	opts = opts or {}

	-- Merge user options into config
	if opts.key ~= nil then config.key = opts.key end
	if opts.notify ~= nil then config.notify = opts.notify end

	-- Create user command
	vim.api.nvim_create_user_command("ZoomToggle", M.toggle, { desc = "Toggle window zoom" })
	vim.api.nvim_create_user_command("ZoomRestore", M.restore, { desc = "Restore window layout" })

	-- Bind keymap if configured
	if config.key then
		vim.keymap.set("n", config.key, M.toggle, { desc = "Toggle window zoom", silent = true })
	end

	-- Reset state only if a window from the original layout closes
	vim.api.nvim_create_autocmd("WinClosed", {
		group = vim.api.nvim_create_augroup("zoom-nvim", { clear = true }),
		callback = function(args)
			if state.is_zoomed then
				local closed_win = tonumber(args.match)
				if closed_win and state.original_wins[closed_win] then
					state.is_zoomed = false
					state.saved_layout = nil
					state.zoomed_buf = nil
					state.original_wins = {}
					vim.api.nvim_exec_autocmds("User", { pattern = "ZoomChanged" })
				end
			end
		end,
	})
end

return M
