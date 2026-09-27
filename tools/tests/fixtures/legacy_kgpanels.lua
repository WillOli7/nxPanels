-- Made-up kgPanels_Reloaded saved variables covering the tricky legacy cases:
-- numbers stored as strings, translated "None", translated border names,
-- percent sizes, panel-to-panel anchors, anchoring loops, scripts, custom art.
local function panel(t)
	local p = {
		absolute_bg = { LLx = 0, LLy = 1, LRx = 1, LRy = 1, ULx = 0, ULy = 0, URx = 1, URy = 0 },
		anchor = "UIParent", anchorFrom = "CENTER", anchorTo = "CENTER",
		bg_alpha = 1, bg_blend = "BLEND", bg_color = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
		bg_insets = { b = 4, l = 4, r = -4, t = -4 }, bg_orientation = "HORIZONTAL",
		bg_style = "SOLID", bg_texture = "Solid",
		border_advanced = { enable = false, show = { BOT = true, BOTLEFTCORNER = true, BOTRIGHTCORNER = true, LEFT = true, RIGHT = true, TOP = true, TOPLEFTCORNER = true, TOPRIGHTCORNER = true } },
		border_color = { a = 1, b = 1, g = 1, r = 1 }, border_edgeSize = 16, border_texture = "Blizzard Tooltip",
		crop = false, gradient_color = { a = 1, b = 1, g = 1, r = 1 },
		height = "100", width = "200", hflip = false, vflip = false, level = 0, mouse = false,
		parent = "UIParent", rotation = 0, scripts = {}, strata = "BACKGROUND", sub_level = 0,
		text = { color = { a = 1, b = 1, g = 1, r = 1 }, font = "Blizzard", justifyH = "CENTER", justifyV = "MIDDLE", size = 12, text = "", x = 0, y = 0 },
		tileSize = 0, tiling = false, use_absolute_bg = false, x = 0, y = 0,
	}
	for k, v in pairs(t) do p[k] = v end
	return p
end

kgPanelsDB = {
	profileKeys = {
		["Muse - Hyjal"] = "Default",
		["Alt - Hyjal"] = "Alt",
		["Other - Hyjal"] = "Empty",
	},
	profiles = {
		Default = { layout = "Main UI" },
		Alt = { layout = "Second", enabled = false },
		Empty = { layout = "Aucun" },
	},
	namespaces = { ["LibDualSpec-1.0"] = { char = { ["Muse - Hyjal"] = { enabled = true, "Default", "Alt" } } } },
	global = {
		artwork = { ["My Art"] = "Interface\\AddOns\\MyMedia\\art.tga", ["Solid"] = "Interface\\Buttons\\WHITE8x8" },
		border = { ["Bulle d'aide de Blizzard"] = "Interface\\Tooltips\\UI-Tooltip-Border", ["My Border"] = "Interface\\AddOns\\MyMedia\\border.tga" },
		layout_deps = { ["Main UI"] = { ["Scripted"] = "Details" } },
		foldersByLayout = { ["Main UI"] = { Bars = true, __ROOT__ = true } },
		layouts = {
			["无"] = {},
			["Main UI"] = {
				["Bottom Bar"] = panel({ width = "100%", height = "32", x = "0", y = "-520", folder = "Bars", border_texture = "Aucun" }),
				["Chat BG"] = panel({ anchor = "Bottom Bar", anchorFrom = "BOTTOMLEFT", anchorTo = "TOPLEFT", x = 4, y = "2",
					border_texture = "Bulle d'aide de Blizzard", bg_texture = "My Art",
					text = { color = { a = 1, b = 0, g = 0.8, r = 1 }, font = "暴雪", justifyH = "LEFT", justifyV = "TOP", size = 0, text = "||cffff0000Chat||r", x = 2, y = -2 } }),
				["Loop A"] = panel({ anchor = "Loop B" }),
				["Loop B"] = panel({ anchor = "Loop A" }),
				["Scripted"] = panel({ mouse = true, level = -3, scripts = {
					LOAD = "self.loaded = (self.loaded or 0) + 1 LoadedBy = kgPanels",
					EVENT = "if event == 'PLAYER_TARGET_CHANGED' then self.lastArg = arg1 self.found = kgPanels:FetchFrame('Bottom Bar') end",
					CLICK = "if pressed then self.down = button elseif released then self.up = button end",
					UPDATE = "error('boom')",
					SHOW = "-- comment on the last line",
					HIDE = "",
				} }),
				["Waiting"] = panel({ parent = "SomeAddonFrame", anchor = "SomeAddonFrame" }),
			},
			["Second"] = {
				["Art"] = panel({ bg_texture = "My Art", rotation = 90, hflip = true, bg_style = "GRADIENT",
					gradient_color = { r = 0, g = 0, b = 1, a = "0.5" }, border_advanced = { enable = true, show = { TOP = false, BOT = true } },
					border_texture = "My Border", sub_level = 12 }),
				["Tiled"] = panel({ tiling = true, tileSize = 32, bg_texture = "Solid", border_texture = "None" }),
			},
		},
	},
}
