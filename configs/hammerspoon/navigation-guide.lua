-- navigation-guide.lua
-- Keybinding reference overlay. Toggle with ctrl+shift+?.

local M = {}

-- ── Catppuccin Mocha ──────────────────────────────────────────────────────────
local c = {
	base     = { red = 0x1e / 255, green = 0x1e / 255, blue = 0x2e / 255, alpha = 0.97 },
	surface0 = { red = 0x31 / 255, green = 0x32 / 255, blue = 0x44 / 255, alpha = 1 },
	overlay0 = { red = 0x6c / 255, green = 0x70 / 255, blue = 0x86 / 255, alpha = 1 },
	subtext1 = { red = 0xba / 255, green = 0xc2 / 255, blue = 0xde / 255, alpha = 1 },
	sky      = { red = 0x89 / 255, green = 0xdc / 255, blue = 0xeb / 255, alpha = 1 },
	green    = { red = 0xa6 / 255, green = 0xe3 / 255, blue = 0xa1 / 255, alpha = 1 },
	mauve    = { red = 0xcb / 255, green = 0xa6 / 255, blue = 0xf7 / 255, alpha = 1 },
	yellow   = { red = 0xf9 / 255, green = 0xe2 / 255, blue = 0xaf / 255, alpha = 1 },
	peach    = { red = 0xfa / 255, green = 0xb3 / 255, blue = 0x87 / 255, alpha = 1 },
	teal     = { red = 0x94 / 255, green = 0xe2 / 255, blue = 0xd5 / 255, alpha = 1 },
}

local FONT     = "Inconsolata Nerd Font Mono"
local TITLE_SZ = 14
local HEAD_SZ  = 13
local SEC_SZ   = 9
local BODY_SZ  = 12

-- ── Reference data — 3 columns, one per tool ─────────────────────────────────
local GROUPS = {
	{
		title = "AEROSPACE",
		color = c.green,
		sections = {
			{
				title = "FOCUS",
				items = {
					{ "alt  h / j / k / l",       "focus ←↓↑→" },
					{ "alt  ctrl  h / j / k / l", "focus monitor ←↓↑→" },
					{ "alt  tab",                 "back & forth" },
					{ "alt  shift  f",                "fullscreen" },
				},
			},
			{
				title = "MOVE WINDOW",
				items = {
					{ "alt  shift  h / j / k / l", "move window ←↓↑→" },
					{ "alt  shift  tab",           "→ next monitor" },
					{ "alt  shift  [key]",         "move window there" },
				},
			},
			{
				title = "MOVE WORKSPACE",
				items = {
					{ "alt  ctrl  shift  h / j / k / l", "send workspace ←↓↑→" },
					{ "mouse + alt  [key]",              "pull workspace here" },
				},
			},
			{
				title = "LAYOUT",
				items = {
					{ "alt  /",    "tiles  h / v" },
					{ "alt  ,",    "accordion  h / v" },
					{ "alt  -  =", "resize  −50 / +50" },
				},
			},
			{
				title = "WORKSPACES",
				items = {
					{ "alt  1 – 5",         "summon numbered here" },
					{ "alt  B  C  M  N",    "browser · code · music · notes" },
					{ "alt  S  T  V  X  Y", "slack · term · V · X · Y" },
				},
			},
			{
				title = "SERVICE  (alt shift ;)",
				items = {
					{ "esc  r  f",          "reload · reset · float" },
					{ "⌫",                  "close all others" },
					{ "alt  shift  h / j / k / l", "join with window" },
				},
			},
		},
	},
	{
		title = "TERMINAL",
		color = c.sky,
		sections = {
			{
				title = "GHOSTTY",
				items = {
					{ "cmd  ← / →", "word back / forward" },
					{ "cmd  shift  ← / →", "line start / end" },
					{ "cmd  r",     "reload config" },
				},
			},
			{
				title = "ZELLIJ  —  direct nav  (locked mode)",
				items = {
					{ "ctrl  h / j / k / l", "focus pane ←↓↑→" },
					{ "ctrl  p / n",         "prev / next tab" },
					{ "ctrl  space",            "→ normal mode" },
				},
			},
			{
				title = "ZELLIJ  —  pane  (normal → v)",
				items = {
					{ "n  /  d  /  R", "new pane  /  ↓  /  →" },
					{ "f  /  w",       "fullscreen / float" },
					{ "x  /  r",       "close / rename" },
				},
			},
			{
				title = "ZELLIJ  —  tab  (normal → t)",
				items = {
					{ "J  /  K",       "next / prev  (normal mode)" },
					{ "n  /  x  /  r", "new / close / rename" },
					{ "h / j   1–9",   "navigate / jump to tab" },
					{ "[  /  ]",       "break pane left / right" },
				},
			},
		},
	},
	{
		title = "VIM",
		color = c.mauve,
		sections = {
			{
				title = "MOVEMENT",
				items = {
					{ "h  j  k  l",      "←  ↓  ↑  →" },
					{ "w  b  e",         "word fwd / back / end" },
					{ "0  ^  $",         "line start / non-ws / end" },
					{ "gg  G",           "top / bottom of file" },
					{ "ctrl-d  ctrl-u",  "½ page ↓ / ↑" },
					{ "{  }",            "prev / next paragraph" },
				},
			},
			{
				title = "SELECT & COPY",
				items = {
					{ "v  V  ctrl-v",  "char / line / block" },
					{ "iw  aw",        "inner / a word" },
					{ "i\"  i(  i{",   "inner quote / paren / brace" },
					{ "yy  /  dd",     "yank line / delete line" },
					{ "p  P",          "paste after / before" },
					{ "u  ctrl-r",     "undo / redo" },
				},
			},
			{
				title = "EDIT & SEARCH",
				items = {
					{ "i  a  o  O",     "insert before/after/below/above" },
					{ "cc  cw  c$",     "change line / word / to end" },
					{ ".",              "repeat last change" },
					{ "/  n  N  *",     "search / next / prev / word" },
					{ ":%s/old/new/g",  "global replace" },
				},
			},
		},
	},
}

