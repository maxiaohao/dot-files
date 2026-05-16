-- ~/.config/wezterm/wezterm.lua
-- A tmux-flavoured WezTerm config.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

------------------------------------------------------------------
-- Appearance
------------------------------------------------------------------
config.color_scheme = "Tokyo Night"
-- Override just the cursor colour (keeps the rest of Tokyo Night intact).
config.colors = {
	cursor_bg = "#00ff00",
	cursor_border = "#00ff00",
	cursor_fg = "#1a1b26",
}
config.font = wezterm.font_with_fallback({
	{ family = "IosevkaSS04 Nerd Font", weight = "Regular" },
	{ family = "Consolas", weight = "Light" },
	{ family = "Cascadia Code", weight = "Light" },
	"Segoe UI Emoji",
})
config.font_size = 13.5
-- config.window_decorations = "RESIZE"
-- config.window_background_opacity = 1.0
config.scrollback_lines = 100000
-- config.audible_bell               = 'Disabled'

-- -- Rendering / input smoothness on Windows.
-- -- WebGpu is generally the snappiest front-end on Windows; HighPerformance
-- -- nudges Windows to pick the discrete/iGPU rather than a software adapter.
-- config.front_end = "WebGpu"
-- config.webgpu_power_preference = "HighPerformance"
-- -- Match a 60 Hz panel; raise to 120/144 if you ever attach a faster display.
-- config.max_fps = 60
-- -- Disable the cursor-blink / status-bar animation tick so we don't redraw
-- -- the whole window 10× a second when nothing is happening.
-- config.animation_fps = 1
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0

------------------------------------------------------------------
-- Tab bar (at the bottom, tmux-style status line)
------------------------------------------------------------------
config.enable_tab_bar = true
config.use_fancy_tab_bar = false -- required for `tab_bar_at_bottom` to take effect
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 13 -- " N: 12345678  " ≈ 13 cells with leading + double-trailing space

-- config.launch_menu = {
-- 	{ label = "PowerShell 7", args = { "pwsh.exe", "-NoLogo" } },
-- 	{ label = "Windows PowerShell", args = { "powershell.exe", "-NoLogo" } },
-- 	{ label = "CMD", args = { "cmd.exe" } },
-- }

-- Tab title formatter.
--   Mux (server)  domain tabs -> green   (#9ece6a)
--   Local (parked) domain tabs -> light blue (#7dcfff)
wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
	local idx = tab.tab_index + 1
	local title = tab.active_pane.title or ""
	if #title > 8 then
		title = title:sub(1, 7) .. "…"
	end
	local is_local = (tab.active_pane.domain_name or "") == "local"
	local accent = is_local and "#7dcfff" or "#bb9af7" -- purple for mux, light blue for local
	local label = string.format(" %d: %s  ", idx, title)

	if tab.is_active then
		return {
			{ Background = { Color = accent } },
			{ Foreground = { Color = "#1a1b26" } },
			{ Text = label },
		}
	end
	return {
		{ Foreground = { Color = accent } },
		{ Text = label },
	}
end)

-- Bottom status bar:
--   left  = [ hostname ]
--   right = YYYY-MM-DD HH:MM:SS
-- WezTerm has no native "center tabs" option; we pad the left status so the
-- tab strip lands in the middle of the window.  Recomputed every second.
wezterm.on("update-status", function(window, pane)
	local left = " [ " .. wezterm.hostname() .. " ] "
	-- e.g. "Sat 16 May 12:32:24"
	local right = " " .. wezterm.strftime("%a %d %b %H:%M:%S") .. " "

	-- Estimate total tab-strip width.  Mirrors the label produced by
	-- format-tab-title: " N: title " plus ~1 cell of separator per tab.
	local tabs_w = 0
	local ok, muxwin = pcall(function()
		return window:mux_window()
	end)
	if ok and muxwin then
		for i, mux_tab in ipairs(muxwin:tabs()) do
			local title = mux_tab:active_pane():get_title() or ""
			if #title > 8 then
				title = title:sub(1, 7) .. "…"
			end
			local label = string.format(" %d: %s  ", i, title)
			tabs_w = tabs_w + wezterm.column_width(label) + 1
		end
	end

	local window_cols = window:active_tab():get_size().cols
	local left_w = wezterm.column_width(left)
	local right_w = wezterm.column_width(right)

	-- For tabs to be centred:
	--   left_total + tabs_w + right_total == window_cols
	--   left_total - left_w        ==  right_total - right_w  (symmetric)
	local target_left = math.floor((window_cols - tabs_w + left_w - right_w) / 2)
	if target_left > left_w then
		left = left .. string.rep(" ", target_left - left_w)
	end

	window:set_left_status(wezterm.format({
		{ Foreground = { Color = "#a9b1d6" } },
		{ Text = left },
	}))
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#a9b1d6" } },
		{ Text = right },
	}))
end)

------------------------------------------------------------------
-- Default shell (Windows -> PowerShell 7 if present, else Windows PS)
------------------------------------------------------------------
if wezterm.target_triple:find("windows") then
	config.default_prog = { "pwsh.exe", "-NoLogo" }
