-- Tests for zoom.nvim using busted with vim API mocks

-- Mock vim global
local autocmd_events = {}
local user_commands = {}
local notifications = {}
local keymaps = {}
local deleted_keymaps = {}

_G.vim = {
	fn = {
		winrestcmd = function() return "1resize 30|vert 1resize 80|" end,
		winnr = function(arg)
			if arg == "$" then return 2 end
			return 1
		end,
		has = function() return 1 end,
	},
	cmd = function() end,
	api = {
		nvim_get_current_buf = function() return 1 end,
		nvim_list_wins = function() return { 1000, 1001 } end,
		nvim_create_user_command = function(name, fn, opts)
			if user_commands[name] and not opts.force then
				error("Command already exists: " .. name)
			end
			user_commands[name] = { fn = fn, opts = opts }
		end,
		nvim_create_autocmd = function(event, opts)
			table.insert(autocmd_events, { event = event, opts = opts })
		end,
		nvim_create_augroup = function(name, _)
			return name
		end,
		nvim_exec_autocmds = function(event, opts)
			-- track fired events for assertions
			_G._zoom_test_events = _G._zoom_test_events or {}
			table.insert(_G._zoom_test_events, { event = event, pattern = opts.pattern })
		end,
	},
	keymap = {
		set = function(mode, lhs, rhs, opts)
			table.insert(keymaps, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
		end,
		del = function(mode, lhs)
			table.insert(deleted_keymaps, { mode = mode, lhs = lhs })
		end,
	},
	notify = function(msg, level)
		table.insert(notifications, { msg = msg, level = level })
	end,
	log = { levels = { INFO = 1, WARN = 2, ERROR = 3 } },
	g = {},
	health = {
		start = function() end,
		ok = function() end,
		warn = function() end,
		error = function() end,
		info = function() end,
	},
}

-- Reload module fresh for each test
local function load_zoom()
	package.loaded["zoom"] = nil
	package.loaded["zoom.init"] = nil
	package.loaded["zoom.health"] = nil
	_G._zoom_test_events = {}
	user_commands = {}
	autocmd_events = {}
	notifications = {}
	keymaps = {}
	deleted_keymaps = {}
	return require("zoom")
end

describe("zoom.nvim", function()
	local zoom

	before_each(function()
		zoom = load_zoom()
		zoom.setup()
	end)

	describe("setup", function()
		it("creates ZoomToggle command", function()
			assert.is_not_nil(user_commands["ZoomToggle"])
		end)

		it("creates ZoomRestore command", function()
			assert.is_not_nil(user_commands["ZoomRestore"])
		end)

		it("can be called repeatedly without duplicate command errors", function()
			assert.has_no.errors(function()
				zoom.setup()
			end)
			assert.is_true(user_commands["ZoomToggle"].opts.force)
			assert.is_true(user_commands["ZoomRestore"].opts.force)
		end)
	end)

	describe("is_zoomed", function()
		it("returns false initially", function()
			assert.is_false(zoom.is_zoomed())
		end)
	end)

	describe("zoom", function()
		it("zooms when not zoomed", function()
			zoom.zoom()
			assert.is_true(zoom.is_zoomed())
		end)

		it("fires ZoomChanged event on zoom", function()
			zoom.zoom()
			assert.equals(1, #_G._zoom_test_events)
			assert.equals("ZoomChanged", _G._zoom_test_events[1].pattern)
		end)

		it("restores when already zoomed", function()
			zoom.zoom()
			zoom.zoom()
			assert.is_false(zoom.is_zoomed())
		end)

		it("notifies when only one window", function()
			vim.fn.winnr = function() return 1 end
			zoom.zoom()
			assert.is_false(zoom.is_zoomed())
			assert.equals("Already at single window", notifications[1].msg)
			-- restore
			vim.fn.winnr = function(arg)
				if arg == "$" then return 2 end
				return 1
			end
		end)
	end)

	describe("restore", function()
		it("does nothing when not zoomed", function()
			zoom.restore()
			assert.is_false(zoom.is_zoomed())
			assert.equals(0, #_G._zoom_test_events)
		end)

		it("restores when zoomed", function()
			zoom.zoom()
			_G._zoom_test_events = {}
			zoom.restore()
			assert.is_false(zoom.is_zoomed())
			assert.equals(1, #_G._zoom_test_events)
			assert.equals("ZoomChanged", _G._zoom_test_events[1].pattern)
		end)
	end)

	describe("toggle", function()
		it("is an alias for zoom", function()
			zoom.toggle()
			assert.is_true(zoom.is_zoomed())
			zoom.toggle()
			assert.is_false(zoom.is_zoomed())
		end)
	end)

	describe("setup options", function()
		it("binds keymap when key option is set", function()
			zoom = load_zoom()
			zoom.setup({ key = "<leader>z" })
			assert.equals(1, #keymaps)
			assert.equals("n", keymaps[1].mode)
			assert.equals("<leader>z", keymaps[1].lhs)
		end)

		it("does not bind keymap when key is nil", function()
			zoom = load_zoom()
			zoom.setup({})
			assert.equals(0, #keymaps)
		end)

		it("resets keymap option back to default on later setup calls", function()
			zoom = load_zoom()
			zoom.setup({ key = "<leader>z" })
			zoom.setup({})
			assert.equals(1, #keymaps)
		end)

		it("resets notify option back to default on later setup calls", function()
			zoom = load_zoom()
			zoom.setup({ notify = false })
			zoom.setup({})
			vim.fn.winnr = function() return 1 end
			zoom.zoom()
			assert.equals(1, #notifications)
			assert.equals("Already at single window", notifications[1].msg)
			vim.fn.winnr = function(arg)
				if arg == "$" then return 2 end
				return 1
			end
		end)

		it("removes the previous keymap when setup changes it", function()
			zoom = load_zoom()
			zoom.setup({ key = "<leader>z" })
			zoom.setup({ key = "gz" })
			assert.equals(1, #deleted_keymaps)
			assert.equals("n", deleted_keymaps[1].mode)
			assert.equals("<leader>z", deleted_keymaps[1].lhs)
			assert.equals("gz", keymaps[#keymaps].lhs)
		end)

		it("removes the previous keymap when setup resets to defaults", function()
			zoom = load_zoom()
			zoom.setup({ key = "<leader>z" })
			zoom.setup({})
			assert.equals(1, #deleted_keymaps)
			assert.equals("<leader>z", deleted_keymaps[1].lhs)
		end)

		it("tolerates an already-removed previous keymap", function()
			zoom = load_zoom()
			zoom.setup({ key = "<leader>z" })

			local original_del = vim.keymap.del
			vim.keymap.del = function()
				error("not found")
			end

			assert.has_no.errors(function()
				zoom.setup({})
			end)

			vim.keymap.del = original_del
		end)

		it("suppresses notification when notify is false", function()
			zoom = load_zoom()
			zoom.setup({ notify = false })
			vim.fn.winnr = function() return 1 end
			zoom.zoom()
			assert.equals(0, #notifications)
			-- restore mock
			vim.fn.winnr = function(arg)
				if arg == "$" then return 2 end
				return 1
			end
		end)
	end)

	describe("health", function()
		it("loads health module without error", function()
			local ok, health = pcall(require, "zoom.health")
			assert.is_true(ok)
			assert.is_not_nil(health.check)
		end)

		it("runs check() without error", function()
			zoom = load_zoom()
			local health = require("zoom.health")
			assert.has_no.errors(function()
				health.check()
			end)
		end)

		it("warns when setup() was not called", function()
			zoom = load_zoom()
			local warnings = {}
			local original = vim.health.warn
			vim.health.warn = function(msg)
				table.insert(warnings, msg)
			end
			require("zoom.health").check()
			vim.health.warn = original
			assert.is_true(#warnings > 0)
		end)

		it("reports ok when setup() was called", function()
			zoom = load_zoom()
			zoom.setup()
			local warnings = {}
			local original = vim.health.warn
			vim.health.warn = function(msg)
				table.insert(warnings, msg)
			end
			require("zoom.health").check()
			vim.health.warn = original
			assert.equals(0, #warnings)
		end)

		it("falls back to report_* API on Neovim 0.7", function()
			package.loaded["zoom.health"] = nil
			local called = false
			local original = vim.health
			vim.health = {
				report_start = function() end,
				report_ok = function() called = true end,
				report_warn = function() end,
				report_error = function() end,
				report_info = function() end,
			}
			local health = require("zoom.health")
			assert.has_no.errors(function()
				health.check()
			end)
			assert.is_true(called)
			vim.health = original
			package.loaded["zoom.health"] = nil
		end)
	end)
end)