-- ── Internal state ────────────────────────────────────────────────────────────
local canvas   = nil
local escHK    = nil
local toggleHK = nil
local visible  = false
local buildCanvas

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function st(text, attrs)
	return hs.styledtext.new(text, attrs)
end

local function activeScreen()
	local win = hs.window.focusedWindow()
	if win then
		return win:screen()
	end

	local screen = hs.mouse.getCurrentScreen()
	if screen then
		return screen
	end

	return hs.screen.primaryScreen()
end

local function hide()
	if canvas then canvas:hide() end
	visible = false
	if escHK then escHK:disable() end
end

local function toggle()
	if visible then
		hide()
	else
		if canvas then canvas:delete() end
		canvas = buildCanvas()
		if canvas then canvas:show() end
		visible = true
		if escHK then escHK:enable() end
	end
end

-- ── Layout constants ──────────────────────────────────────────────────────────
local PAD         = 20   -- outer padding
local COL_GAP     = 12   -- gap between columns
local COL_W       = 340  -- column width
local TITLE_BAR_H = 54   -- height of the top title bar
local COL_HEAD_H  = 36   -- group title height inside column
local COL_PAD_X   = 14   -- horizontal inner padding
local COL_PAD_TOP = 10   -- top padding inside column (after header)
local SEC_LABEL_H = 18   -- section label row height
local SEC_GAP     = 10   -- gap between sections
local ITEM_H      = 21   -- item row height
local KW          = 148  -- key column fixed width

local function colHeight(grp)
	local h = COL_HEAD_H + COL_PAD_TOP
	for si, sec in ipairs(grp.sections) do
		h = h + SEC_LABEL_H + #sec.items * ITEM_H
		if si < #grp.sections then h = h + SEC_GAP end
	end
	return h + COL_PAD_TOP
end

