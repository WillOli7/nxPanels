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
			self:Share(kind, name, path)
		end
	end
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnMediaRegistered")
end

-- Shares a library entry with the other addons through LibSharedMedia. Only a file the
-- game knows, in its Interface folder: recent versions of LibSharedMedia report the
-- others as a Lua error. An unknown file stays usable here (Fetch reads the library)
-- and is shared after a restart. Returns true when the game knows the file.
function Media:Share(kind, name, path)
	if not self:IsKnownFile(path) then return false end
	if type(path) == "string" and not path:lower():find("^interface") then return true end
	LSM:Register(kind, name, path)
	return true
end

-- Adds an entry to the user library (saved) and shares it. Returns true when the
-- game knows the file (new files are only found after a restart).
function Media:AddToLibrary(kind, name, path)
	ns.db.global.media[kind][name] = path
	return self:Share(kind, name, path)
end

-- The game finds this file (a file id is trusted). New files are only found after a restart.
function Media:IsKnownFile(path)
	if type(path) ~= "string" then return path ~= nil end
	local isKnown = C_UIFileAsset and C_UIFileAsset.IsKnownFile
	if not isKnown then return true end
	local ok, known = pcall(isKnown, path)
	return not ok or known and true or false
end

-- Path saved in the user library, nil for other keys
function Media:LibraryPath(kind, key)
	local library = ns.db.global.media[kind]
	return library and library[key]
end

-- Removes an entry from the user library. LibSharedMedia cannot unregister a
-- media: it stays usable until the next reload.
function Media:RemoveFromLibrary(kind, name)
	ns.db.global.media[kind][name] = nil
end

-- Texture path of a background/border key; nil for "none" or unknown keys
function Media:Fetch(kind, key, panelId)
	if not key then return nil end
	local path = LSM:Fetch(kind, key, true) or self:LibraryPath(kind, key)
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
