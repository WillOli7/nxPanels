local _, ns = ...
local L = ns.L

-- Shows the active layout: places every panel, then starts the scripts
local Layouts = {}
ns.Layouts = Layouts

Layouts.frames = {}       -- [panelId] = frame of the active layout
Layouts.waiting = {}      -- [panelId] = true: parent or anchor frame does not exist yet
Layouts.cyclic = {}       -- [panelId] = true: part of an anchoring loop, anchored to the screen
local waitingAddon = {}   -- [addon] = { [panelId] = true }: scripts waiting for an addon
local started = {}        -- [panelId] = true: scripts attached
local ticker

local RETRY_INTERVAL, RETRY_COUNT = 1, 60

function Layouts:Init()
	ns:RegisterEvent("ADDON_LOADED", function(_, addon) self:OnAddonLoaded(addon) end)
	ns:RegisterEvent("PLAYER_ENTERING_WORLD", function() self:RetryWaiting() end)
	ns:RegisterEvent("DISPLAY_SIZE_CHANGED", function() self:RefreshAll() end)
	ns:RegisterEvent("UI_SCALE_CHANGED", function() self:RefreshAll() end)
end

local function activeLayout()
	return ns.Database:GetLayout(Layouts.activeId)
end

function Layouts:ReleaseAll()
	for _, frame in pairs(self.frames) do
		ns.Scripts:Detach(frame)
		ns.Panel:Release(frame)
	end
	wipe(self.frames)
	wipe(self.waiting)
	wipe(self.cyclic)
	wipe(waitingAddon)
	wipe(started)
	ns.Media:ClearWaiting()
	ns.Scripts:ResetErrors()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
	self.activeId = nil
end

function Layouts:ApplyActive()
	self:ReleaseAll()
	if not ns.db.profile.enabled then return end
	local id = ns.Database:GetActiveLayoutId()
	local layout = ns.Database:GetLayout(id)
	if not layout then return end
	self.activeId = id

	local order, cyclic = ns.Anchors:Order(layout.panels)
	self.cyclic = cyclic
	-- Every frame exists before placing, so panels can reference each other
	for _, panelId in ipairs(order) do
		self.frames[panelId] = ns.Panel:Acquire(panelId)
	end
	for _, panelId in ipairs(order) do
		if cyclic[panelId] then
			ns:Print(L["ANCHOR_CYCLE"], layout.panels[panelId].name)
		end
		self:Place(panelId)
	end
	for _, panelId in ipairs(order) do
		self:StartScripts(panelId)
	end
	self:StartRetry()
end

-- Parent and anchor frames of a panel (nil when they do not exist yet)
function Layouts:Targets(panelId, panel)
	if self.cyclic[panelId] then
		return UIParent, UIParent
	end
	return ns.Anchors:Resolve(panel.parent, self.frames, panelId),
		ns.Anchors:Resolve(panel.anchor.relativeTo, self.frames, panelId)
end

-- Returns true when the panel could be shown
function Layouts:Place(panelId)
	local layout = activeLayout()
	local panel = layout and layout.panels[panelId]
	local frame = self.frames[panelId]
	if not panel or not frame then return false end

	local parent, anchor = self:Targets(panelId, panel)
	if not parent or not anchor then
		self.waiting[panelId] = true
		ns.Panel:Apply(frame, panel, parent or UIParent, anchor or UIParent)
		frame:Hide()
		return false
	end
	self.waiting[panelId] = nil
	ns.Panel:Apply(frame, panel, parent, anchor)
	-- Shown unless its display conditions say otherwise
	ns.Visibility:Refresh(panelId, true)
	return true
end

function Layouts:StartScripts(panelId)
	if started[panelId] or self.waiting[panelId] then return end
	local layout = activeLayout()
	local panel = layout and layout.panels[panelId]
	if not panel then return end

	local dependency = panel.scriptDependency
	if dependency and not C_AddOns.IsAddOnLoaded(dependency) then
		waitingAddon[dependency] = waitingAddon[dependency] or {}
		waitingAddon[dependency][panelId] = true
		return
	end
	started[panelId] = true
	ns.Scripts:Attach(self.frames[panelId], panel)
end

-- Panels waiting for a frame created later (another addon, a Blizzard frame loaded on demand)
function Layouts:RetryWaiting()
	for panelId in pairs(self.waiting) do
		if self:Place(panelId) then
			self:StartScripts(panelId)
		end
	end