-- ── Canvas builder ────────────────────────────────────────────────────────────
buildCanvas = function()
	local screen = activeScreen()
	local sf     = screen:fullFrame()

	local maxColH = 0
	for _, grp in ipairs(GROUPS) do
		maxColH = math.max(maxColH, colHeight(grp))
	end

	local W = PAD * 2 + #GROUPS * COL_W + (#GROUPS - 1) * COL_GAP
	local H = TITLE_BAR_H + maxColH + PAD

	local cv = hs.canvas.new({
		x = sf.x + math.floor((sf.w - W) / 2),
		y = sf.y + math.floor((sf.h - H) / 2),
		w = W,
		h = H,
	})
	cv:level(hs.canvas.windowLevels.modalPanel)
	cv:behavior(hs.canvas.windowBehaviors.transient + hs.canvas.windowBehaviors.canJoinAllSpaces)

	local els = {}
	local function push(e) els[#els + 1] = e end

	-- ── Outer background ──
	push {
		type             = "rectangle",
		fillColor        = c.base,
		strokeColor      = c.surface0,
		strokeWidth      = 1.5,
		roundedRectRadii = { xRadius = 14, yRadius = 14 },
		frame            = { x = 0, y = 0, w = W, h = H },
	}

	-- ── Title bar ──
	push {
		type  = "text",
		text  = st("  NAVIGATION GUIDE", {
			font  = { name = FONT, size = TITLE_SZ, traits = { "bold" } },
			color = c.sky,
		}),
		frame = { x = PAD, y = 13, w = W / 2, h = 26 },
	}
	push {
		type  = "text",
		text  = st("ctrl-shift-?  or  esc  to close", {
			font           = { name = FONT, size = 10 },
			color          = c.overlay0,
			paragraphStyle = { alignment = "right" },
		}),
		frame = { x = PAD, y = 17, w = W - PAD * 2, h = 18 },
	}
	push {
		type      = "rectangle",
		fillColor = c.surface0,
		frame     = { x = PAD, y = 44, w = W - PAD * 2, h = 1 },
	}

	-- ── Columns ──
	for gi, grp in ipairs(GROUPS) do
		local cx = PAD + (gi - 1) * (COL_W + COL_GAP)
		local cy = TITLE_BAR_H

		-- Column background
		push {
			type             = "rectangle",
			fillColor        = { red = 0x1a / 255, green = 0x1a / 255, blue = 0x28 / 255, alpha = 1 },
			strokeColor      = { red = grp.color.red, green = grp.color.green, blue = grp.color.blue, alpha = 0.22 },
			strokeWidth      = 1,
			roundedRectRadii = { xRadius = 10, yRadius = 10 },
			frame            = { x = cx, y = cy, w = COL_W, h = maxColH },
		}

		-- Left accent strip
		push {
			type             = "rectangle",
			fillColor        = { red = grp.color.red, green = grp.color.green, blue = grp.color.blue, alpha = 0.75 },
			roundedRectRadii = { xRadius = 2, yRadius = 2 },
			frame            = { x = cx, y = cy + 9, w = 3, h = COL_HEAD_H - 14 },
		}

		-- Group title
		push {
			type  = "text",
			text  = st(grp.title, {
				font  = { name = FONT, size = HEAD_SZ, traits = { "bold" } },
				color = grp.color,
			}),
			frame = { x = cx + 12, y = cy + 8, w = COL_W - 20, h = 22 },
		}

		-- Header underline
		push {
			type      = "rectangle",
			fillColor = { red = grp.color.red, green = grp.color.green, blue = grp.color.blue, alpha = 0.18 },
			frame     = { x = cx + 12, y = cy + COL_HEAD_H - 4, w = COL_W - 24, h = 1 },
		}

		-- Sections
		local iy = cy + COL_HEAD_H + COL_PAD_TOP

		for si, sec in ipairs(grp.sections) do
			-- Separator line before section (not before first)
			if si > 1 then
				push {
					type      = "rectangle",
					fillColor = { red = 0.28, green = 0.29, blue = 0.38, alpha = 1 },
					frame     = { x = cx + COL_PAD_X, y = iy - math.floor(SEC_GAP / 2), w = COL_W - COL_PAD_X * 2, h = 1 },
				}
			end

			-- Section label
			push {
				type  = "text",
				text  = st(sec.title:upper(), {
					font  = { name = FONT, size = SEC_SZ, traits = { "bold" } },
					color = { red = grp.color.red, green = grp.color.green, blue = grp.color.blue, alpha = 0.55 },
				}),
				frame = { x = cx + COL_PAD_X, y = iy, w = COL_W - COL_PAD_X * 2, h = SEC_LABEL_H },
			}
			iy = iy + SEC_LABEL_H

			-- Items
			for _, item in ipairs(sec.items) do
				push {
					type  = "text",
					text  = st(item[1], {
						font  = { name = FONT, size = BODY_SZ, traits = { "bold" } },
						color = c.sky,
					}),
					frame = { x = cx + COL_PAD_X, y = iy, w = KW, h = ITEM_H },
				}
				push {
					type  = "text",
					text  = st(item[2], {
						font  = { name = FONT, size = BODY_SZ },
						color = c.subtext1,
					}),
					frame = { x = cx + COL_PAD_X + KW, y = iy, w = COL_W - COL_PAD_X - KW - 8, h = ITEM_H },
				}
				iy = iy + ITEM_H
			end

			if si < #grp.sections then iy = iy + SEC_GAP end
		end
	end

	for i, e in ipairs(els) do cv[i] = e end
	return cv
end

-- ── Public API ────────────────────────────────────────────────────────────────
function M.start()
	canvas = buildCanvas()
	escHK    = hs.hotkey.new({}, "escape", hide)
	toggleHK = hs.hotkey.bind({ "ctrl", "shift" }, "/", toggle)

	hs.screen.watcher.new(function()
		hs.timer.doAfter(1.0, function()
			local was = visible
			if canvas then canvas:delete() end
			canvas = buildCanvas()
			if was then
				canvas:show()
				visible = true
				if escHK then escHK:enable() end
			end
		end)
	end):start()
end

function M.stop()
	if toggleHK then toggleHK:delete() end
	if escHK    then escHK:delete() end
	if canvas   then canvas:delete() end
	canvas  = nil
	visible = false
end

return M
