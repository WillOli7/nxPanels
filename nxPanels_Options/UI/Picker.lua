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
local THROTTLE = 0.05
local SCAN_BATCH = 1500

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

-- Name of a frame that can be referenced (named, reachable by its name), nil otherwise
local function referencable(frame)
	local forbidden = frame:IsForbidden()
	if secret(forbidden) or forbidden then return end
	local name = frame:GetName()
	if secret(name) or type(name) ~= "string" or IGNORED[name] or _G[name] ~= frame then return end
	return name
end

-- Area of the frame when it is shown under the point, nil otherwise
local function areaUnder(frame, x, y)
	local visible = frame:IsVisible()
	if secret(visible) or not visible then return end
	local l, b, w, h = frame:GetRect()
	local s = frame:GetEffectiveScale()
	if secret(l, b, w, h, s) or not l or w <= 0 or h <= 0 then return end
	local cx, cy = x / s, y / s
	if cx >= l and cx <= l + w and cy >= b and cy <= b + h then
		return w * h * s * s
	end
end

--[[
The interface can hold tens of thousands of frames: they are scanned once per
pick, SCAN_BATCH at a time (no freeze), and only the named ones are kept.
Returns true when the scan is over.
]]
function Picker:Scan()
	local frame = self.scanStarted and self.scanFrame or EnumerateFrames()
	self.scanStarted = true
	local n = 0
	while frame and n < SCAN_BATCH do
		-- pcall: a protected value that is not detected must not break the picker
		local ok, name = pcall(referencable, frame)
		if ok and name then self.named[#self.named + 1] = { frame = frame, name = name } end
		frame = EnumerateFrames(frame)
		n = n + 1
	end
	self.scanned = self.scanned + n
	self.scanFrame = frame
	return frame == nil
end

-- Named frames under the cursor, smallest first
function Picker:FramesUnderCursor()
	local list = {}
	local x, y = GetCursorPosition()
	for _, c in ipairs(self.named) do
		local ok, area = pcall(areaUnder, c.frame, x, y)
		if ok and area then list[#list + 1] = { frame = c.frame, name = c.name, area = area } end
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
		-- First the scan of the interface, one batch per frame
		if not Picker.scanDone then
			Picker.scanDone = Picker:Scan()
			f.name:SetText(L["PICKER_SCANNING"]:format(Picker.scanned))
			if not Picker.scanDone then return end
		end
		elapsed = elapsed + e
		if elapsed < THROTTLE then return end
		elapsed = 0
		-- Then only when the mouse moved
		local x, y = GetCursorPosition()
		if x ~= Picker.lastX or y ~= Picker.lastY then
			Picker.lastX, Picker.lastY = x, y
			Picker:Update()
		end
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
	self.list = self:FramesUnderCursor()
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
	self.named, self.scanned, self.scanDone, self.scanStarted, self.scanFrame = {}, 0, false, false, nil
	self.lastX, self.lastY = nil, nil
	-- The options window would hide the frames behind it
	self.reopen = O.Options.frame and O.Options.frame:IsShown()
	if self.reopen then O.Options.frame:Hide() end
	O.Dropdown:Close()
	self.frame:Show()
	self.frame.box:Hide()
	self.frame.name:SetText(L["PICKER_SCANNING"]:format(0))
end

function Picker:Stop(ref)
	self.frame:Hide()
	if self.reopen then O.Options:Show() end
	local onPick = self.onPick
	self.onPick = nil
	if ref and onPick then onPick(ref) end
end
