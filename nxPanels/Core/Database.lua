local _, ns = ...

local Database = {}
ns.Database = Database

--[[
nxPanelsDB (AceDB)
	global.schema            data schema version (ns.SCHEMA), not in the defaults so it is always saved
	global.nextId            counter used to build stable ids
	global.layouts[id]       { name = "...", folders = { "name", ... }, panels = { [panelId] = panel } }
	global.media.background  user library: [name] = path
	global.media.border      user library: [name] = path
	global.migration         { source = "...", date = time() } set by an import module
	global.optionsScale      scale of the options window
	global.optionsTheme      look of the options window: { style = "...", accent = "..." }
	global.editMode          grid and snapping of the edit mode
	global.newCharacters     profile of the characters that have none yet: "default", "class", "faction"
	profile.layout           id of the default layout of the profile
	profile.specLayouts      [spec key] = layout id, replaces the default layout for that spec (see Specs)
	profile.enabled          panels shown or hidden
	profile.minimap          LibDBIcon settings
]]
local DEFAULTS = {
	global = {
		nextId = 1,
		layouts = {},
		media = { background = {}, border = {} },
		optionsScale = 1,
		optionsTheme = { style = "atelier", accent = "gold" },
		editMode = {
			showGrid = true,
			gridSize = 16,
			snapGrid = false,
			snapPanels = true,
			snapDistance = 8,
			bigStep = 10,
		},
		newCharacters = "default",
	},
	profile = {
		enabled = true,
		minimap = { hide = false },
		specLayouts = {},
	},
}

-- Profile given to a character that has none yet (read before AceDB starts)
local function newCharacterProfile()
	local sv = _G.nxPanelsDB
	local choice = type(sv) == "table" and type(sv.global) == "table" and sv.global.newCharacters
	if choice == "class" then
		return (UnitClass("player")) or true
	elseif choice == "faction" then
		return select(2, UnitFactionGroup("player")) or true
	end
	return true
end

function Database:Init()
	self.db = LibStub("AceDB-3.0"):New("nxPanelsDB", DEFAULTS, newCharacterProfile())
	ns.db = self.db

	local function onProfile()
		ns.Layouts:ApplyActive()
	end
	self.db.RegisterCallback(self, "OnProfileChanged", onProfile)
	self.db.RegisterCallback(self, "OnProfileCopied", onProfile)
	self.db.RegisterCallback(self, "OnProfileReset", onProfile)

	self:Upgrade()
	for _, layout in pairs(self.db.global.layouts) do
		self:NormalizeLayout(layout)
	end
end

-- One step per schema version. A missing schema is version 1 (it used to be a
-- default value, so AceDB did not save it).
function Database:Upgrade()
	local g = self.db.global
	local from = g.schema or 1
	if from < 2 then
		-- Profiles per specialization (LibDualSpec) replaced by layouts per specialization
		local namespaces = self.db.sv.namespaces
		if namespaces then namespaces["LibDualSpec-1.0"] = nil end
	end
	-- 3: display conditions and color modes, added to every panel by NormalizeLayout
	g.schema = ns.SCHEMA
end

function Database:NormalizeLayout(layout)
	layout.panels = layout.panels or {}
	layout.folders = layout.folders or {}
	for _, panel in pairs(layout.panels) do
		ns.FillDefaults(panel, ns.PanelDefaults)
	end
end

function Database:NewId(prefix)
	local g = self.db.global
	local id = g.nextId
	g.nextId = id + 1
	return prefix .. id
end

---------------------------------------------------------------------------
-- Layouts
---------------------------------------------------------------------------
function Database:GetLayout(id)
	return id and self.db.global.layouts[id]
end

-- Accepts an id or a name (case-insensitive)
function Database:FindLayout(key)
	if not key then return end
	local layouts = self.db.global.layouts
	if layouts[key] then
		return key, layouts[key]
	end
	local lower = key:lower()
	for id, layout in pairs(layouts) do
		if layout.name:lower() == lower then
			return id, layout
		end
	end
end

function Database:UniqueLayoutName(name)
	local candidate, n = name, 1
	while self:FindLayout(candidate) do
		n = n + 1
		candidate = ("%s (%d)"):format(name, n)
	end
	return candidate
end

function Database:CreateLayout(name)
	local id = self:NewId("L")
	self.db.global.layouts[id] = { name = self:UniqueLayoutName(name), folders = {}, panels = {} }
	return id, self.db.global.layouts[id]
end

