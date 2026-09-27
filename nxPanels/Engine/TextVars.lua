local _, ns = ...
local L = ns.L

--[[
Variables in the text of a panel, replaced without any script:
	{player} {realm} {class} {spec} {level} {guild} {ilvl}
	{zone} {subzone} {time} {date} {fps} {latency} {gold}
	{currency:<id>} {item:<id>}   amount with its icon
Unknown words between braces are left as they are. Texts using variables are
refreshed every second while they are shown.
]]
local TextVars = {}
ns.TextVars = TextVars

local VARS = {
	player = function() return UnitName("player") end,
	realm = function() return GetRealmName() end,
	class = function() return (UnitClass("player")) end,
	spec = function() return ns.Specs:CurrentName() end,
	level = function() return UnitLevel("player") end,
	guild = function() return GetGuildInfo("player") end,
	ilvl = function()
		if not GetAverageItemLevel then return end
		local _, equipped = GetAverageItemLevel()
		return equipped and math.floor(equipped)
	end,
	zone = function() return GetRealZoneText and GetRealZoneText() or GetZoneText() end,
	subzone = function() return GetSubZoneText() end,
	time = function() return date(L["TIME_FORMAT"]) end,
	date = function() return date(L["DATE_FORMAT"]) end,
	fps = function() return math.floor(GetFramerate() + 0.5) end,
	latency = function()
		local _, _, home, world = GetNetStats()
		return world or home
	end,
	gold = function()
		local money = GetMoney()
		if GetCoinTextureString then return GetCoinTextureString(money) end
		return math.floor(money / 10000) .. "g"
	end,
}
TextVars.NAMES = { "player", "realm", "class", "spec", "level", "guild", "ilvl",
	"zone", "subzone", "time", "date", "fps", "latency", "gold" }

local tracked = {}   -- [frame] = true: frames with variables in their text
local ticker

-- Texture code of an icon, as big as the text
local function icon(file)
	return file and ("|T" .. file .. ":0|t ") or ""
end

-- Variables with a number: {currency:<id>} and {item:<id>} (amount with its icon)
local PARAM_VARS = {
	currency = function(id)
		local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(id)
		if not info then return end
		local amount = BreakUpLargeNumbers and BreakUpLargeNumbers(info.quantity) or info.quantity
		return icon(info.iconFileID) .. amount
	end,
	item = function(id)
		local getCount = C_Item and C_Item.GetItemCount or GetItemCount
		local getIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
		local count = getCount and getCount(id, true) or 0
		return icon(getIcon and getIcon(id)) .. count
	end,
}

local function known(word, param)
	word = word:lower()
	if param ~= "" then return PARAM_VARS[word] ~= nil end
	return VARS[word] ~= nil
end

local function replace(word, param)
	if not known(word, param) then return end
	local fn = param ~= "" and PARAM_VARS[word:lower()] or VARS[word:lower()]
	local ok, value = pcall(fn, tonumber(param))
	return ok and value ~= nil and tostring(value) or ""
end

function TextVars:Render(text)
	return (text:gsub("{(%a+):?(%d*)}", replace))
end

function TextVars:Uses(text)
	for word, param in text:gmatch("{(%a+):?(%d*)}") do
		if known(word, param) then return true end
	end
	return false
end

local function tick()
	for frame in pairs(tracked) do
		if frame.textTemplate and frame:IsVisible() then
			frame.text:SetText(TextVars:Render(frame.textTemplate))
		end
	end
end

-- Shows a text on a panel, and keeps it up to date when it has variables
function TextVars:Set(frame, text)
	if self:Uses(text) then
		frame.textTemplate = text
		tracked[frame] = true
		frame.text:SetText(self:Render(text))
		if not ticker then ticker = C_Timer.NewTicker(1, tick) end
	else
		frame.textTemplate = nil
		tracked[frame] = nil
		frame.text:SetText(text)
		if ticker and not next(tracked) then
			ticker:Cancel()
			ticker = nil
		end
	end
end
