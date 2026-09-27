local _, ns = ...

local Media = {}
ns.Media = Media

local LSM = LibStub("LibSharedMedia-3.0")
Media.LSM = LSM

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Panels waiting for a media registered later by another addon: [kind][key] = { [panelId] = true }
local waiting = { background = {}, border = {}, font = {} }

function Media:Init()
	LSM:Register("background", "Solid", WHITE)
	for kind, list in pairs(ns.db.global.media) do
		for name, path in pairs(list) do
			LSM:Register(kind, name, path)
		end
	end
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnMediaRegistered")
end

-- Adds an entry to the user library (saved) and to LibSharedMedia
function Media:AddToLibrary(kind, name, path)
	ns.db.global.media[kind][name] = path
	LSM:Register(kind, name, path)
end

-- Texture path of a background/border key; nil for "none" or unknown keys
function Media:Fetch(kind, key, panelId)
	if not key then return nil end
	local path = LSM:Fetch(kind, key, true)
	if path and path ~= "" then
		return path
	end
	if panelId then
		waiting[kind][key] = waiting[kind][key] or {}
		waiting[kind][key][panelId] = true
	end
	return nil
end

--[[
Default font of the client language. STANDARD_TEXT_FONT is set by the client
(ARKai_T on zhCN, bLEI00D on zhTW, 2002 on koKR, FRIZQT__ on western clients),
so Chinese text is always readable. Never hard-code a latin font here.
]]
function Media:DefaultFont()
	return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

-- Font path of a key: the LibSharedMedia font when it exists and supports the
-- client language, the language default font otherwise
function Media:FetchFont(key, panelId)
	if key then
		local path = LSM:Fetch("font", key, true)
		if path then
			return path
		end
		if panelId then
			waiting.font[key] = waiting.font[key] or {}
			waiting.font[key][panelId] = true
		end
	end
	return self:DefaultFont()
end

-- Another addon registered a media one of our panels was waiting for
function Media:OnMediaRegistered(_, kind, key)
	local list = waiting[kind] and waiting[kind][key]
	if not list then return end
	waiting[kind][key] = nil
	for panelId in pairs(list) do
		ns.Layouts:RefreshPanel(panelId)
	end
end

function Media:ClearWaiting()
	for _, list in pairs(waiting) do
		wipe(list)
	end
end
