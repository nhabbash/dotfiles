-- aerospace-hints.lua
-- Displays a floating contextual keybinding hint bar for AeroSpace modes.
-- Inspired by zjstatus-hints for Zellij.
--
-- Setup:
--   1. Add to ~/.config/aerospace/aerospace.toml:
--        after-startup-command = ['exec-and-forget sh -c "echo main > /tmp/aerospace-mode"']
--        on mode-switch bindings: 'exec-and-forget sh -c "echo <mode> > /tmp/aerospace-mode"'
--   2. require("aerospace-hints").start() from your init.lua

local M = {}

-- ── Catppuccin Mocha ──────────────────────────────────────────────────────
local c = {
	base = { red = 0x1e / 255, green = 0x1e / 255, blue = 0x2e / 255, alpha = 0.95 },
	surface0 = { red = 0x31 / 255, green = 0x32 / 255, blue = 0x44 / 255, alpha = 1 },
	overlay0 = { red = 0x6c / 255, green = 0x70 / 255, blue = 0x86 / 255, alpha = 1 },
	subtext1 = { red = 0xba / 255, green = 0xc2 / 255, blue = 0xde / 255, alpha = 1 },
	black = { red = 0x11 / 255, green = 0x11 / 255, blue = 0x1b / 255, alpha = 1 },
	green = { red = 0xa6 / 255, green = 0xe3 / 255, blue = 0xa1 / 255, alpha = 1 },
	red = { red = 0xf3 / 255, green = 0x8b / 255, blue = 0xa8 / 255, alpha = 1 },
	sky = { red = 0x89 / 255, green = 0xdc / 255, blue = 0xeb / 255, alpha = 1 },
	mauve = { red = 0xcb / 255, green = 0xa6 / 255, blue = 0xf7 / 255, alpha = 1 },
}

-- ── Config ────────────────────────────────────────────────────────────────
local FONT = "Inconsolata Nerd Font Mono"
local SIZE = 14
local HEIGHT = 28
local MARGIN_X = 10 -- gap from left/right screen edges
local MARGIN_B = 5 -- gap from bottom screen edge
local RADIUS = 8 -- rounded corner radius
local STATE = "/tmp/aerospace-mode"

-- ── Mode definitions ──────────────────────────────────────────────────────
local MODES = {
	main = {
		color = c.green,
		hints = {
			{ key = "alt h/j/k/l", desc = "focus" },
			{ key = "alt shift h/j/k/l", desc = "move" },
			{ key = "alt -/=", desc = "resize" },
			{ key = "alt /", desc = "tiles" },
			{ key = "alt ,", desc = "accordion" },
			{ key = "alt tab", desc = "back/forth" },
			{ key = "alt shift tab", desc = "→ monitor" },
			{ key = "alt shift ;", desc = "service mode" },
		},
	},
	service = {
		color = c.red,
		hints = {
			{ key = "esc", desc = "reload config" },
			{ key = "r", desc = "reset layout" },
			{ key = "f", desc = "float/tile" },
			{ key = "⌫", desc = "close others" },
			{ key = "alt shift h/j/k/l", desc = "join with" },
		},
	},
}

-- ── Internal state ────────────────────────────────────────────────────────
local canvas = nil
local watcher = nil

-- ── Styled text helpers ───────────────────────────────────────────────────
local function st(text, attrs)
	return hs.styledtext.new(text, attrs)
end

local function buildLine(mode)
	local def = MODES[mode] or MODES["main"]
	local font = { name = FONT, size = SIZE }
	local bold = { name = FONT, size = SIZE, traits = { "bold" } }

	local line = st(" 󰕰 ", { font = bold, color = c.sky })
	line = line
		.. st(" " .. (mode or "main"):upper() .. " ", {
			font = bold,
			color = c.black,
			backgroundColor = def.color,
		})
	line = line .. st("  ", { font = font, color = c.subtext1 })

	for i, h in ipairs(def.hints) do
		line = line .. st(h.key, { font = bold, color = c.sky })
		line = line .. st(" → ", { font = font, color = c.overlay0 })
		line = line .. st(h.desc, { font = font, color = c.subtext1 })
		if i < #def.hints then
			line = line .. st("  ·  ", { font = font, color = c.overlay0 })
		end
	end

	return line
end

-- ── Canvas ────────────────────────────────────────────────────────────────
local function makeCanvas()
	local screen = hs.screen.primaryScreen()
	local frame = screen:frame()
	local w = frame.w - MARGIN_X * 2

	local cv = hs.canvas.new({
		x = frame.x + MARGIN_X,
		y = frame.y + frame.h - HEIGHT - MARGIN_B,
		w = w,
		h = HEIGHT,
	})

	cv:level(hs.canvas.windowLevels.overlay)
	cv:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)

	-- Rounded background
	cv[1] = {
		type = "rectangle",
		fillColor = c.base,
		strokeColor = c.surface0,
		strokeWidth = 1,
		roundedRectRadii = { xRadius = RADIUS, yRadius = RADIUS },
		frame = { x = 0, y = 0, w = w, h = HEIGHT },
	}

	-- Hint text
	cv[2] = {
		type = "text",
		text = "",
		frame = { x = 8, y = 6, w = w - 16, h = HEIGHT },
		textLineBreak = "clip",
	}

	return cv
end

-- ── Mode reading ──────────────────────────────────────────────────────────
local function readMode()
	local f = io.open(STATE, "r")
	if not f then
		return "main"
	end
	local s = f:read("*l")
	f:close()
	return (s and s:match("^%s*(.-)%s*$")) or "main"
end

local function refresh()
	if not canvas then
		return
	end
	canvas[2].text = buildLine(readMode())
end

-- ── Public API ────────────────────────────────────────────────────────────
function M.start()
	canvas = makeCanvas()
	canvas[2].text = buildLine(readMode())
	canvas:show()

	watcher = hs.pathwatcher
		.new(STATE, function()
			hs.timer.doAfter(0.05, refresh)
		end)
		:start()
end

function M.stop()
	if watcher then
		watcher:stop()
		watcher = nil
	end
	if canvas then
		canvas:delete()
		canvas = nil
	end
end

-- Reposition when monitors change
hs.screen.watcher
	.new(function()
		if canvas then
			M.stop()
			M.start()
		end
	end)
	:start()

return M
