local M = {}

function M.check()
	vim.health.start("zoom.nvim")

	-- Check Neovim version (needs 0.7+ for nvim_create_user_command)
	if vim.fn.has("nvim-0.7") == 1 then
		vim.health.ok("Neovim >= 0.7")
	else
		vim.health.error("Neovim >= 0.7 required", { "Update Neovim to 0.7 or later" })
	end

	-- Check if plugin is loaded
	local ok, zoom = pcall(require, "zoom")
	if ok then
		vim.health.ok("zoom module loaded")
	else
		vim.health.error("zoom module failed to load", { "Check plugin installation" })
		return
	end

	-- Check if setup was called
	if vim.g.loaded_zoom then
		vim.health.ok("Plugin guard active (vim.g.loaded_zoom)")
	else
		vim.health.warn("Plugin guard not set", { "Ensure plugin/ directory is in runtimepath" })
	end

	-- Report zoom state
	if zoom.is_zoomed() then
		vim.health.info("Currently zoomed")
	else
		vim.health.ok("Not currently zoomed")
	end
end

return M
