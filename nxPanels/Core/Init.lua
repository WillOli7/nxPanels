-- nxPanels - Copyright (C) 2026 Adna
-- Licensed under the GNU General Public License v3.0 or later. See LICENSE.

local ADDON, ns = ...

ns.name = ADDON
ns.version = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "dev"

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON)
ns.L = L

---------------------------------------------------------------------------
-- Client detection
-- WoW Forever reports WOW_PROJECT_MAINLINE with a 1.x build (interface 16xxx).
---------------------------------------------------------------------------
local tocVersion = select(4, GetBuildInfo())
ns.isMainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.isForever = ns.isMainline and tocVersion >= 16000 and tocVersion < 20000
ns.isRetail = ns.isMainline and tocVersion >= 100000

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------
local PREFIX = "|cff33ccffnxPanels|r: "

function ns:Print(msg, ...)
	if select("#", ...) > 0 then
		msg = msg:format(...)
	end
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

---------------------------------------------------------------------------
-- Required libraries: fail with a readable message instead of a Lua error
---------------------------------------------------------------------------
local REQUIRED_LIBS = {
	"CallbackHandler-1.0", "AceDB-3.0", "AceLocale-3.0", "AceSerializer-3.0",
	"LibSharedMedia-3.0", "LibSerialize", "LibDeflate", "LibDataBroker-1.1", "LibDBIcon-1.0",
}

ns.libsOK = true
for _, lib in ipairs(REQUIRED_LIBS) do
	if not LibStub(lib, true) then
		ns.libsOK = false
		C_Timer.After(5, function() ns:Print(L["LIB_MISSING"], lib) end)
	end
end

---------------------------------------------------------------------------
-- Events: several modules can listen to the same event
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if not list then return end
	for i = 1, #list do
		list[i](event, ...)
	end
end)

function ns:RegisterEvent(event, func)
	if not handlers[event] then
		handlers[event] = {}
		-- Unknown events raise an error on trimmed clients (WoW Forever)
		if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
			handlers[event] = nil
			return false
		end
	end
	table.insert(handlers[event], func)
	return true
end

---------------------------------------------------------------------------
-- Small helpers shared by the modules
---------------------------------------------------------------------------
function ns.DeepCopy(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = ns.DeepCopy(v)
	end
	return copy
end

-- Fill missing keys of `target` from `defaults`, recursively
function ns.FillDefaults(target, defaults)
	for k, v in pairs(defaults) do
		if target[k] == nil then
			target[k] = ns.DeepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" then
			ns.FillDefaults(target[k], v)
		end
	end
	return target
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
ns:RegisterEvent("ADDON_LOADED", function(_, name)
	if name ~= ADDON or not ns.libsOK then return end
	ns.Database:Init()
	ns.Media:Init()
	ns.Layouts:Init()
	ns.Commands:Init()
end)

ns:RegisterEvent("PLAYER_LOGIN", function()
	if not ns.libsOK then return end
	ns.Layouts:ApplyActive()
end)
