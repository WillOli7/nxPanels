local _, O = ...
local L = O.L

--[[
Ready-made templates of the gallery (Import / Export page). Each template is a
set of panels in the export format: keys are local ids, "panel:<key>" links the
panels of one template. Missing values come from the panel defaults, names are
translated when the template is added.
]]
local function color(r, g, b, a) return { r = r, g = g, b = b, a = a } end
local NO_BORDER = { texture = false }

O.Templates = {
	{
		key = "INFO_BAR",
		panels = function() return {
			bar = {
				name = L["TPL_INFO_BAR"],
				anchor = { point = "TOP", relativeTo = "UIParent", relativePoint = "TOP", x = 0, y = 0 },
				width = 100, widthUnit = "%", height = 24, strata = "LOW",
				background = { style = "GRADIENT", orientation = "VERTICAL", color = color(0, 0, 0, 0.35), color2 = color(0, 0, 0, 0.85),
					insets = { left = 0, right = 0, top = 0, bottom = 0 } },
				border = NO_BORDER,
				text = { value = "{zone}   ·   {time}   ·   {fps} fps   ·   {latency} ms", size = 12, outline = "OUTLINE" },
			},
			line = {
				name = L["TPL_INFO_BAR_LINE"],
				parent = "panel:bar",
				anchor = { point = "TOP", relativeTo = "panel:bar", relativePoint = "BOTTOM", x = 0, y = 0 },
				width = 100, widthUnit = "%", height = 2, strata = "LOW",
				background = { colorMode = "CLASS", color = color(1, 1, 1, 0.9), insets = { left = 0, right = 0, top = 0, bottom = 0 } },
				border = NO_BORDER,
			},
		} end,
	},
	{
		key = "ACTION_BARS",
		panels = function() return {
			frame = {
				name = L["TPL_ACTION_BARS"],
				anchor = { point = "BOTTOM", relativeTo = "UIParent", relativePoint = "BOTTOM", x = 0, y = 0 },
				width = 580, height = 124,
				background = { style = "NONE", texture = "Blizzard Dialog Background Dark", color = color(1, 1, 1, 1) },
				border = { texture = "Blizzard Tooltip", size = 16, color = color(0.8, 0.8, 0.8, 1) },
			},
		} end,
	},
	{
		key = "CHAT",
		panels = function() return {
			chat = {
				name = L["TPL_CHAT"],
				anchor = { point = "BOTTOMLEFT", relativeTo = "UIParent", relativePoint = "BOTTOMLEFT", x = 12, y = 12 },
				width = 460, height = 220,
				background = { color = color(0.02, 0.02, 0.03, 0.6) },
				border = { texture = "Blizzard Tooltip", size = 14, color = color(0.55, 0.55, 0.6, 1) },
			},
		} end,
	},
	{
		key = "COMBAT_GLOW",
		panels = function() return {
			glow = {
				name = L["TPL_COMBAT_GLOW"],
				anchor = { point = "BOTTOM", relativeTo = "UIParent", relativePoint = "BOTTOM", x = 0, y = 0 },
				width = 100, widthUnit = "%", height = 140,
				background = { style = "GRADIENT", orientation = "VERTICAL", color = color(0.8, 0.05, 0.05, 0.45), color2 = color(0.8, 0.05, 0.05, 0),
					insets = { left = 0, right = 0, top = 0, bottom = 0 } },
				border = NO_BORDER,
				display = { combat = "IN", fade = 0.4 },
			},
		} end,
	},
	{
		key = "HOVER_BOX",
		panels = function() return {
			box = {
				name = L["TPL_HOVER_BOX"],
				anchor = { point = "RIGHT", relativeTo = "UIParent", relativePoint = "RIGHT", x = -40, y = 0 },
				width = 260, height = 180,
				background = { color = color(0.05, 0.05, 0.06, 0.8) },
				border = { texture = "Blizzard Tooltip", size = 14, color = color(1, 1, 1, 1) },
				display = { alpha = 0.15, combatAlpha = 0.15, hoverAlpha = 1, fade = 0.25 },
			},
		} end,
	},
	{
		key = "TARGET_TINT",
		panels = function() return {
			tint = {
				name = L["TPL_TARGET_TINT"],
				anchor = { point = "TOP", relativeTo = "UIParent", relativePoint = "TOP", x = 0, y = -90 },
				width = 300, height = 6,
				background = { colorMode = "REACTION", color = color(0.4, 0.4, 0.4, 0.9), insets = { left = 0, right = 0, top = 0, bottom = 0 } },
				border = NO_BORDER,
				display = { target = "YES", fade = 0.2 },
			},
		} end,
	},
}

-- Payload of a template, ready for nxPanels.Share.AddPanels
function O.TemplatePayload(template)
	return { layout = { name = L["TPL_" .. template.key], folders = {}, panels = template.panels() } }
end

-- Adds a template to the active layout (or to a new layout); returns the layout and panel ids
function O.AddTemplate(template, newLayout)
	local core = O.core
	local payload = O.TemplatePayload(template)
	local layoutId = not newLayout and core.Database:GetActiveLayoutId()
	if not layoutId then
		layoutId = core.Database:CreateLayout(payload.layout.name)
		core.Layouts:Activate(layoutId)
	end
	local ids = core.Share.AddPanels(payload, layoutId)
	for _, panelId in ipairs(ids) do core.Layouts:PanelChanged(panelId, "added") end
	core:Print(L["IMPORT_PANELS_DONE"], #ids, core.Database:GetLayout(layoutId).name)
	return layoutId, ids
end
