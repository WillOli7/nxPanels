local _, ns = ...

--[[
Automatic colors of backgrounds and borders (colorMode):
	CUSTOM     the color chosen by the user
	CLASS      class color of the player
	FACTION    Horde red / Alliance blue
	REACTION   hostile / neutral / friendly target (custom color without target)
The alpha always comes from the custom color.
]]
local Colors = {}
ns.Colors = Colors

local FACTION = {
	Horde = { 0.78, 0.13, 0.13 },
	Alliance = { 0.18, 0.4, 0.86 },
}
local REACTION = {
	hostile = { 0.86, 0.2, 0.2 },
	neutral = { 0.92, 0.8, 0.22 },
	friendly = { 0.24, 0.8, 0.34 },
}

local function classColor()
	local _, classFile = UnitClass("player")
	local c = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFile)
		or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
	if c then return c.r, c.g, c.b end
end

local function reactionColor()
	if not UnitExists("target") then return end
	local c
	if UnitCanAttack("player", "target") then
		c = REACTION.hostile
	elseif UnitIsFriend("player", "target") then
		c = REACTION.friendly
	else
		c = REACTION.neutral
	end
	return c[1], c[2], c[3]
end

-- r, g, b, a of a color table in the given mode
function Colors:Get(mode, color)
	local r, g, b
	if mode == "CLASS" then
		r, g, b = classColor()
	elseif mode == "FACTION" then
		local c = FACTION[UnitFactionGroup("player") or ""]
		if c then r, g, b = c[1], c[2], c[3] end
	elseif mode == "REACTION" then
		r, g, b = reactionColor()
	end
	if not r then r, g, b = color.r, color.g, color.b end
	return r, g, b, color.a
end

-- The target changed: redraws the colors of the panels that follow it
function Colors:Init()
	ns:RegisterEvent("PLAYER_TARGET_CHANGED", function()
		local layout = ns.Database:GetLayout(ns.Layouts.activeId)
		if not layout then return end
		for panelId, frame in pairs(ns.Layouts.frames) do
			local panel = layout.panels[panelId]
			if panel and (panel.background.colorMode == "REACTION" or panel.border.colorMode == "REACTION") then
				ns.Panel:ApplyColors(frame, panel)
			end
		end
	end)
end
