local _, ns = ...

-- Data schema version of nxPanelsDB. Bump it and add a step in Database:Upgrade on changes.
ns.SCHEMA = 3

-- Every key here is neutral (never translated). Media are LibSharedMedia keys;
-- false means "no texture", a nil font means "language default font".
-- A background texture "atlas:<name>" is a Blizzard atlas.
ns.PanelDefaults = {
	name = "",
	folder = nil,

	parent = "UIParent",
	anchor = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 },
	width = 200, widthUnit = "px",   -- "px" or "%" of the parent
	height = 100, heightUnit = "px",
	scale = 1,
	strata = "BACKGROUND",
	level = 0,
	mouse = false,

	background = {
		style = "SOLID",              -- SOLID, GRADIENT, NONE (no tint)
		colorMode = "CUSTOM",         -- CUSTOM, CLASS, FACTION, REACTION (of the target): replaces the first color
		texture = "Solid",
		color = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
		color2 = { r = 1, g = 1, b = 1, a = 1 },
		orientation = "HORIZONTAL",
		blend = "BLEND",
		alpha = 1,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
		rotation = 0,
		flipH = false,
		flipV = false,
		texCoord = nil,               -- { ULx, ULy, LLx, LLy, URx, URy, LRx, LRy }
		tile = false,
		tileSize = 0,
		subLevel = 0,
	},

	border = {
		texture = "Blizzard Tooltip",
		colorMode = "CUSTOM",
		color = { r = 1, g = 1, b = 1, a = 1 },
		size = 16,
		hidden = {},                  -- [section] = true: LEFT, RIGHT, TOP, BOT, TOPLEFTCORNER...
	},

	text = {
		value = "",
		font = nil,
		size = 12,
		outline = "",                 -- "", "OUTLINE", "THICKOUTLINE"
		color = { r = 1, g = 1, b = 1, a = 1 },
		x = 0,
		y = 0,
		justifyH = "CENTER",
		justifyV = "MIDDLE",
	},

	-- When the panel is shown, and how opaque (see Engine/Visibility.lua).
	-- With every value at its default the panel is never hidden nor faded.
	display = {
		combat = "ANY",               -- ANY, IN, OUT
		group = "ANY",                -- ANY, SOLO, GROUP, PARTY (group, not raid), RAID
		instance = "ANY",             -- ANY, WORLD, INSTANCE, DUNGEON, RAID, PVP
		mounted = "ANY",              -- ANY, YES, NO
		target = "ANY",               -- ANY, YES, NO
		hidePetBattle = false,
		macro = "",                   -- macro conditions, e.g. "[combat] show; hide"
		alpha = 1,
		combatAlpha = 1,
		hoverAlpha = 1,
		fade = 0,                     -- seconds of the fade when shown / hidden / opacity changes
	},

	scripts = {},                     -- [hook] = code: LOAD, EVENT, UPDATE, SHOW, HIDE, ENTER, LEAVE, CLICK, RESIZE, DROP
	scriptDependency = nil,           -- addon that must be loaded before the scripts run
}
