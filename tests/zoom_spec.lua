-- Tests for zoom.nvim using busted with vim API mocks

-- Mock vim global
local autocmd_events = {}
local user_commands = {}
local notifications = {}

_G.vim = {
	fn = {
		winrestcmd = function() return "1resize 30|vert 1resize 80|" end,
		winnr = function(arg)
			if arg == "$" then return 2 end
			return 1
		end,
	},
	cmd = function() end,
	api = {
		nvim_get_current_buf = function() return 1 end,
		nvim_list_wins = function() return { 1000, 1001 } end,
		nvim_create_user_command = function(name, fn, opts)
			user_commands[name] = { fn = fn, opts = opts }
		end,
		nvim_create_autocmd = function(event, opts)
			table.insert(autocmd_events, { event = event, opts = opts })
		end,
		nvim_create_augroup = function(name, opts)
			return name
		end,
		nvim_exec_autocmds = function(event, opts)
			-- track fired events for assertions
			_G._zoom_test_events = _G._zoom_test_events or {}
			table.insert(_G._zoom_test_events, { event = event, pattern = opts.pattern })
		end,
	},
	notify = function(msg, level)
		table.insert(notifications, { msg = msg, level = level })
	end,
	log = { levels = { INFO = 1, WARN = 2, ERROR = 3 } },
	g = {},
}

-- Reload module fresh for each test
local function load_zoom()
	package.loaded["zoom"] = nil
	package.loaded["zoom.init"] = nil
	_G._zoom_test_events = {}
	notifications = {}
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
end)