end

function Layouts:StartRetry()
	if ticker or not next(self.waiting) then return end
	ticker = C_Timer.NewTicker(RETRY_INTERVAL, function()
		self:RetryWaiting()
		if not next(self.waiting) and ticker then
			ticker:Cancel()
			ticker = nil
		end
	end, RETRY_COUNT)
end

function Layouts:OnAddonLoaded(addon)
	if not self.activeId then return end
	self:RetryWaiting()
	local list = waitingAddon[addon]
	if list then
		waitingAddon[addon] = nil
		for panelId in pairs(list) do
			self:StartScripts(panelId)
		end
	end
end

-- Redraws one panel (a media it needed was registered)
function Layouts:RefreshPanel(panelId)
	if self.frames[panelId] then
		self:Place(panelId)
	end
end

-- Redraws every panel (screen size or UI scale changed: % sizes)
function Layouts:RefreshAll()
	if not self.activeId then return end
	local layout = activeLayout()
	for _, panelId in ipairs((ns.Anchors:Order(layout.panels))) do
		self:Place(panelId)
	end
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
function Layouts:Activate(layoutId)
	ns.Database:SetActiveLayoutId(layoutId)
	self:ApplyActive()
end

function Layouts:SetEnabled(enabled)
	ns.db.profile.enabled = enabled and true or false
	self:ApplyActive()
end

---------------------------------------------------------------------------
-- Live editing (options window, edit mode)
---------------------------------------------------------------------------
function Layouts:RestartScripts(panelId)
	local frame = self.frames[panelId]
	if not frame then return end
	ns.Scripts:Detach(frame)
	started[panelId] = nil
	self:StartScripts(panelId)
end

--[[
A panel of the active layout was edited.
	what = "look"      background, border, text, size, position: redraw it
	what = "geometry"  only size or position: moves it (edit mode, while dragging)
	what = "display"   display conditions or opacity
	what = "anchors"   parent or anchor changed: loops may appear or disappear
	what = "scripts"   scripts changed: restart them
	what = "added"     new panel: creates its frame, the other panels keep running
	what = "removed"   panel deleted: releases its frame, re-places the others
	what = "structure" many changes: rebuild the layout
]]
function Layouts:PanelChanged(panelId, what)
	if not self.activeId then return end
	if what == "structure" then
		self:ApplyActive()
	elseif what == "scripts" then
		self:RestartScripts(panelId)
	elseif what == "geometry" then
		self:UpdateGeometry(panelId)
	elseif what == "display" then
		ns.Visibility:Refresh(panelId, false)
	elseif what == "added" then
		if not self.frames[panelId] then
			self.frames[panelId] = ns.Panel:Acquire(panelId)
		end
		self:Reanchor()
	elseif what == "removed" then
		local frame = self.frames[panelId]
		if frame then
			ns.Scripts:Detach(frame)
			ns.Panel:Release(frame)
			self.frames[panelId] = nil
		end
		self.waiting[panelId] = nil
		started[panelId] = nil
		self:Reanchor()
	elseif what == "anchors" then
		self:Reanchor()
	else
		self:RefreshPanel(panelId)
	end
end

-- Places every panel again (anchors changed, loops may appear or disappear)
function Layouts:Reanchor()
	local order, cyclic = ns.Anchors:Order(activeLayout().panels)
	self.cyclic = cyclic
	for _, id in ipairs(order) do
		if self:Place(id) then self:StartScripts(id) end
	end
	self:StartRetry()
end

-- Moves or resizes a shown panel without redrawing it
function Layouts:UpdateGeometry(panelId)
	local layout = activeLayout()
	local panel = layout and layout.panels[panelId]
	local frame = self.frames[panelId]
	if not panel or not frame or self.waiting[panelId] then return end
	local parent, anchor = self:Targets(panelId, panel)
	if parent and anchor then
		ns.Panel:ApplyGeometry(frame, panel, parent, anchor)
	end
end

function Layouts:CountShown()
	local shown, waiting = 0, 0
	for panelId in pairs(self.frames) do
		if self.waiting[panelId] then
			waiting = waiting + 1
		else
			shown = shown + 1
		end
	end
	return shown, waiting
end
