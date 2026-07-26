local M = {}

-- Resolve the health API at call time. Neovim <0.8 has no `vim.health` table
-- (the report_* functions live in the `health` module); 0.8-0.9 expose
-- report_* on `vim.health`; 0.10+ adds the short aliases. Support all three.
local function get_health()
	local health = vim.health
	if not health then
		local ok, mod = pcall(require, "health")
		health = ok and mod or {}
	end
	local noop = function() end
	return {
		available = (health.start or health.report_start) ~= nil,
		start = health.start or health.report_start or noop,
		ok = health.ok or health.report_ok or noop,
		warn = health.warn or health.report_warn or noop,
		error = health.error or health.report_error or noop,
		info = health.info or health.report_info or noop,
	}
end

function M.check()
	local h = get_health()
	if not h.available then
		return
	end
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
