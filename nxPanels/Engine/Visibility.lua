local _, ns = ...

--[[
Display conditions and opacity of the panels (panel.display), without scripts.

A panel whose display settings are all at their defaults is never touched here:
its scripts keep full control of its visibility and opacity (legacy layouts).
Otherwise the panel is shown when every condition is met, with the base, combat
or mouse-over opacity, and changes fade over `fade` seconds.
]]
local Visibility = {}
ns.Visibility = Visibility

local inCombat = false
local fades = {}         -- [frame] = { from, to, elapsed, duration, hide }
local driver = CreateFrame("Frame")
Visibility.driver = driver
local pollElapsed = 0
local POLL = 0.1

local function isDefault(d)
	return d.combat == "ANY" and d.group == "ANY" and d.instance == "ANY" and d.mounted == "ANY"
		and d.target == "ANY" and not d.hidePetBattle and not d.macro:find("%S")
		and d.alpha == 1 and d.combatAlpha == 1 and d.hoverAlpha == 1 and d.fade <= 0
end
Visibility.IsDefault = isDefault

-- Needs a regular check (mouse-over, macro conditions: no event for every case)
local function needsPolling(d)
	return d.hoverAlpha ~= d.alpha or d.hoverAlpha ~= d.combatAlpha or d.macro:find("%S") ~= nil
end

local function conditionsMet(d)
	if d.combat == "IN" and not inCombat then return false end
	if d.combat == "OUT" and inCombat then return false end
	if d.group ~= "ANY" then
		local raid, group = IsInRaid(), IsInGroup()
		if d.group == "SOLO" and group then return false end
		if d.group == "GROUP" and not group then return false end
		if d.group == "PARTY" and (not group or raid) then return false end
		if d.group == "RAID" and not raid then return false end
	end
	if d.instance ~= "ANY" then
		local inside, kind = IsInInstance()
		if d.instance == "WORLD" and inside then return false end
		if d.instance == "INSTANCE" and not inside then return false end
		if d.instance == "DUNGEON" and kind ~= "party" then return false end
		if d.instance == "RAID" and kind ~= "raid" then return false end
		if d.instance == "PVP" and kind ~= "pvp" and kind ~= "arena" then return false end
	end
	if d.mounted ~= "ANY" and (IsMounted() and "YES" or "NO") ~= d.mounted then return false end
	if d.target ~= "ANY" and (UnitExists("target") and "YES" or "NO") ~= d.target then return false end
	if d.hidePetBattle and C_PetBattles and C_PetBattles.IsInBattle() then return false end
	if d.macro:find("%S") and SecureCmdOptionParse then
		local ok, result = pcall(SecureCmdOptionParse, d.macro)
		if ok and result and strtrim(result):lower() == "hide" then return false end
	end
	return true
end

-- Mouse-over opacity wins over the combat opacity, which wins over the base one
local function targetAlpha(frame, d)
	local alpha = inCombat and d.combatAlpha or d.alpha
	if d.hoverAlpha ~= alpha and frame:IsVisible() and frame:IsMouseOver() then
		return d.hoverAlpha
	end
	return alpha
end

local function finish(frame, f)
	fades[frame] = nil
	frame:SetAlpha(f.to)
	if f.hide then frame:Hide() end
end

local function fadeTo(frame, to, duration, hide)
	local current = frame:IsShown() and frame:GetAlpha() or 0
	local f = fades[frame]
	if f and f.to == to and f.hide == hide then return end
	if not hide then frame:Show() end
	if duration <= 0 or math.abs(current - to) < 0.01 then
		fades[frame] = nil
		frame:SetAlpha(to)
		if hide then frame:Hide() end
		return
	end
	frame:SetAlpha(current)
	fades[frame] = { from = current, to = to, elapsed = 0, duration = duration * math.abs(to - current), hide = hide }
end

--[[
Applies the display settings of a panel of the active layout.
instant: no fade (the panel was just placed)
]]
function Visibility:Refresh(panelId, instant)
	local frame = ns.Layouts.frames[panelId]
	local layout = ns.Database:GetLayout(ns.Layouts.activeId)
	local panel = layout and layout.panels[panelId]
	if not frame or not panel or ns.Layouts.waiting[panelId] then return end
	local d = panel.display
	if self.forceShow then
		-- Edit mode shows everything
		fades[frame] = nil
		frame:SetAlpha(1)
		frame:Show()
		return
	end
	if isDefault(d) then
		-- Default settings leave the panel to its scripts
		if frame.nxManaged then
			frame.nxManaged = nil
			fades[frame] = nil
			frame:SetAlpha(1)
		end
		frame:Show()
		return
	end
	frame.nxManaged = true
	local fade = instant and 0 or d.fade
	if conditionsMet(d) then
		fadeTo(frame, targetAlpha(frame, d), fade, false)
	else
		fadeTo(frame, 0, fade, true)
	end
end

function Visibility:RefreshAll(instant)
	for panelId in pairs(ns.Layouts.frames) do
		self:Refresh(panelId, instant)
	end
end

-- A frame goes back to the pool
function Visibility:Forget(frame)
	fades[frame] = nil
	frame.nxManaged = nil
	frame:SetAlpha(1)
end

-- Edit mode: every panel shown and opaque, so it can be grabbed
function Visibility:SetForceShow(on)
	self.forceShow = on and true or nil
	self:RefreshAll(true)
end

function Visibility:InCombat() return inCombat end

---------------------------------------------------------------------------
-- Fades and polling
---------------------------------------------------------------------------
driver:SetScript("OnUpdate", function(_, elapsed)
	for frame, f in pairs(fades) do
		f.elapsed = f.elapsed + elapsed
		if f.elapsed >= f.duration then
			finish(frame, f)
		else
			frame:SetAlpha(f.from + (f.to - f.from) * f.elapsed / f.duration)
		end
	end
	pollElapsed = pollElapsed + elapsed
	if pollElapsed < POLL then return end
	pollElapsed = 0
	local layout = ns.Database and ns.Layouts.activeId and ns.Database:GetLayout(ns.Layouts.activeId)
	if not layout or Visibility.forceShow then return end
	for panelId, frame in pairs(ns.Layouts.frames) do
		local panel = layout.panels[panelId]
		if panel and frame.nxManaged and needsPolling(panel.display) then
			Visibility:Refresh(panelId, false)
		end
	end
end)

function Visibility:Init()
	inCombat = UnitAffectingCombat("player") and true or false
	local function refresh() self:RefreshAll(false) end
	ns:RegisterEvent("PLAYER_REGEN_DISABLED", function() inCombat = true refresh() end)
	ns:RegisterEvent("PLAYER_REGEN_ENABLED", function() inCombat = false refresh() end)
	for _, event in ipairs({
		"GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_TARGET_CHANGED",
		"PLAYER_MOUNT_DISPLAY_CHANGED", "PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE",
		"MODIFIER_STATE_CHANGED", "UPDATE_SHAPESHIFT_FORM", "ACTIONBAR_PAGE_CHANGED", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE",
	}) do
		ns:RegisterEvent(event, refresh)
	end
end