end

------------------------------------------------------------------
-- Multiplexing: tmux-style detach / re-attach via a local mux domain.
-- The mux server (wezterm-mux-server) keeps panes alive after the GUI
-- closes. On Windows the 'unix' domain uses a Named Pipe under the hood.
------------------------------------------------------------------
config.unix_domains = {
	{ name = "main" },
}

-- Auto-attach to the 'main' mux every time the GUI starts so every shell
-- you spawn lives in the mux and survives the window being closed.
config.default_gui_startup_args = { "connect", "main" }

------------------------------------------------------------------
-- LEADER:  Ctrl-A, just like tmux
------------------------------------------------------------------
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }

------------------------------------------------------------------
-- Key bindings (tmux muscle memory)
------------------------------------------------------------------
config.disable_default_key_bindings = false
config.keys = {
	-- Send a literal Ctrl-A by hitting the leader twice (tmux's `send-prefix`)
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Tabs
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- LEADER + 1..9 -> focus that tab (1-based)
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },

	-- Panes (splits)
	{ key = "%", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = '"', mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Move focus between panes (vi keys, tmux style)
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },

	-- Resize panes (LEADER + r, then h/j/k/l; Esc to exit)
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "resize_pane",
			one_shot = false,
			timeout_milliseconds = 1500,
		}),
	},

	-- Zoom toggle (tmux: prefix + z)
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- Swap panes (tmux: prefix + { / })
	{ key = "{", mods = "LEADER|SHIFT", action = act.RotatePanes("CounterClockwise") },
	{ key = "}", mods = "LEADER|SHIFT", action = act.RotatePanes("Clockwise") },

	-- Pane selector
	{ key = "q", mods = "LEADER", action = act.PaneSelect({ alphabet = "1234567890" }) },

	-- Copy / paste (tmux: prefix + [ to enter copy mode, prefix + ] to paste)
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },

	-- Quick-select (URLs, hashes, paths…)
	{ key = "Space", mods = "LEADER", action = act.QuickSelect },

	-- Search the scrollback (tmux's copy-mode `/`)
	{ key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },

	-- Reload config on the fly
	{ key = "R", mods = "LEADER|SHIFT", action = act.ReloadConfiguration },

	-- Detach from the mux: closes the GUI but keeps panes alive (tmux: prefix + d)
	{ key = "d", mods = "LEADER", action = act.DetachDomain({ DomainName = "main" }) },

	-- Spawn a "park" tab in the LOCAL (non-mux) domain so you can detach
	-- from the mux without losing the window.
	{ key = "t", mods = "LEADER", action = act.SpawnTab({ DomainName = "local" }) },

	-- Attach / switch to the 'main' mux from inside a running window
	{ key = "s", mods = "LEADER", action = act.AttachDomain("main") },

	-- Launcher (was on LEADER+d before; moved here so `d` is free for detach)
	{ key = "L", mods = "LEADER|CTRL", action = act.ShowLauncher },

	-- Debug overlay
	{ key = "D", mods = "LEADER|SHIFT", action = act.ShowDebugOverlay },
}

------------------------------------------------------------------
-- Key tables (resize_pane, copy_mode, search_mode)
------------------------------------------------------------------
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},

	-- COPY MODE -- vi-style, tmux's `copy-mode-vi` flavour
	--   Enter:    LEADER+[  (or default Ctrl-Shift-X)
	--   Exit:     Esc / q / Ctrl-C
	--   Select:   v (cell), V (line), Ctrl-v (block)
	--   Yank:     y    -> copies to clipboard AND exits
	copy_mode = {
		-- Movement (vi)
		{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
		{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },

		-- Words
		{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
		{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },

		-- Line jumps
		{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
		{ key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
		{ key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },

		-- Page / scrollback
		{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
		{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
		{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
		{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
		{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
		{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
		{ key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
		{ key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },

		-- Char jumps  f/F/t/T  + ; ,
		{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
		{ key = "F", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
		{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
		{ key = "T", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
		{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
		{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },

		-- Selection mode (tmux: v / V / Ctrl-v)
		{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
		{ key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
		{ key = "O", mods = "SHIFT", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },

		-- YANK -- copy to clipboard and exit (tmux `copy-pipe-and-cancel`)
		{
			key = "y",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "Close" },
			}),
		},
		{
			key = "Enter",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "Close" },
			}),
		},

		-- Search inside copy mode
		{ key = "/", mods = "NONE", action = act.Search({ CaseInSensitiveString = "" }) },
		{ key = "?", mods = "SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },
		{ key = "n", mods = "NONE", action = act.CopyMode("NextMatch") },
		{ key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") },

		-- Quit copy mode
		{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
	},

	-- SEARCH MODE
	search_mode = {
		{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
		{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
		{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
	},
}

------------------------------------------------------------------
-- Mouse: right-click pastes, Ctrl+Click opens links
------------------------------------------------------------------
config.mouse_bindings = {
	{ event = { Down = { streak = 1, button = "Right" } }, mods = "NONE", action = act.PasteFrom("Clipboard") },

	{ event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },
}

return config
