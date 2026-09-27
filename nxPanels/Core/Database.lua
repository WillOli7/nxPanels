local ADDON, ns = ...

local Database = {}
ns.Database = Database

--[[
nxPanelsDB (AceDB)
	global.schema            data schema version (ns.SCHEMA)
	global.nextId            counter used to build stable ids
	global.layouts[id]       { name = "...", folders = { "name", ... }, panels = { [panelId] = panel } }
	global.media.background  user library: [name] = path
	global.media.border      user library: [name] = path
	global.migration         { source = "...", date = time() } set by an import module
	global.optionsScale      scale of the options window
	global.editMode          grid and snapping of the edit mode
	profile.layout           id of the active layout
	profile.enabled          panels shown or hidden
	profile.minimap          LibDBIcon settings
]]
local DEFAULTS = {
	global = {
		schema = ns.SCHEMA,
		nextId = 1,
		layouts = {},
		media = { background = {}, border = {} },
		optionsScale = 1,
		editMode = {
			showGrid = true,
			gridSize = 16,
			snapGrid = true,
			snapPanels = true,
			snapDistance = 8,
			bigStep = 10,
		},
	},
	profile = {
		enabled = true,
		minimap = { hide = false },
	},
}

function Database:Init()
	self.db = LibStub("AceDB-3.0"):New("nxPanelsDB", DEFAULTS, true)
	ns.db = self.db

	local LibDualSpec = LibStub("LibDualSpec-1.0", true)
	if LibDualSpec then
		pcall(LibDualSpec.EnhanceDatabase, LibDualSpec, self.db, ADDON)
	end

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

-- Future schema changes go here, one step per version
function Database:Upgrade()
	local g = self.db.global
	g.schema = g.schema or ns.SCHEMA
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

function Database:GetActiveLayoutId()
	local id = self.db.profile.layout
	if id and self.db.global.layouts[id] then
		return id
	end
end

function Database:SetActiveLayoutId(id)
	self.db.profile.layout = id
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
