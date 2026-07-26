local M = {}

-- Feature-detect the health API: Neovim 0.7 exposes the report_* names,
-- 0.8+ adds the short aliases. Support both so :checkhealth works on 0.7+.
local health = vim.health or {}
local h = {
	start = health.start or health.report_start,
	ok = health.ok or health.report_ok,
	warn = health.warn or health.report_warn,
	error = health.error or health.report_error,
	info = health.info or health.report_info,
}

function M.check()
	h.start("zoom.nvim")

	-- Check Neovim version (needs 0.7+ for nvim_create_user_command / vim.keymap)
	if vim.fn.has("nvim-0.7") == 1 then
		h.ok("Neovim >= 0.7")
	else
		h.error("Neovim >= 0.7 required", { "Update Neovim to 0.7 or later" })
	end

	-- Check if plugin is loaded
	local ok, zoom = pcall(require, "zoom")
	if ok then
		h.ok("zoom module loaded")
	else
		h.error("zoom module failed to load", { "Check plugin installation" })
		return
	end

	-- Check if setup() was called
	if zoom._setup_called then
		h.ok("require('zoom').setup() has been called")
	else
		h.warn("require('zoom').setup() has not been called", { "Call require('zoom').setup() in your config" })
	end

	-- Report zoom state
	if zoom.is_zoomed() then
		h.info("Currently zoomed")
	else
		h.ok("Not currently zoomed")
	end
end

return M
