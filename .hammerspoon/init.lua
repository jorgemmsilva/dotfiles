hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.PaperWM = {
	url = "https://github.com/mogenson/PaperWM.spoon",
	desc = "PaperWM.spoon repository",
	branch = "release",
}

spoon.SpoonInstall:andUse("PaperWM", {
	repo = "PaperWM",
	config = { screen_margin = 16, window_gap = 2 },
	start = false,
	hotkeys = {},
})

PaperWM = hs.loadSpoon("PaperWM")
PaperWM:bindHotkeys({
	-- switch to a new focused window in tiled grid
	-- focus_left = { { "alt", "ctrl" }, "left" },
	-- focus_right = { { "alt", "ctrl" }, "right" },
	-- focus_up = { { "alt", "ctrl" }, "up" },
	-- focus_down = { { "alt", "ctrl" }, "down" },

	-- switch windows by cycling forward/backward
	-- (forward = down or right, backward = up or left)
	focus_prev = { { "alt", "ctrl" }, "h" },
	focus_next = { { "alt", "ctrl" }, "l" },
	-- increase/decrease width
	increase_width = { { "alt", "ctrl" }, "k" },
	decrease_width = { { "alt", "ctrl" }, "j" },

	-- move windows around in tiled grid
	swap_left = { { "alt", "ctrl" }, "left" },
	swap_right = { { "alt", "ctrl" }, "right" },
	swap_up = { { "alt", "ctrl" }, "up" },
	swap_down = { { "alt", "ctrl" }, "down" },

	-- position and resize focused window
	center_window = { { "alt", "ctrl" }, "c" },
	full_width = { { "alt", "ctrl" }, "f" },
	cycle_width = { { "alt", "ctrl" }, "r" },
	reverse_cycle_width = { { "ctrl", "alt", "ctrl" }, "r" },
	cycle_height = { { "alt", "ctrl", "shift" }, "r" },
	reverse_cycle_height = { { "ctrl", "alt", "ctrl", "shift" }, "r" },

	-- move focused window into / out of a column
	slurp_in = { { "alt", "ctrl" }, "i" },
	barf_out = { { "alt", "ctrl" }, "o" },

	-- move the focused window into / out of the tiling layer
	toggle_floating = { { "alt", "ctrl" }, "escape" },

	-- focus the first / second / etc window in the current space
	focus_window_1 = { { "ctrl", "shift" }, "1" },
	focus_window_2 = { { "ctrl", "shift" }, "2" },
	focus_window_3 = { { "ctrl", "shift" }, "3" },
	focus_window_4 = { { "ctrl", "shift" }, "4" },
	focus_window_5 = { { "ctrl", "shift" }, "5" },
	focus_window_6 = { { "ctrl", "shift" }, "6" },
	focus_window_7 = { { "ctrl", "shift" }, "7" },
	focus_window_8 = { { "ctrl", "shift" }, "8" },
	focus_window_9 = { { "ctrl", "shift" }, "9" },

	-- switch to a new Mission Control space
	switch_space_l = { { "alt", "ctrl" }, "," },
	switch_space_r = { { "alt", "ctrl" }, "." },
	switch_space_1 = { { "alt", "ctrl" }, "1" },
	switch_space_2 = { { "alt", "ctrl" }, "2" },
	switch_space_3 = { { "alt", "ctrl" }, "3" },
	switch_space_4 = { { "alt", "ctrl" }, "4" },
	switch_space_5 = { { "alt", "ctrl" }, "5" },
	switch_space_6 = { { "alt", "ctrl" }, "6" },
	switch_space_7 = { { "alt", "ctrl" }, "7" },
	switch_space_8 = { { "alt", "ctrl" }, "8" },
	switch_space_9 = { { "alt", "ctrl" }, "9" },

	-- move focused window to a new space and tile
	move_window_1 = { { "alt", "ctrl", "shift" }, "1" },
	move_window_2 = { { "alt", "ctrl", "shift" }, "2" },
	move_window_3 = { { "alt", "ctrl", "shift" }, "3" },
	move_window_4 = { { "alt", "ctrl", "shift" }, "4" },
	move_window_5 = { { "alt", "ctrl", "shift" }, "5" },
	move_window_6 = { { "alt", "ctrl", "shift" }, "6" },
	move_window_7 = { { "alt", "ctrl", "shift" }, "7" },
	move_window_8 = { { "alt", "ctrl", "shift" }, "8" },
	move_window_9 = { { "alt", "ctrl", "shift" }, "9" },
})

-- use ⌘ Enter as hyper key to enter modal layer, press Escape to exit
-- local modal = hs.hotkey.modal.new({ "ctrl" }, "return")

-- local actions = PaperWM.actions.actions()
-- modal:bind({}, "h", nil, actions.focus_left)
-- modal:bind({}, "j", nil, actions.focus_down)
-- modal:bind({}, "k", nil, actions.focus_up)
-- modal:bind({}, "l", nil, actions.focus_right)

--  gap on all sides
-- PaperWM.window_gap = 5
-- or specific gaps per side
PaperWM.window_gap = { top = 0, bottom = 0, left = 5, right = 5 }

-- ignore a specific app
PaperWM.window_filter:rejectApp("Slack")
PaperWM.window_filter:rejectApp("Signal")
PaperWM.window_filter:rejectApp("OrbStack")
PaperWM.window_filter:rejectApp("TIDAL")
PaperWM.window_filter:rejectApp("Claude")
PaperWM.window_filter:rejectApp("Notion")
PaperWM.window_filter:rejectApp("Linear")
PaperWM.window_filter:rejectApp("Finder")
PaperWM.window_filter:rejectApp("System Settings")
-- list of screens to tile (use % to escape string match characters, like -)
-- PaperWM.window_filter:setScreens({ "Built%-in Retina Display" })

-- disable mouse centering when switching spaces
PaperWM.center_mouse = false

-- number of fingers to detect a horizontal swipe, set to 0 to disable (the default)
PaperWM.swipe_fingers = 3
-- increase this number to make windows move farther when swiping
PaperWM.swipe_gain = 1.0

-- Set PaperWM.window_ratios to the ratios to cycle window widths and heights through. For example:
PaperWM.window_ratios = { 1 / 3, 1 / 2, 2 / 3 }

-- set to a table of modifier keys to enable window dragging, default is nil
PaperWM.drag_window = { "alt", "ctrl" }

-- set to a table of modifier keys to enable window lifting, default is nil
PaperWM.lift_window = { "alt", "ctrl", "shift" }

PaperWM:start()
