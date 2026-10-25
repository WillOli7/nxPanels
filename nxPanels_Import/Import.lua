local ADDON, I = ...
local ns = nxPanels.__ns
local L = ns.L

--[[
Imports the data of kgPanels and kgPanels Reloaded (global "kgPanelsDB").

An addon can only read its own SavedVariables file. The package therefore ships a
small load-on-demand addon named "kgPanels_Reloaded" (the bridge) which only
declares kgPanelsDB: loading it gives access to the old file of kgPanels Reloaded.
The original kgPanels, when installed, loads its data itself.
Both use the same global name, so the bridge is never loaded next to kgPanels
(one file would overwrite the other when logging out).

The legacy data is never modified. This module is temporary: it can be removed
once players have moved to nxPanels, the core does not depend on it.
]]
local Import = {}
I.Import = Import

local ORIGINAL = "kgPanels"
local RELOADED = "kgPanels_Reloaded"
local LEGACY_ADDONS = { ORIGINAL, RELOADED, "kgPanelsConfig_Reloaded" }

local function isLoaded(name)
	return C_AddOns.IsAddOnLoaded(name)
end

local function exists(name)
	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.GetAddOnInfo(i) == name then
			return true
		end
	end
	return false
end

-- Returns the legacy table and the name of its addon
function Import:GetLegacyData()
	---@diagnostic disable-next-line: undefined-field -- SavedVariables of the old addon
	if isLoaded(ORIGINAL) and type(_G.kgPanelsDB) == "table" then
		return _G.kgPanelsDB, ORIGINAL
	end
	if exists(RELOADED) then
		if not isLoaded(RELOADED) then
			local loaded, reason = C_AddOns.LoadAddOn(RELOADED)
			if not loaded and reason == "DISABLED" then
				C_AddOns.EnableAddOn(RELOADED)
				C_AddOns.LoadAddOn(RELOADED)
			end
		end
		if type(_G.kgPanelsDB) == "table" then
			return _G.kgPanelsDB, RELOADED
		end
	end
end

-- The original kgPanels is installed but the game did not load it (made for another
-- client, like BCC Anniversary on WoW Forever, or disabled): its data cannot be read.
-- Returns the reason shown to the player, or nil.
function Import:LegacyNotLoaded()
	if isLoaded(ORIGINAL) or not exists(ORIGINAL) then return end
	local _, _, _, _, reason = C_AddOns.GetAddOnInfo(ORIGINAL)
	reason = tostring(reason or "NOT_LOADED")
	return _G["ADDON_" .. reason] or reason
end

-- Adds the legacy layouts to nxPanels; returns layouts, panels, old name -> id
local function importLayouts(legacyGlobal)
	local g = ns.db.global
	local layouts, panels, ids = I.Convert.Layouts(ns.DeepCopy(legacyGlobal), g)
	for _, layout in pairs(g.layouts) do
		ns.Database:NormalizeLayout(layout)
	end
	for kind, list in pairs(g.media) do
		for name, path in pairs(list) do
			ns.Media:Share(kind, name, path)
		end
	end
	return layouts, panels, ids
end

---------------------------------------------------------------------------
-- Automatic import, on the first start of nxPanels
---------------------------------------------------------------------------
function Import:Auto()
	if not ns.db then return end
	local g = ns.db.global
	if g.migration or next(g.layouts) then return end
	-- The old addon itself is running (original kgPanels, or kgPanels Reloaded installed
	-- by hand next to nxPanels): its panels stay on screen until a reload
	local legacyRunning = isLoaded(ORIGINAL) or isLoaded(RELOADED)

	local legacy, source = self:GetLegacyData()
	if type(legacy) ~= "table" or type(legacy.global) ~= "table" then
		-- Explained after login, when the chat is ready
		self.notLoaded = self:LegacyNotLoaded()
		return
	end
	legacy = ns.DeepCopy(legacy)

	local layoutCount, panelCount, ids = importLayouts(legacy.global)
	local sv = ns.db.sv

	-- Profiles keep their name, their characters and their active layout
	if type(legacy.profiles) == "table" then
		for name, profile in pairs(legacy.profiles) do
			if type(profile) == "table" then
				local target = sv.profiles[name] or {}
				sv.profiles[name] = target
				target.layout = ids[profile.layout]
				target.enabled = profile.enabled ~= false
			end
		end
	end
	if type(legacy.profileKeys) == "table" then
		for char, name in pairs(legacy.profileKeys) do
			if type(name) == "string" then sv.profileKeys[char] = name end
		end
		local current = legacy.profileKeys[ns.db.keys.char]
		if current and current ~= ns.db:GetCurrentProfile() then
			ns.db:SetProfile(current)
		end
	end
	-- Profiles per specialization (LibDualSpec) become layouts per specialization.
	-- Only for this character: the specializations of the others are unknown here.
	local dualSpec = type(legacy.namespaces) == "table" and legacy.namespaces["LibDualSpec-1.0"]
	local mine = type(dualSpec) == "table" and type(dualSpec.char) == "table" and dualSpec.char[ns.db.keys.char]
	if type(mine) == "table" and mine.enabled and type(legacy.profiles) == "table" then
		for i, spec in ipairs(ns.Specs:List()) do
			local profile = legacy.profiles[mine[i]]
			local layoutId = type(profile) == "table" and ids[profile.layout]
			if layoutId then ns.db.profile.specLayouts[spec.key] = layoutId end
		end
	end

	g.migration = { source = source, date = time(), layouts = layoutCount, panels = panelCount }
	self.done = g.migration
	self.needReload = legacyRunning