-- Sorted list of { id = ..., layout = ... }
function Database:SortedLayouts()
	local list = {}
	for id, layout in pairs(self.db.global.layouts) do
		list[#list + 1] = { id = id, layout = layout }
	end
	table.sort(list, function(a, b) return a.layout.name:lower() < b.layout.name:lower() end)
	return list
end

function Database:CountPanels(layout)
	local n = 0
	for _ in pairs(layout.panels) do n = n + 1 end
	return n
end

-- Layout to show: the one of the current specialization, else the profile default
function Database:GetActiveLayoutId()
	local layouts, profile = self.db.global.layouts, self.db.profile
	local spec = ns.Specs:Current()
	local id = spec and profile.specLayouts[spec]
	if id and layouts[id] then
		return id
	end
	id = profile.layout
	if id and layouts[id] then
		return id
	end
end

-- Activating a layout by hand: replaces the layout of the current specialization
-- when it has one, the default layout of the profile otherwise
function Database:SetActiveLayoutId(id)
	local spec = ns.Specs:Current()
	local profile = self.db.profile
	if spec and profile.specLayouts[spec] and id then
		profile.specLayouts[spec] = id
	else
		profile.layout = id
	end
end

function Database:GetDefaultLayoutId()
	local id = self.db.profile.layout
	return id and self.db.global.layouts[id] and id or nil
end

function Database:SetDefaultLayoutId(id)
	self.db.profile.layout = id
end

-- nil: the specialization uses the default layout of the profile
function Database:GetSpecLayoutId(spec)
	local id = self.db.profile.specLayouts[spec]
	return id and self.db.global.layouts[id] and id or nil
end

function Database:SetSpecLayoutId(spec, id)
	self.db.profile.specLayouts[spec] = id
end

function Database:RenameLayout(id, name)
	local layout = self:GetLayout(id)
	name = name and strtrim(name)
	if not layout or not name or name == "" or name == layout.name then return end
	layout.name = self:UniqueLayoutName(name)
	return layout.name
end

-- Copies a layout; references between its panels point to the new copies
function Database:DuplicateLayout(id)
	local source = self:GetLayout(id)
	if not source then return end
	local newId, copy = self:CreateLayout(source.name)
	copy.folders = ns.DeepCopy(source.folders)
	local map = {}
	for panelId in pairs(source.panels) do
		map[panelId] = self:NewId("P")
	end
	local function remap(ref)
		local old = type(ref) == "string" and ref:match("^panel:(.+)$")
		return old and map[old] and ("panel:" .. map[old]) or ref
	end
	for panelId, panel in pairs(source.panels) do
		local p = ns.DeepCopy(panel)
		p.parent = remap(p.parent)
		p.anchor.relativeTo = remap(p.anchor.relativeTo)
		copy.panels[map[panelId]] = p
	end
	return newId, copy
end

-- Deletes a layout; profiles that used it get no active layout
function Database:DeleteLayout(id)
	if not self.db.global.layouts[id] then return end
	self.db.global.layouts[id] = nil
	for _, profile in pairs(self.db.profiles) do
		if profile.layout == id then profile.layout = nil end
		for spec, layoutId in pairs(type(profile.specLayouts) == "table" and profile.specLayouts or {}) do
			if layoutId == id then profile.specLayouts[spec] = nil end
		end
	end
end

---------------------------------------------------------------------------
-- Panels
---------------------------------------------------------------------------
function Database:UniquePanelName(layout, name, exceptId)
	local used = {}
	for id, panel in pairs(layout.panels) do
		if id ~= exceptId then used[panel.name:lower()] = true end
	end
	local candidate, n = name, 1
	while used[candidate:lower()] do
		n = n + 1
		candidate = ("%s (%d)"):format(name, n)
	end
	return candidate
end

function Database:CreatePanel(layoutId, name, folder)
	local layout = self:GetLayout(layoutId)
	if not layout then return end
	local id = self:NewId("P")
	local panel = ns.FillDefaults({}, ns.PanelDefaults)
	panel.name = self:UniquePanelName(layout, name)
	panel.folder = folder
	layout.panels[id] = panel
	return id, panel
end

function Database:DuplicatePanel(layoutId, panelId)
	local layout = self:GetLayout(layoutId)
	local source = layout and layout.panels[panelId]
	if not source then return end
	local id = self:NewId("P")
	local panel = ns.DeepCopy(source)
	panel.name = self:UniquePanelName(layout, source.name)
	panel.anchor.x = panel.anchor.x + 20
	panel.anchor.y = panel.anchor.y - 20
	layout.panels[id] = panel
	return id, panel
end

-- Deletes a panel; panels attached to it are attached to the screen
function Database:DeletePanel(layoutId, panelId)
	local layout = self:GetLayout(layoutId)
	if not layout or not layout.panels[panelId] then return end
	layout.panels[panelId] = nil
	local ref = "panel:" .. panelId
	for _, panel in pairs(layout.panels) do
		if panel.parent == ref then panel.parent = "UIParent" end
		if panel.anchor.relativeTo == ref then panel.anchor.relativeTo = "UIParent" end
	end
end

function Database:RenamePanel(layoutId, panelId, name)
	local layout = self:GetLayout(layoutId)
	local panel = layout and layout.panels[panelId]
	name = name and strtrim(name)
	if not panel or not name or name == "" then return end
	panel.name = self:UniquePanelName(layout, name, panelId)
	return panel.name
end

---------------------------------------------------------------------------
-- Folders (organization only, no effect on the display)
---------------------------------------------------------------------------
function Database:AddFolder(layoutId, name)
	local layout = self:GetLayout(layoutId)
	name = name and strtrim(name)
	if not layout or not name or name == "" then return end
	for _, folder in ipairs(layout.folders) do
		if folder == name then return name end
	end
	table.insert(layout.folders, name)
	table.sort(layout.folders, function(a, b) return a:lower() < b:lower() end)
	return name
end

function Database:RenameFolder(layoutId, old, new)
	local layout = self:GetLayout(layoutId)
	new = new and strtrim(new)
	if not layout or not new or new == "" or old == new then return end
	for i, folder in ipairs(layout.folders) do
		if folder == old then table.remove(layout.folders, i) break end
	end
	for _, panel in pairs(layout.panels) do
		if panel.folder == old then panel.folder = new end
	end
	return self:AddFolder(layoutId, new)
end

-- Deletes a folder; its panels go back to the root
function Database:DeleteFolder(layoutId, name)
	local layout = self:GetLayout(layoutId)
	if not layout then return end
	for i, folder in ipairs(layout.folders) do
		if folder == name then table.remove(layout.folders, i) break end
	end
	for _, panel in pairs(layout.panels) do
		if panel.folder == name then panel.folder = nil end
	end
end

-- Panel lookup by id or by name inside a layout
function Database:FindPanel(layout, key)
	if not layout or not key then return end
	if layout.panels[key] then
		return key, layout.panels[key]
	end
	for id, panel in pairs(layout.panels) do
		if panel.name == key then
			return id, panel
		end
	end
end
