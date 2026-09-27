local _, ns = ...

-- Data schema version of nxPanelsDB. Bump it and add a step in Database:Upgrade on changes.
ns.SCHEMA = 1

-- Every key here is neutral (never translated). Media are LibSharedMedia keys;
-- false means "no texture", a nil font means "language default font".
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

	scripts = {},                     -- [hook] = code: LOAD, EVENT, UPDATE, SHOW, HIDE, ENTER, LEAVE, CLICK, RESIZE, DROP
	scriptDependency = nil,           -- addon that must be loaded before the scripts run
}
