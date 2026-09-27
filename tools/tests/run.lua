-- Offline tests of nxPanels, run with LuaJIT from the repository root:
--   luajit tools/tests/run.lua <scenario>
-- Scenarios: migrate, original, empty, forever, zhcn, real (NXP_REAL_SV=path/to/kgPanels_Reloaded.lua)

local scenario = arg[1] or "migrate"
local M = dofile("tools/tests/wowmock.lua")

-- WoW's string.format supports positional arguments (%2$s), LuaJIT's does not
do
	local rawformat = string.format
	string.format = function(fmt, ...)
		if type(fmt) == "string" and fmt:find("%%%d+%$") then
			local args, order = { ... }, {}
			fmt = fmt:gsub("%%(%d+)%$", function(n) order[#order + 1] = tonumber(n) return "%" end)
			local ordered = {}
			for i, n in ipairs(order) do ordered[i] = args[n] end
			return rawformat(fmt, unpack(ordered, 1, #order))
		end
		return rawformat(fmt, ...)
	end
	getmetatable("").__index.format = string.format
end

local failures, checks = 0, 0
local function check(cond, label)
	checks = checks + 1
	if not cond then
		failures = failures + 1
		print("  FAIL " .. label)
	end
end
local function printed(pattern)
	for _, line in ipairs(M.printed) do
		if line:find(pattern) then return true end
	end
	return false
end
local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end
local function deepEqual(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

---------------------------------------------------------------------------
-- Environment of the scenario
---------------------------------------------------------------------------
local function fixture()
	local env = setmetatable({}, { __index = _G })
	setfenv(assert(loadfile("tools/tests/fixtures/legacy_kgpanels.lua")), env)()
	return env.kgPanelsDB
end

local realSV = os.getenv("NXP_REAL_SV")
local function realData()
	local env = {}
	setfenv(assert(loadfile(realSV)), env)()
	return env.kgPanelsDB
end

if scenario == "forever" then
	M.build = { "1.60.1", "70009", "Sep 20 2026", 16001 }
elseif scenario == "zhcn" then
	M.locale = "zhCN"
	STANDARD_TEXT_FONT = "Fonts\\ARKai_T.ttf"
end

local legacySource = scenario == "real" and realData or fixture
if scenario == "original" then
	kgPanelsDB = fixture()
	M.addons = {
		{ name = "kgPanels", loaded = true },
		{ name = "kgPanels_Reloaded", lod = true, onLoad = function() kgPanelsDB = { global = { layouts = { Wrong = {} } } } end },
		{ name = "nxPanels", loaded = true },
	}
elseif scenario ~= "empty" then
	M.addons = {
		{ name = "kgPanelsConfig_Reloaded", lod = true },
		{ name = "kgPanels_Reloaded", lod = true, onLoad = function() kgPanelsDB = legacySource() end },
		{ name = "nxPanels", loaded = true },
		{ name = "Details" },
	}
else
	M.addons = { { name = "nxPanels", loaded = true } }
end

---------------------------------------------------------------------------
-- Load the addon like the client does (TOC order)
---------------------------------------------------------------------------
local ns = {}
local ROOT = "nxPanels/"
local function load(path)
	local chunk = assert(loadfile(ROOT .. path))
	chunk("nxPanels", ns)
end
for _, lib in ipairs({
	"Libs/LibStub/LibStub.lua", "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua", "Libs/AceDB-3.0/AceDB-3.0.lua",
	"Libs/AceLocale-3.0/AceLocale-3.0.lua", "Libs/AceSerializer-3.0/AceSerializer-3.0.lua",
	"Libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua", "Libs/LibSerialize/LibSerialize.lua",
	"Libs/LibDeflate/LibDeflate.lua", "Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua",
}) do
	load(lib)
end
-- LibDBIcon needs the real minimap: replaced by a stub
local icon = LibStub:NewLibrary("LibDBIcon-1.0", 9999)
function icon:Register(name, obj, db) self.registered = { name = name, obj = obj, db = db } end
function icon:Show() end
function icon:Hide() end

for line in io.lines(ROOT .. "nxPanels.toc") do
	line = line:gsub("\r", "")
	if line:match("%.lua$") then load((line:gsub("\\", "/"))) end
end

M.Fire("ADDON_LOADED", "nxPanels")

-- Import module (loaded after nxPanels, like RequiredDeps does)
local I = {}
for line in io.lines("nxPanels_Import/nxPanels_Import.toc") do
	line = line:gsub("\r", "")
	if line:match("%.lua$") then assert(loadfile("nxPanels_Import/" .. line))("nxPanels_Import", I) end
end
M.Fire("ADDON_LOADED", "nxPanels_Import")
M.Fire("PLAYER_LOGIN")

local db = nxPanelsDB
local L = ns.L
print(("[%s] client: retail=%s forever=%s, locale %s"):format(scenario, tostring(ns.isRetail), tostring(ns.isForever), M.locale))

---------------------------------------------------------------------------
-- Checks
---------------------------------------------------------------------------
local function layoutByName(name)
	for id, layout in pairs(db.global.layouts) do
		if layout.name == name then return id, layout end
	end
end
local function frameOf(layout, name)
	local id = ns.Database:FindPanel(layout, name)
	return id and ns.Layouts.frames[id], id
end

if scenario == "migrate" or scenario == "forever" or scenario == "zhcn" then
	check(ns.isForever == (scenario == "forever"), "client detection")
	check(M.loadCalls[1] == "kgPanels_Reloaded", "bridge addon loaded")
	check(count(db.global.layouts) == 2, "2 layouts imported, empty translated 'None' layout skipped")
	local mainId, main = layoutByName("Main UI")
	local secondId, second = layoutByName("Second")
	check(main and count(main.panels) == 6 and count(second.panels) == 2, "panels imported")
	check(main.folders[1] == "Bars" and #main.folders == 1, "folders imported")
	check(db.global.media.background["My Art"] and db.global.media.border["My Border"], "custom art imported")
	check(not db.global.media.background["Solid"] and not db.global.media.border["Bulle d'aide de Blizzard"], "built-in art not duplicated")
	check(db.global.migration and db.global.migration.source == "kgPanels_Reloaded", "migration recorded")
	check(db.profileKeys["Muse - Hyjal"] == "Default" and db.profileKeys["Alt - Hyjal"] == "Alt", "profile keys kept")
	check(db.profiles.Default.layout == mainId and db.profiles.Alt.layout == secondId, "profile layouts mapped to ids")
	check(db.profiles.Alt.enabled == false and db.profiles.Empty.layout == nil, "profile flags")
	check(db.namespaces["LibDualSpec-1.0"] ~= nil, "LibDualSpec settings kept")
	check(deepEqual(kgPanelsDB, fixture()), "legacy data left untouched")
	check(M.disabled.kgPanels_Reloaded and M.disabled.kgPanelsConfig_Reloaded, "legacy addons disabled")
	check(#M.popups == 0, "no reload popup when only the bridge was used")
	check(printed(L["MIGRATED"]:format(2, 8, "kgPanels_Reloaded"):gsub("%p", "%%%0")), "migration message")

	-- Active layout of the Default profile
	check(ns.Layouts.activeId == mainId, "active layout")
	local bar = frameOf(main, "Bottom Bar")
	check(bar and bar.shown and bar.w == 1920 and bar.h == 32, "percent width, string height")
	check(bar.points[1][5] == -520, "string offset converted")
	check(not bar.border.textures.TOP.shown, "translated 'None' border = no border")

	local chat = frameOf(main, "Chat BG")
	check(chat.points[1][2] == bar and chat.points[1][1] == "BOTTOMLEFT", "panel anchored to another panel")
	check(chat.border.textures.LEFT.texture == "Interface\\Tooltips\\UI-Tooltip-Border", "translated border name resolved")
	check(chat.bg.texture == "Interface\\AddOns\\MyMedia\\art.tga", "custom background resolved")
	check(chat.text.font[1] == STANDARD_TEXT_FONT and chat.text.font[2] == 12, "language default font, size 0 -> 12")
	check(chat.text.textValue == "|cffff0000Chat|r", "escaped color codes")
	check(chat.bg.points[1][4] == 4 and chat.bg.points[1][5] == -4 and chat.bg.points[2][4] == -4 and chat.bg.points[2][5] == 4, "background insets")

	local loopA = frameOf(main, "Loop A")
	local loopB = frameOf(main, "Loop B")
	check(loopA.points[1][2] == UIParent and loopB.points[1][2] == UIParent, "anchoring loop broken")
	check(printed("Loop A") and printed("Loop B"), "anchoring loop reported")

	local waiting, waitingId = frameOf(main, "Waiting")
	check(waiting and not waiting.shown and ns.Layouts.waiting[waitingId], "panel waiting for a missing frame")
	local target = CreateFrame("Frame", "SomeAddonFrame", UIParent)
	target.w, target.h = 300, 200
	M.ticker.fn()
	check(waiting.shown and waiting.parent == target and not ns.Layouts.waiting[waitingId], "panel shown once its frame exists")
	check(M.ticker.cancelled, "retry timer stopped")

	-- Scripts wait for their dependency
	local s = frameOf(main, "Scripted")
	check(s.level == 0, "negative frame level clamped")
	check(s.loaded == nil and s.scripts.OnEvent == nil, "scripts wait for their addon")
	M.addons[4].loaded = true
	M.Fire("ADDON_LOADED", "Details")
	check(s.loaded == 1, "LOAD script ran once")
	check(ns.Scripts.env.LoadedBy == ns.API and rawget(_G, "LoadedBy") == nil, "script variables isolated from the game globals")
	s.scripts.OnEvent(s, "PLAYER_TARGET_CHANGED", "unit1")
	check(s.lastArg == "unit1", "EVENT script with legacy arg1")
	check(s.found == bar, "old kgPanels:FetchFrame call rewritten to nxPanels")
	s.scripts.OnMouseDown(s, "LeftButton")
	s.scripts.OnMouseUp(s, "RightButton")
	check(s.down == "LeftButton" and s.up == "RightButton", "CLICK script pressed / released")
	check(s.scripts.OnShow ~= nil, "script ending with a comment compiles")
	check(s.scripts.OnHide == nil, "empty script ignored")
	local before = #M.printed
	s.scripts.OnUpdate(s, 0.1)
	check(s.scripts.OnUpdate == nil, "failing script switched off")
	check(#M.printed == before + 1 and M.printed[#M.printed]:find("boom"), "script error reported once")

	-- Second layout: gradient, rotation, flips, tiling, hidden border sides
	SlashCmdList.NXPANELS("layout second")
	check(ns.Layouts.activeId == secondId and ns.db.profile.layout == secondId, "layout switched by name (case-insensitive)")
	check(not s.shown or s.panelId ~= nil, "previous frames released")
	local art = frameOf(second, "Art")
	check(art.bg.gradient and art.bg.gradient[3].a == 0.5, "gradient with string alpha")
	check(art.bg.subLevel == 7, "sublevel clamped")
	check(#art.bg.texCoord == 8, "rotation + flip coordinates")
	check(not art.border.textures.TOP.shown and art.border.textures.BOT.shown, "hidden border sides")
	check(art.border.textures.TOP.texCoord and #art.border.textures.TOP.texCoord == 8, "rotated border side")
	local tiled = frameOf(second, "Tiled")
	tiled.bg.w, tiled.bg.h = 192, 92
	tiled.sizer.scripts.OnSizeChanged(tiled.sizer)
	check(tiled.bg.wrapH == "REPEAT" and tiled.bg.texCoord[2] == 6, "tiled background")

	-- Commands
	for _, cmd in ipairs({ "", "layouts", "status", "toggle", "toggle", "minimap", "config", "layout nope" }) do
		local ok, err = pcall(SlashCmdList.NXPANELS, cmd)
		check(ok, "command '" .. cmd .. "': " .. tostring(err))
	end
	check(printed(L["LAYOUT_NOT_FOUND"]:format("nope")), "unknown layout message")

	-- Next start: no second migration
	I.Import:Auto()
	check(count(db.global.layouts) == 2, "no migration on the next start")

	-- Manual import adds copies with unique names
	SlashCmdList.NXPANELS("import")
	check(count(db.global.layouts) == 4 and layoutByName("Main UI (2)"), "manual import with unique names")
	for _, lyt in pairs(db.global.layouts) do
		for _, p in pairs(lyt.panels) do
			for _, code in pairs(p.scripts) do
				check(not code:find("kgPanels"), "no kgPanels left in converted scripts")
			end
		end
	end

	-- Export / import of a layout
	local mainIdNow = layoutByName("Main UI")
	local text = ns.Share:Export(mainIdNow)
	check(text and text:sub(1, 6) == "!NXP1!", "export string")
	local decoded = ns.Share:Decode(text)
	check(decoded and decoded.count == 6 and decoded.scripted[1] == "Scripted", "export decoded, scripts listed")
	local newId = ns.Share:Import(decoded, "Copy")
	local copy = ns.Database:GetLayout(newId)
	local chatId, chatPanel = ns.Database:FindPanel(copy, "Chat BG")
	local barId = ns.Database:FindPanel(copy, "Bottom Bar")
	check(copy and copy.name == "Copy" and chatPanel.anchor.relativeTo == "panel:" .. barId, "imported copy keeps its anchors")
	local bad, err = ns.Share:Decode("hello")
	check(not bad and err == L["IMPORT_INVALID"], "invalid string rejected")
	local legacyString = LibStub("AceSerializer-3.0"):Serialize(fixture().global.layouts["Second"])
	local old = ns.Share:Decode(legacyString)
	check(old and old.count == 2 and old.format == L["FORMAT_LEGACY"], "old kgPanels string decoded by the import module")
	local oldId = ns.Share:Import(old, "From old")
	check(ns.Database:GetLayout(oldId) and ns.Database:CountPanels(ns.Database:GetLayout(oldId)) == 2, "old kgPanels string imported")

	if scenario == "zhcn" then
		check(chat.text.font[1] == "Fonts\\ARKai_T.ttf", "Chinese font used by default")
		check(printed("已从 kgPanels_Reloaded 导入 2 个布局和 8 个面板"), "Chinese messages")
	end

elseif scenario == "original" then
	check(#M.loadCalls == 0, "bridge not loaded when the original kgPanels is present")
	check(db.global.migration.source == "kgPanels", "imported from the original kgPanels")
	check(count(db.global.layouts) == 2, "layouts imported")
	check(M.disabled.kgPanels, "original addon disabled")
	check(M.popups[1] == "NXPANELS_MIGRATED", "reload popup shown")

elseif scenario == "empty" then
	check(count(db.global.layouts) == 0 and not db.global.migration, "nothing imported")
	local ok = pcall(SlashCmdList.NXPANELS, "status")
	check(ok and printed(L["LAYOUT_NONE"]:gsub("%p", "%%%0")), "status without layout")
	SlashCmdList.NXPANELS("import")
	check(printed(L["MIGRATE_NOTHING"]), "import without legacy data")

elseif scenario == "real" then
	local panels = 0
	for _, layout in pairs(db.global.layouts) do panels = panels + count(layout.panels) end
	print(("  imported %d layouts, %d panels"):format(count(db.global.layouts), panels))
	for _, entry in ipairs(ns.Database:SortedLayouts()) do
		print(("   - %s: %d panels, folders: %s"):format(entry.layout.name, count(entry.layout.panels), table.concat(entry.layout.folders, ", ")))
	end
	for name, profile in pairs(db.profiles) do
		local layout = ns.Database:GetLayout(profile.layout)
		print(("   profile %s -> %s"):format(name, layout and layout.name or "-"))
	end
	local shown, waiting = ns.Layouts:CountShown()
	print(("  active layout: %s, %d shown, %d waiting"):format(tostring(ns.API.GetActiveLayout()), shown, waiting))
	check(panels > 0 and shown > 0, "real data rendered")
	check(deepEqual(kgPanelsDB, realData()), "legacy data left untouched")
end

for _, line in ipairs(M.printed) do
	if line:find("rror") then print("  chat: " .. line) end
end
print(("  %d checks, %d failed"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