end

---------------------------------------------------------------------------
-- Repair of the imports made by 1.0.0: a panel named like the game frame it follows
-- ("Minimap" anchored to "Minimap") was anchored to itself. Back to the frame name.
---------------------------------------------------------------------------
function Import:RepairSelfReferences()
	if not ns.db or not ns.db.global.migration then return 0 end
	local repaired = 0
	for _, layout in pairs(ns.db.global.layouts) do
		for id, panel in pairs(layout.panels) do
			local own = "panel:" .. id
			if panel.parent == own then
				panel.parent = panel.name
				repaired = repaired + 1
			end
			if type(panel.anchor) == "table" and panel.anchor.relativeTo == own then
				panel.anchor.relativeTo = panel.name
				repaired = repaired + 1
			end
		end
	end
	return repaired
end

---------------------------------------------------------------------------
-- Welcome window, shown once after an import (also to players who imported before it existed)
---------------------------------------------------------------------------
function Import:Welcome()
	-- No database when a library is missing
	if not ns.db then return end
	local done = ns.db.global.migration
	if type(done) ~= "table" or done.welcomed then return end
	local f = self.welcomeFrame or ns.Splash:Create("nxPanelsWelcome", 520, 400)
	self.welcomeFrame = f
	f.title:SetText(L["WELCOME_TITLE"]:format(done.source == ORIGINAL and "kgPanels" or "kgPanels Reloaded"))
	local body = L["WELCOME_BODY"]
	-- No count when the old addon had no layout
	if (tonumber(done.layouts) or 0) > 0 then
		body = L["WELCOME_COUNT"]:format(done.layouts, tonumber(done.panels) or 0) .. "\n" .. body
	end
	f.body:SetText(body)
	f:Show()
	-- Recorded once shown: an error above leaves the welcome for the next login
	done.welcomed = true
end

-- After login: report, switch the legacy addons off, then welcome (after the reload if one is needed)
function Import:Finish()
	local done = self.done
	if not done then
		if self.notLoaded then
			ns:Print(L["LEGACY_NOT_LOADED"], self.notLoaded)
			self.notLoaded = nil
		end
		self:Welcome()
		return
	end
	self.done = nil
	ns:Print(L["MIGRATED"], done.layouts, done.panels, done.source)

	local needReload = self.needReload
	for _, name in ipairs(LEGACY_ADDONS) do
		if exists(name) then C_AddOns.DisableAddOn(name) end
	end
	if needReload then
		StaticPopupDialogs["NXPANELS_MIGRATED"] = {
			text = L["MIGRATE_POPUP"],
			button1 = L["RELOAD"],
			button2 = L["LATER"],
			OnAccept = function() ReloadUI() end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("NXPANELS_MIGRATED")
	else
		self:Welcome()
	end
end

---------------------------------------------------------------------------
-- /nxp import: adds the legacy layouts again, as new layouts
---------------------------------------------------------------------------
function Import:Again()
	local legacy, source = self:GetLegacyData()
	if type(legacy) ~= "table" or type(legacy.global) ~= "table" then
		local reason = self:LegacyNotLoaded()
		if reason then
			ns:Print(L["LEGACY_NOT_LOADED"], reason)
		else
			ns:Print(L["MIGRATE_NOTHING"])
		end
		return
	end
	local layouts, panels = importLayouts(legacy.global)
	ns:Print(L["MIGRATED"], layouts, panels, source)
end

---------------------------------------------------------------------------
-- Old export strings (AceSerializer), in the import window of nxPanels
---------------------------------------------------------------------------
local AceSerializer = LibStub("AceSerializer-3.0")

local function decodeLegacyString(text)
	local ok, layout = AceSerializer:Deserialize(text)
	if not ok or type(layout) ~= "table" then return end
	local count, scripted = 0, {}
	for name, panel in pairs(layout) do
		count = count + 1
		for _, code in pairs(type(panel) == "table" and type(panel.scripts) == "table" and panel.scripts or {}) do
			if type(code) == "string" and code:find("%S") then
				scripted[#scripted + 1] = tostring(name)
				break
			end
		end
	end
	table.sort(scripted)
	return {
		format = L["FORMAT_LEGACY"],
		count = count,
		scripted = scripted,
		import = function(name)
			local before = {}
			for id in pairs(ns.db.global.layouts) do before[id] = true end
			importLayouts({ layouts = { [name] = layout } })
			for id in pairs(ns.db.global.layouts) do
				if not before[id] then return id end
			end
		end,
	}
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
ns:RegisterEvent("ADDON_LOADED", function(_, name)
	if name ~= ADDON or not ns.libsOK then return end
	Import:Auto()
	Import:RepairSelfReferences()
	ns.Commands:Register("import", L["HELP_IMPORT"], function() Import:Again() end)
	ns.Share:RegisterDecoder(decodeLegacyString)
end)

ns:RegisterEvent("PLAYER_LOGIN", function()
	Import:Finish()
end)
