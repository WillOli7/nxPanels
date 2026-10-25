local _, ns = ...
local L = ns.L

--[[
Layout export / import.
nxPanels strings: "!NXP1!" + LibSerialize + LibDeflate (printable text).
Other formats can be added by other modules with Share:RegisterDecoder.

A decoded string is described by:
	{ format = "display name", name = "suggested layout name", count = panels,
	  scripted = { names of the panels that contain scripts },
	  import = function(layoutName) -> new layout id,
	  kind = "layout" | "panels" (some panels, to add to a layout),
	  addTo = function(layoutId) -> new panel ids (optional) }
]]
local Share = {}
ns.Share = Share

local PREFIX = "!NXP1!"
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

local decoders = {}

function Share:RegisterDecoder(decoder)
	decoders[#decoders + 1] = decoder
end

-- Custom art used by a layout, so the receiver gets the paths too
local function usedMedia(layout)
	local media = { background = {}, border = {} }
	local library = ns.db.global.media
	for _, panel in pairs(layout.panels) do
		local bg, border = panel.background.texture, panel.border.texture
		if bg and library.background[bg] then media.background[bg] = library.background[bg] end
		if border and library.border[border] then media.border[border] = library.border[border] end
	end
	return media
end

function Share:Export(layoutId)
	local layout = ns.Database:GetLayout(layoutId)
	if not layout then return end
	local payload = {
		kind = "layout",
		schema = ns.SCHEMA,
		addonVersion = ns.version,
		layout = layout,
		media = usedMedia(layout),
	}
	local compressed = LibDeflate:CompressDeflate(LibSerialize:Serialize(payload), { level = 9 })
	return PREFIX .. LibDeflate:EncodeForPrint(compressed)
end

local function hasScript(panel)
	for _, code in pairs(type(panel.scripts) == "table" and panel.scripts or {}) do
		if type(code) == "string" and code:find("%S") then return true end
	end
	return false
end

--[[
Adds the panels of a payload to a layout, with new ids. References between
these panels are kept; references to panels that are not in the payload go
to the screen. Names are made unique in the layout. Returns the new ids.
]]
local function addPanels(layoutId, layout, payload)
	for _, folder in ipairs(payload.layout.folders or {}) do
		ns.Database:AddFolder(layoutId, folder)
	end
	local map, ids = {}, {}
	for panelId in pairs(payload.layout.panels) do
		map[panelId] = ns.Database:NewId("P")
	end
	local function remap(ref)
		local old = type(ref) == "string" and ref:match("^panel:(.+)$")
		if old then return map[old] and ("panel:" .. map[old]) or "UIParent" end
		return ref
	end
	for panelId, panel in pairs(payload.layout.panels) do
		local p = ns.FillDefaults(ns.DeepCopy(panel), ns.PanelDefaults)
		p.parent = remap(p.parent)
		p.anchor.relativeTo = remap(p.anchor.relativeTo)
		p.name = ns.Database:UniquePanelName(layout, tostring(p.name))
		layout.panels[map[panelId]] = p
		ids[#ids + 1] = map[panelId]
	end
	local library = ns.db.global.media
	for kind, list in pairs(type(payload.media) == "table" and payload.media or {}) do
		for mediaName, path in pairs(list) do
			if library[kind] and not library[kind][mediaName] then
				ns.Media:AddToLibrary(kind, mediaName, path)
			end
		end
	end
	return ids
end

-- Creates a layout from an nxPanels payload
local function importPayload(payload, name)
	local id, layout = ns.Database:CreateLayout(name)
	addPanels(id, layout, payload)
	return id
end

-- Adds the panels of a payload to an existing layout; returns the new panel ids
local function addToLayout(payload, layoutId)
	local layout = ns.Database:GetLayout(layoutId)
	if not layout then return {} end
	return addPanels(layoutId, layout, payload)
end
Share.AddPanels = addToLayout

-- Some panels of a layout (a panel, a folder...): pasted into another layout
function Share:ExportPanels(layoutId, panelIds)
	local layout = ns.Database:GetLayout(layoutId)
	if not layout then return end
	local subset, seen = { name = layout.name, folders = {}, panels = {} }, {}
	for _, panelId in ipairs(panelIds) do
		local panel = layout.panels[panelId]
		if panel then
			subset.panels[panelId] = panel
			if panel.folder and not seen[panel.folder] then
				seen[panel.folder] = true
				subset.folders[#subset.folders + 1] = panel.folder
			end
		end
	end
	table.sort(subset.folders)
	local payload = {
		kind = "panels",
		schema = ns.SCHEMA,
		addonVersion = ns.version,
		layout = subset,
		media = usedMedia(subset),
	}
	local compressed = LibDeflate:CompressDeflate(LibSerialize:Serialize(payload), { level = 9 })
	return PREFIX .. LibDeflate:EncodeForPrint(compressed)
end

--[[
A string can be damaged or forged: values of the wrong type are dropped (the
defaults replace them) before anything uses them. Tables must stay tables, numbers
numbers (a number in a string is kept), texts texts; false stays allowed for
"no texture". Values without a default (folder, font...) are checked by cleanPayload.
]]
local function cleanValues(target, defaults)
	for key, default in pairs(defaults) do
		local value = target[key]
		if value ~= nil then
			if type(default) == "table" then
				if type(value) ~= "table" then
					target[key] = nil
				elseif next(default) then
					cleanValues(value, default)
				end
			elseif type(default) == "number" then
				target[key] = tonumber(value)
			elseif type(value) ~= type(default) and not (key == "texture" and value == false) then
				target[key] = nil
			end
		end
	end
end

local function cleanPayload(payload)
	local layout = payload.layout
	local panels = {}
	for id, panel in pairs(layout.panels) do
		if type(id) == "string" and type(panel) == "table" then
			if type(panel.name) == "number" then panel.name = tostring(panel.name) end
			cleanValues(panel, ns.PanelDefaults)
			panel.name = panel.name or id
			if type(panel.folder) ~= "string" then panel.folder = nil end
			if type(panel.scriptDependency) ~= "string" then panel.scriptDependency = nil end
			local scripts = {}
			for hook, code in pairs(type(panel.scripts) == "table" and panel.scripts or {}) do
				if type(hook) == "string" and type(code) == "string" then scripts[hook] = code end
			end
			panel.scripts = scripts
			if type(panel.text) == "table" and type(panel.text.font) ~= "string" then panel.text.font = nil end
			local bg = panel.background
			if type(bg) == "table" and bg.texCoord ~= nil then
				local c = bg.texCoord
				local valid = type(c) == "table" and #c == 8
				for i = 1, 8 do valid = valid and type(c[i]) == "number" end
				if not valid then bg.texCoord = nil end
			end
			panels[id] = panel
		end
	end
	layout.panels = panels
	local folders = {}
	for _, folder in ipairs(type(layout.folders) == "table" and layout.folders or {}) do
		if type(folder) == "string" then folders[#folders + 1] = folder end
	end
	layout.folders = folders
	if type(layout.name) ~= "string" then layout.name = nil end
	local media = {}
	for kind, list in pairs(type(payload.media) == "table" and payload.media or {}) do
		if type(kind) == "string" and type(list) == "table" then
			media[kind] = {}
			for name, path in pairs(list) do
				if type(name) == "string" and (type(path) == "string" or type(path) == "number") then
					media[kind][name] = path
				end
			end
		end
	end
	payload.media = media
end

local function decodeNative(text)
	if text:sub(1, #PREFIX) ~= PREFIX then return end
	local decoded = LibDeflate:DecodeForPrint(text:sub(#PREFIX + 1))
	local raw = decoded and LibDeflate:DecompressDeflate(decoded)
	if not raw then return false, L["IMPORT_INVALID"] end
	local ok, payload = LibSerialize:Deserialize(raw)
	if not ok or type(payload) ~= "table" or type(payload.layout) ~= "table" or type(payload.layout.panels) ~= "table" then
		return false, L["IMPORT_INVALID"]
	end
	if (tonumber(payload.schema) or 1) > ns.SCHEMA then
		return false, L["IMPORT_NEWER"]
	end
	cleanPayload(payload)
	local count, scripted = 0, {}
	for _, panel in pairs(payload.layout.panels) do
		count = count + 1
		if type(panel) == "table" and hasScript(panel) then scripted[#scripted + 1] = tostring(panel.name) end
	end
	table.sort(scripted)
	return {
		format = "nxPanels",
		name = payload.layout.name,
		count = count,
		scripted = scripted,
		kind = payload.kind == "panels" and "panels" or "layout",
		import = function(name) return importPayload(payload, name) end,
		addTo = function(layoutId) return addToLayout(payload, layoutId) end,
	}
end

-- Returns the description of a string, or nil and an error message
function Share:Decode(text)
	text = text and strtrim(text) or ""
	if text == "" then return nil, L["IMPORT_EMPTY"] end
	local decoded, err = decodeNative(text)
	if decoded then return decoded end
	if decoded == false then return nil, err end
	for _, decoder in ipairs(decoders) do
		decoded = decoder(text)
		if decoded then return decoded end
	end
	return nil, L["IMPORT_INVALID"]
end

-- Imports a decoded string as a new layout; returns its id
function Share:Import(decoded, name)
	name = name and strtrim(name) or ""
	if name == "" then name = decoded.name or L["IMPORTED_LAYOUT"] end
	return decoded.import(name)
end
