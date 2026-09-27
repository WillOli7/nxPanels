-- Minimal World of Warcraft API mock, enough to load nxPanels in LuaJIT.
-- Objects record what the addon asks for, so the tests can check it.

local M = { printed = {}, addons = {}, loadCalls = {}, disabled = {}, popups = {} }

---------------------------------------------------------------------------
-- Globals of the game
---------------------------------------------------------------------------
WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_ID = 1
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
M.build = { "12.1.0", "69933", "Sep 1 2026", 120100 }
function GetBuildInfo() return unpack(M.build) end
M.locale = "frFR"
function GetLocale() return M.locale end
function GetRealmName() return "Hyjal" end
function GetCurrentRegion() return 3 end
function GetCurrentRegionName() return "EU" end
function UnitNameUnmodified() return "Muse" end
function UnitName() return "Muse" end
function UnitClass() return "Mage", "MAGE" end
function UnitRace() return "Humain", "Human" end
function UnitFactionGroup() return "Alliance" end
function time() return 1790000000 end
function strlenutf8(s) return #s end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strjoin(sep, ...) return table.concat({ ... }, sep) end
function tostringall(...) local t = { ... } for i = 1, select("#", ...) do t[i] = tostring(t[i]) end return unpack(t, 1, select("#", ...)) end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
strmatch, strsub, strlen, strbyte, strchar, format, strfind, strlower = string.match, string.sub, string.len, string.byte, string.char, string.format, string.find, string.lower
tinsert, tremove = table.insert, table.remove
function securecallfunction(f, ...) return f(...) end
function geterrorhandler() return function(e) error(e, 0) end end
function hooksecurefunc() end
function ReloadUI() M.reloaded = true end
C_UIFileAsset = { IsKnownFile = function() return true end }
C_GameRules = { IsGameRuleActive = function() return false end }
Enum = { GameRule = {} }
StaticPopupDialogs = {}
SlashCmdList = {}
function StaticPopup_Show(name) M.popups[#M.popups + 1] = name end

function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end

DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) M.printed[#M.printed + 1] = msg end }

C_Timer = {
	After = function(_, fn) M.timers = M.timers or {} table.insert(M.timers, fn) end,
	NewTicker = function(_, fn, n)
		local t = { fn = fn, n = n, cancelled = false }
		function t:Cancel() self.cancelled = true end
		M.ticker = t
		return t
	end,
}

---------------------------------------------------------------------------
-- Addons
---------------------------------------------------------------------------
-- M.addons = { { name = "...", loaded = bool, lod = bool, onLoad = function() end } }
local function findAddon(name)
	for i, a in ipairs(M.addons) do
		if a.name == name then return a, i end
	end
end
C_AddOns = {
	GetAddOnMetadata = function(_, field) if field == "Version" then return "test" end end,
	IsAddOnLoaded = function(name) local a = findAddon(name) return a and a.loaded or false end,
	GetNumAddOns = function() return #M.addons end,
	GetAddOnInfo = function(i)
		local a = type(i) == "number" and M.addons[i] or findAddon(i)
		if a then return a.name, a.name, "", true, nil end
	end,
	LoadAddOn = function(name)
		M.loadCalls[#M.loadCalls + 1] = name
		local a = findAddon(name)
		if not a then return false, "MISSING" end
		if a.disabled then return false, "DISABLED" end
		if not a.loaded then
			a.loaded = true
			if a.onLoad then a.onLoad() end
		end
		return true
	end,
	EnableAddOn = function(name) local a = findAddon(name) if a then a.disabled = false end end,
	DisableAddOn = function(name) M.disabled[name] = true end,
}

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local Region = {}
Region.__index = Region

local function newRegion(kind, parent)
	return setmetatable({ kind = kind, parent = parent, points = {}, shown = true, scripts = {}, events = {}, w = 0, h = 0, scale = 1 }, Region)
end

function Region:GetObjectType() return self.kind end
function Region:SetPoint(point, rel, relPoint, x, y)
	assert(type(point) == "string", "SetPoint: point must be a string")
	if type(rel) == "table" then
		assert(rel ~= self, "SetPoint: anchored to itself")
	end
	self.points[#self.points + 1] = { point, rel, relPoint, x, y }
end
function Region:ClearAllPoints() self.points = {} end
function Region:SetAllPoints(rel) self.points = { { "ALL", rel } } end
function Region:SetSize(w, h) assert(w and h and w >= 0 and h >= 0, "SetSize: bad size") self.w, self.h = w, h end
function Region:SetWidth(w) self.w = w end
function Region:SetHeight(h) self.h = h end
function Region:GetWidth() return self.w end
function Region:GetHeight() return self.h end
function Region:GetSize() return self.w, self.h end
function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:SetShown(v) self.shown = not not v end
function Region:IsShown() return self.shown end
function Region:GetParent() return self.parent end
function Region:SetParent(p) assert(type(p) == "table", "SetParent: nil parent") self.parent = p end
function Region:SetAlpha(a) self.alpha = a end

-- Textures
function Region:SetTexture(path, wrapH, wrapV) self.texture, self.wrapH, self.wrapV = path, wrapH, wrapV end
function Region:SetTexCoord(...)
	local n = select("#", ...)
	assert(n == 4 or n == 8, "SetTexCoord: 4 or 8 numbers expected, got " .. n)
	for i = 1, n do assert(type(select(i, ...)) == "number", "SetTexCoord: number expected") end
	self.texCoord = { ... }
end
function Region:SetVertexColor(r, g, b, a) self.vertexColor = { r, g, b, a } self.gradient = nil end
function Region:SetGradient(orientation, c1, c2)
	assert(orientation == "HORIZONTAL" or orientation == "VERTICAL", "SetGradient: orientation")
	assert(type(c1) == "table" and type(c2) == "table", "SetGradient: colors must be ColorMixin")
	self.gradient = { orientation, c1, c2 }
end
function Region:SetDrawLayer(layer, sub) assert(sub >= -8 and sub <= 7, "sublevel out of range") self.layer, self.subLevel = layer, sub end
function Region:SetBlendMode(mode) self.blend = mode end
function Region:SetHorizTile(v) self.hTile = v end
function Region:SetVertTile(v) self.vTile = v end

-- Font strings
function Region:SetFont(path, size, flags) self.font = { path, size, flags } return true end
function Region:SetJustifyH(v) self.justifyH = v end
function Region:SetJustifyV(v) self.justifyV = v end
function Region:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a } end
function Region:SetText(t) self.textValue = t end
function Region:SetFontObject() end

-- Frames
function Region:SetScript(name, fn)
	self.scripts[name] = fn
	if name == "OnSizeChanged" then end
end
function Region:GetScript(name) return self.scripts[name] end
function Region:RegisterEvent(e) self.events[e] = true end
function Region:UnregisterAllEvents() self.events = {} end
function Region:CreateTexture() local t = newRegion("Texture", self) return t end
function Region:CreateFontString() local t = newRegion("FontString", self) return t end
function Region:SetScale(s) self.scale = s end
function Region:GetScale() return self.scale end
function Region:SetFrameStrata(s) self.strata = s end
function Region:SetFrameLevel(l) assert(l >= 0, "negative frame level") self.level = l end
function Region:EnableMouse(v) self.mouse = v end
function Region:IsForbidden() return false end

M.frames = {}
function CreateFrame(kind, name, parent)
	local f = newRegion(kind, parent)
	M.frames[#M.frames + 1] = f
	if name then _G[name] = f end
	return f
end
UIParent = newRegion("Frame")
UIParent.w, UIParent.h = 1920, 1080

-- Fires an event on every frame registered for it
function M.Fire(event, ...)
	for _, f in ipairs(M.frames) do
		if f.events[event] and f.scripts.OnEvent then
			f.scripts.OnEvent(f, event, ...)
		end
	end
end

return M
