local _, O = ...
local T = O.Theme
local C = T.colors
local L = O.L
local core = O.core

--[[
Frame picker: point a frame of the interface with the mouse to attach a panel
to it (instead of typing its name, like /fstack).
	Picker:Start(onPick)   onPick(ref): "panel:<id>" or a global frame name
Only named frames can be referenced. The mouse wheel goes through the frames
stacked under the cursor, from the smallest to the biggest.
]]
local Picker = {}
O.Picker = Picker

local IGNORED = {
	UIParent = true, WorldFrame = true, nxPanelsOptionsFrame = true, nxPanelsPicker = true,
	nxPanelsEditMode = true, nxPanelsBrowser = true,
}
local THROTTLE = 0.1

--[[
Retail 12 hides some values of other addons' frames ("secret values", e.g.
aura frames): testing them is an error. Such frames are skipped.
]]
local isSecret = issecretvalue or function() return false end

local function secret(...)
	for i = 1, select("#", ...) do
		if isSecret((select(i, ...))) then return true end
	end
	return false
end

-- { frame, name, area } when the frame is a named frame under the point, nil otherwise
local function candidate(frame, x, y)
	local forbidden, visible = frame:IsForbidden(), frame:IsVisible()
	if secret(forbidden, visible) or forbidden or not visible then return end
	local name = frame:GetName()
	if secret(name) or type(name) ~= "string" or IGNORED[name] or _G[name] ~= frame then return end
	local l, b, w, h = frame:GetRect()
	local s = frame:GetEffectiveScale()
	if secret(l, b, w, h, s) or not l or w <= 0 or h <= 0 then return end
	local cx, cy = x / s, y / s
	if cx >= l and cx <= l + w and cy >= b and cy <= b + h then
		return { frame = frame, name = name, area = w * h * s * s }
	end
end

-- Named frames under the cursor, smallest first
local function framesUnderCursor()
	local list = {}
	local x, y = GetCursorPosition()
	local frame = EnumerateFrames()
	while frame do
		-- pcall: a protected value that is not detected must not break the picker
		local ok, found = pcall(candidate, frame, x, y)
		if ok and found then list[#list + 1] = found end
		frame = EnumerateFrames(frame)
	end
	table.sort(list, function(a, b) return a.area < b.area end)
	return list
end

-- Reference stored in the panel data
local function refOf(name)
	local id = name:match("^nxPanel_(.+)$")
	return id and ("panel:" .. id) or name
end

local function create()
	local f = CreateFrame("Frame", "nxPanelsPicker", UIParent)
	f:SetAllPoints(UIParent)
	f:SetFrameStrata("TOOLTIP")
	f:EnableMouse(true)
	f:EnableMouseWheel(true)
	f:EnableKeyboard(true)
	f:Hide()

	f.box = CreateFrame("Frame", nil, f)
	T:Fill(f.box, C.accentSoft)
	f.box.edges = T:Border(f.box, C.accent)

	f.help = CreateFrame("Frame", nil, f)
	f.help:SetSize(560, 58)
	f.help:SetPoint("TOP", 0, -40)
	T:Fill(f.help, C.window)
	T:Border(f.help, C.accent)
	f.name = T:Text(f.help, T.fonts.header, C.accent, "CENTER")
	f.name:SetPoint("TOP", 0, -10)
	f.hint = T:Text(f.help, T.fonts.small, C.textDim, "CENTER")
	f.hint:SetPoint("BOTTOM", 0, 10)
	f.hint:SetText(L["PICKER_HINT"])

	local elapsed = THROTTLE
	f:SetScript("OnUpdate", function(_, e)
		elapsed = elapsed + e
		if elapsed < THROTTLE then return end
		elapsed = 0
		Picker:Update()
	end)
	f:SetScript("OnMouseWheel", function(_, delta)
		Picker.index = math.max(1, math.min(#Picker.list, Picker.index - delta))
		Picker:Draw()
	end)
	f:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then
			local c = Picker.list[Picker.index]
			Picker:Stop(c and refOf(c.name))
		else
			Picker:Stop(nil)
		end
	end)
	f:SetScript("OnKeyDown", function(self, key)
		local handled = key == "ESCAPE"
		if handled then Picker:Stop(nil) end
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(not handled) end
	end)
	Picker.frame = f
end

function Picker:Update()
	local previous = self.list[self.index]
	self.list = framesUnderCursor()
	self.index = 1
	-- Keeps the frame chosen with the wheel while it is still under the cursor
	if previous then
		for i, c in ipairs(self.list) do
			if c.frame == previous.frame then self.index = i break end
		end
	end
	self:Draw()
end

function Picker:Draw()
	local f = self.frame
	local c = self.list[self.index]
	if not c then
		f.box:Hide()
		f.name:SetText(L["PICKER_NONE"])
		return
	end
	-- The frame was readable when it was found; it may be protected since
	local ok, l, b, w, h = pcall(c.frame.GetRect, c.frame)
	local s = c.frame:GetEffectiveScale()
	if not ok or not l or secret(l, b, w, h, s) then
		f.box:Hide()
		return
	end
	s = s / UIParent:GetEffectiveScale()
	f.box:ClearAllPoints()
	f.box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l * s, b * s)
	f.box:SetSize(w * s, h * s)
	f.box:Show()
	local id = c.name:match("^nxPanel_(.+)$")
	local layout = id and core.Database:GetLayout(core.Layouts.activeId)
	local label = id and layout and layout.panels[id] and L["PANEL_REF"]:format(layout.panels[id].name) or c.name
	f.name:SetText(("%s  |cff888888(%d/%d)|r"):format(label, self.index, #self.list))
end

function Picker:Start(onPick)
	if InCombatLockdown() then
		core:Print(L["EDIT_MODE_COMBAT"])
		return
	end
	if not self.frame then create() end
	self.onPick = onPick
	self.list, self.index = {}, 1
	-- The options window would hide the frames behind it
	self.reopen = O.Options.frame and O.Options.frame:IsShown()
	if self.reopen then O.Options.frame:Hide() end
	O.Dropdown:Close()
	self.frame:Show()
	self:Update()
end

function Picker:Stop(ref)
	self.frame:Hide()
	if self.reopen then O.Options:Show() end
	local onPick = self.onPick
	self.onPick = nil
	if ref and onPick then onPick(ref) end
end
