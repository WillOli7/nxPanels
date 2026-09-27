-- Offline tests of nxPanels, run with LuaJIT from the repository root:
--   luajit tools/tests/run.lua <scenario>
-- Scenarios: migrate, original, handinstall, empty, forever, zhcn, options, real (NXP_REAL_SV=path/to/kgPanels_Reloaded.lua)

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
-- Optional client language: luajit tools/tests/run.lua options zhTW
if arg[2] then
	M.locale = arg[2]
	if arg[2]:find("^zh") then STANDARD_TEXT_FONT = "Fonts\\ARKai_T.ttf" end
end

local legacySource = scenario == "real" and realData or fixture
if scenario == "original" then
	kgPanelsDB = fixture()
	M.addons = {
		{ name = "kgPanels", loaded = true },
		{ name = "kgPanels_Reloaded", lod = true, onLoad = function() kgPanelsDB = { global = { layouts = { Wrong = {} } } } end },
		{ name = "nxPanels", loaded = true },
	}
elseif scenario == "handinstall" then
	-- The old kgPanels Reloaded (full addon, not the bridge) installed by hand next to nxPanels
	kgPanelsDB = fixture()
	M.addons = {
		{ name = "kgPanelsConfig_Reloaded", loaded = true },
		{ name = "kgPanels_Reloaded", loaded = true },
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
-- Loads the options module like C_AddOns.LoadAddOn does
local function loadOptions()
	M.addons[#M.addons + 1] = { name = "nxPanels_Options", loaded = true }
	local O = {}
	for line in io.lines("nxPanels_Options/nxPanels_Options.toc") do
		line = line:gsub("\r", "")
		if line:match("%.lua$") then assert(loadfile("nxPanels_Options/" .. line:gsub("\\", "/")))("nxPanels_Options", O) end
	end
	return O
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
	local specs = ns.Specs:List()
	local specKeys = scenario == "forever" and "G1G2" or "S62S63S64"
	local joined = ""
	for _, spec in ipairs(specs) do joined = joined .. spec.key end
	check(joined == specKeys, "specializations of the client: " .. joined)
	local specLayouts = db.profiles.Default.specLayouts or {}
	check(specLayouts[specs[1].key] == mainId and specLayouts[specs[2].key] == secondId, "profiles per spec became layouts per spec")
	check(not (db.namespaces and db.namespaces["LibDualSpec-1.0"]), "LibDualSpec settings not copied")
	check(db.global.schema == ns.SCHEMA, "schema saved")
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

	-- Display conditions, opacity and fades
	ns.Layouts:Activate(mainId)
	local chatId, barId
	chat, chatId = frameOf(main, "Chat BG")
	barId = select(2, frameOf(main, "Bottom Bar"))
	local chatP = main.panels[chatId]
	local d = chatP.display
	local driver = ns.Visibility.driver
	local function redraw() ns.Layouts:PanelChanged(chatId, "display") end
	d.combat = "IN"
	redraw()
	check(not chat.shown and chat.nxManaged, "hidden out of combat")
	M.Fire("PLAYER_REGEN_DISABLED")
	check(chat.shown and chat.alpha == 1, "shown in combat")
	M.Fire("PLAYER_REGEN_ENABLED")
	check(not chat.shown, "hidden again after combat")
	d.fade = 1
	M.Fire("PLAYER_REGEN_DISABLED")
	check(chat.shown and chat.alpha == 0, "fade starts transparent")
	driver.scripts.OnUpdate(driver, 0.5)
	check(math.abs(chat.alpha - 0.5) < 0.01, "fading in")
	driver.scripts.OnUpdate(driver, 0.6)
	check(chat.alpha == 1, "fade finished")
	M.Fire("PLAYER_REGEN_ENABLED")
	driver.scripts.OnUpdate(driver, 2)
	check(not chat.shown and chat.alpha == 0, "faded out, then hidden")
	d.combat, d.fade = "ANY", 0
	d.alpha, d.hoverAlpha = 0.3, 1
	redraw()
	check(chat.shown and chat.alpha == 0.3, "base opacity")
	M.state.hover[chat] = true
	driver.scripts.OnUpdate(driver, 0.2)
	check(chat.alpha == 1, "mouse-over opacity")
	M.state.hover[chat] = nil
	d.alpha, d.hoverAlpha = 1, 1
	d.macro = "[combat] show; hide"
	redraw()
	check(not chat.shown, "macro condition hides")
	d.macro = ""
	d.group = "RAID"
	redraw()
	check(not chat.shown, "raid only: hidden solo")
	M.state.raid = true
	M.Fire("GROUP_ROSTER_UPDATE")
	check(chat.shown, "shown in a raid")
	M.state.raid = false
	M.Fire("GROUP_ROSTER_UPDATE")
	ns.Visibility:SetForceShow(true)
	check(chat.shown and chat.alpha == 1, "edit mode shows hidden panels")
	ns.Visibility:SetForceShow(false)
	check(not chat.shown, "hidden again after the edit mode")
	d.group = "ANY"
	redraw()
	check(chat.shown and chat.alpha == 1 and not chat.nxManaged, "default settings: panel left to its scripts")

	-- Automatic colors
	chatP.background.style, chatP.background.texture = "SOLID", "Solid"
	chatP.background.colorMode = "CLASS"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.bg.vertexColor[1] == 0.25 and chat.bg.vertexColor[4] == math.min(chatP.background.color.a, chatP.background.alpha), "class color, own opacity")
	chatP.background.colorMode = "REACTION"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.bg.vertexColor[1] == chatP.background.color.r, "no target: custom color")
	M.state.target = "hostile"
	M.Fire("PLAYER_TARGET_CHANGED")
	check(chat.bg.vertexColor[1] == 0.86, "hostile target: red")
	M.state.target = nil
	chatP.border.texture, chatP.border.colorMode = "Blizzard Tooltip", "FACTION"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.border.textures.TOP.vertexColor[1] == 0.18, "faction color on the border")
	chatP.background.colorMode, chatP.border.colorMode = "CUSTOM", "CUSTOM"

	-- Blizzard atlas
	chatP.background.texture = "atlas:test-atlas"
	ns.Layouts:PanelChanged(chatId, "look")
	local tc = chat.bg.texCoord
	check(chat.bg.texture == 12345 and chat.bg.shown and tc[1] == 0.5 and tc[2] == 0 and tc[7] == 1 and tc[8] == 0.25, "atlas drawn from its sheet")
	chatP.background.texture = "atlas:missing"
	ns.Layouts:PanelChanged(chatId, "look")
	check(not chat.bg.shown, "unknown atlas: no background")
	chatP.background.texture = "Solid"

	-- Text variables
	chatP.text.value = "{zone} {fps} {unknown}"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.text.textValue == "Valdrakken 60 {unknown}" and chat.textTemplate, "text variables replaced")
	local textTicker = M.ticker
	chatP.text.value = "plain"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.text.textValue == "plain" and textTicker.cancelled, "no variables: timer stopped")

	-- A recycled frame does not keep what the scripts stored on it
	local recycled = ns.Panel:Acquire("PX")
	recycled.done = true
	ns.Panel:Release(recycled)
	check(recycled.done == nil and recycled.bg and recycled.sizer and recycled.border, "script values cleared when a frame is recycled")

	-- Script check, panel export, media packs
	local scriptErr = ns.Scripts:Check("LOAD", "local x =")
	check(scriptErr and scriptErr:find("LOAD:1") and not ns.Scripts:Check("EVENT", "print(event, arg1)"), "script syntax check with line number")
	local panelsText = ns.Share:ExportPanels(mainId, { chatId, barId })
	local partial = ns.Share:Decode(panelsText)
	check(partial and partial.kind == "panels" and partial.count == 2, "panels exported")
	local added = partial.addTo(mainId)
	local copyChatId, copyChat = ns.Database:FindPanel(main, "Chat BG (2)")
	local copyBarId = ns.Database:FindPanel(main, "Bottom Bar (2)")
	check(#added == 2 and copyChat and copyChat.anchor.relativeTo == "panel:" .. copyBarId, "panels added to a layout, anchors kept")
	check(nxPanels.RegisterMedia("background", "Pack Stone", "Interface\\AddOns\\Pack\\stone.tga") and ns.Media.LSM:Fetch("background", "Pack Stone"), "media pack API")
	-- LibSerialize patched for WoW Forever (no division by zero): values still round-trip
	local LS = LibStub("LibSerialize")
	local okZero, zeros = LS:Deserialize(LS:Serialize({ 0, -0.0, 1.5, 0 / 0 }))
	check(okZero and zeros[1] == 0 and tostring(zeros[2]) == "-0" and zeros[3] == 1.5 and zeros[4] ~= zeros[4], "zero, negative zero and NaN serialized without dividing by zero")

	-- Layout per specialization
	local function setSpec(n)
		if scenario == "forever" then M.specGroup = n else M.spec = n end
		M.Fire(scenario == "forever" and "ACTIVE_TALENT_GROUP_CHANGED" or "PLAYER_SPECIALIZATION_CHANGED", "player")
	end
	ns.Layouts:Activate(mainId)
	setSpec(2)
	check(ns.Layouts.activeId == secondId, "layout of the specialization shown")
	ns.Layouts:Activate(mainId)
	check(db.profiles.Default.specLayouts[specs[2].key] == mainId and ns.Layouts.activeId == mainId, "activating by hand changes the layout of the spec")
	ns.Database:SetSpecLayoutId(specs[2].key, secondId)
	ns.Database:DeleteLayout(secondId)
	check(db.profiles.Default.specLayouts[specs[2].key] == nil, "deleted layout removed from the specs")
	setSpec(nil)

	if scenario == "zhcn" then
		check(chat.text.font[1] == "Fonts\\ARKai_T.ttf", "Chinese font used by default")
		check(printed("已从 kgPanels_Reloaded 导入 2 个布局和 8 个面板"), "Chinese messages")
	end

elseif scenario == "options" then
	local O = loadOptions()
	local Options, P = ns.Options, O.PanelsPage
	local mainId, main = layoutByName("Main UI")
	local barId = ns.Database:FindPanel(main, "Bottom Bar")
	local chatId = ns.Database:FindPanel(main, "Chat BG")
	local waitingId = ns.Database:FindPanel(main, "Waiting")

	local function findRow(form, label)
		for _, r in ipairs(form.rows) do
			if r.label and r.label.textValue == label then return r end
		end
		error("row not found: " .. tostring(label))
	end
	local function setSlider(r, value)
		r.valueBox.edit:SetText(tostring(value))
		r.valueBox.edit.scripts.OnEnterPressed(r.valueBox.edit)
	end
	local function choose(r, value)
		r.button.scripts.OnClick(r.button)
		return O.Dropdown:Choose(value)
	end
	local function click(b) b.scripts.OnClick(b, "LeftButton") end
	local function typeIn(edit, text)
		edit:SetText(text)
		edit.scripts.OnTextChanged(edit, true)
	end

	-- Window and pages
	local ok, err = pcall(SlashCmdList.NXPANELS, "")
	check(ok and Options.frame and Options.frame.shown, "window opened: " .. tostring(err))
	for _, key in ipairs(Options.order) do
		if key ~= "editmode" then
			ok, err = pcall(Options.Show, Options, key)
			check(ok and Options.current == key, "page " .. key .. ": " .. tostring(err))
		end
	end

	-- Panels page: list by folders
	Options:Show("panels")
	local list = P.page.list.scroll.content
	check(list.h == 7 * 26, "list: folder, its panel and the root panels")
	P.collapsed.Bars = true
	P:RefreshList()
	check(list.h == 6 * 26, "folder collapsed")
	P.collapsed.Bars = nil
	P.page.search.edit:SetText("loop")
	check(list.h == 2 * 26, "search filter")
	P.page.search.edit:SetText("")

	-- Editor: every change is drawn at once
	P:Select(chatId)
	local editor = P.page.editor
	local chat, chatPanel = ns.Layouts.frames[chatId], main.panels[chatId]
	check(editor.shown and editor.name.textValue == "Chat BG", "panel selected in the editor")
	local general = editor.tabs.general.form
	setSlider(findRow(general, L["WIDTH"]), 321)
	check(chatPanel.width == 321 and chat.w == 321, "width applied live")
	setSlider(findRow(general, L["OFFSET_X"]), 2500)
	check(chatPanel.anchor.x == 2500, "offset accepts values outside the slider range")
	check(choose(findRow(general, L["WIDTH_UNIT"]), "%") and chatPanel.widthUnit == "%", "unit dropdown")
	choose(findRow(general, L["WIDTH_UNIT"]), "px")
	choose(findRow(general, L["ANCHORED_TO"]), "__custom")
	M.lastPopup.data.onAccept("MissingFrame")
	check(chatPanel.anchor.relativeTo == "MissingFrame" and ns.Layouts.waiting[chatId] and not chat.shown, "anchored to a frame by name")
	check(findRow(general, L["ANCHORED_TO"]).button.text.textValue == "MissingFrame", "custom frame name shown")
	choose(findRow(general, L["ANCHORED_TO"]), "panel:" .. barId)
	check(chatPanel.anchor.relativeTo == "panel:" .. barId and chat.shown and chat.points[1][2] == ns.Layouts.frames[barId], "anchored back to a panel")

	-- Texture rows open the browser
	local function browse(r, value)
		r.button.scripts.OnClick(r.button)
		local shown = O.Browser.frame.shown
		O.Browser:Choose(value)
		return shown
	end
	check(browse(findRow(editor.tabs.background.form, L["TEXTURE"]), "Solid") and chat.bg.texture == "Interface\\Buttons\\WHITE8X8", "background texture from the browser")
	local bgRow = findRow(editor.tabs.background.form, L["TEXTURE"])
	bgRow.button.scripts.OnClick(bgRow.button)
	O.Browser.frame.tabs:Select("atlas")
	check(O.Browser.frame.count.textValue == L["ATLAS_COUNT"]:format(1), "atlas tab: only the atlases of this client")
	O.Browser:Choose("atlas:test-atlas")
	check(chatPanel.background.texture == "atlas:test-atlas" and chat.bg.texture == 12345, "Blizzard atlas chosen")
	check(bgRow.button.text.textValue == L["ATLAS_ITEM"]:format("test-atlas"), "atlas name shown")
	browse(bgRow, "Solid")
	choose(findRow(editor.tabs.background.form, L["STYLE"]), "GRADIENT")
	check(chat.bg.gradient ~= nil and findRow(editor.tabs.background.form, L["COLOR_END"]).shown, "gradient shows its second color")
	check(browse(findRow(editor.tabs.border.form, L["TEXTURE"]), false) and chatPanel.border.texture == false and not chat.border.textures.TOP.shown, "no border (false)")
	local fontRow = findRow(editor.tabs.text.form, L["FONT"])
	check(choose(fontRow, nil) and chatPanel.text.font == nil and chat.text.font[1] == STANDARD_TEXT_FONT, "language default font")
	typeIn(editor.tabs.text.form.rows[1].area.edit, "Hello ||cffff0000red||r")
	check(chatPanel.text.value == "Hello ||cffff0000red||r" and chat.text.textValue == "Hello |cffff0000red|r", "text typed live")

	-- Scripts: edited as drafts, applied with Save
	local scripts = editor.tabs.scripts.form
	local code = scripts.rows[2].area.edit
	typeIn(code, "self.testLoaded = (self.testLoaded or 0) + 1")
	check(chatPanel.scripts.LOAD == nil and P.drafts[chatId .. "LOAD"], "script draft not saved yet")
	click(scripts.rows[3].buttons[3])
	check(chatPanel.scripts.LOAD and chat.testLoaded == 1 and not P.drafts[chatId .. "LOAD"], "script saved and run")
	editor.bar:Select("scripts")
	typeIn(code, "local x =")
	click(scripts.rows[3].buttons[2])
	check(scripts.rows[4].shown and scripts.rows[4].text.textValue:find("LOAD:1"), "syntax check shows the line")
	click(scripts.rows[3].buttons[1])
	editor.bar:Select("general")

	-- Display tab
	local display = editor.tabs.display.form
	choose(findRow(display, L["COND_COMBAT"]), "IN")
	check(chatPanel.display.combat == "IN" and not chat.shown, "display condition applied at once")
	choose(findRow(display, L["COND_COMBAT"]), "ANY")
	check(chat.shown, "shown again")
	setSlider(findRow(display, L["ALPHA_BASE"]), 0.5)
	check(chatPanel.display.combatAlpha == 0.5 and chatPanel.display.hoverAlpha == 0.5 and chat.alpha == 0.5, "opacity: combat and mouse-over follow")
	setSlider(findRow(display, L["ALPHA_BASE"]), 1)
	check(chat.alpha == 1 and not chat.nxManaged, "back to defaults")

	-- Automatic color, text variables
	choose(findRow(editor.tabs.background.form, L["STYLE"]), "SOLID")
	choose(findRow(editor.tabs.background.form, L["COLOR_MODE"]), "CLASS")
	check(chatPanel.background.colorMode == "CLASS" and chat.bg.vertexColor[1] == 0.25, "class color chosen")
	choose(findRow(editor.tabs.background.form, L["COLOR_MODE"]), "CUSTOM")
	chatPanel.text.value = "Zone:"
	choose(findRow(editor.tabs.text.form, L["INSERT_VARIABLE"]), "zone")
	check(chatPanel.text.value == "Zone: {zone}" and chat.text.textValue == "Zone: Valdrakken", "variable inserted")
	choose(findRow(editor.tabs.text.form, L["INSERT_ICON"]), "Interface\\MoneyFrame\\UI-GoldIcon")
	check(chat.text.textValue == "Zone: Valdrakken |TInterface\\MoneyFrame\\UI-GoldIcon:0|t", "icon inserted as a texture code")
	-- Every icon of the game: only the visible cells are drawn
	chatPanel.text.value = ""
	choose(findRow(editor.tabs.text.form, L["INSERT_ICON"]), "__all")
	local browser = O.Browser.frame
	browser.scroll.w, browser.scroll.h = 720, 440
	O.Browser:FillIcons()
	check(browser.count.textValue == L["ICON_COUNT"]:format(500) and browser.scroll.content.h == math.ceil(500 / 16) * 44, "500 icons in the grid")
	browser.scroll:SetVerticalScroll(44 * 20)
	browser.scroll.scripts.OnMouseWheel(browser.scroll, 0)
	O.Browser:Choose(100000 + 16 * 20 + 1)
	check(chatPanel.text.value == "||T100321:0||t", "icon of the game inserted")
	-- Currencies and items
	chatPanel.text.value = ""
	choose(findRow(editor.tabs.text.form, L["INSERT_CURRENCY"]), 3008)
	chatPanel.text.value = chatPanel.text.value .. " {item:6948}"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.text.textValue == "|T5868902:0|t 12345 |T134400:0|t 7", "currency and item amounts with their icons")
	chatPanel.text.value = "Zone: {zone}"
	-- A list row used by the font list goes back to the normal font
	local fontRow = findRow(editor.tabs.text.form, L["FONT"])
	fontRow.button.scripts.OnClick(fontRow.button)
	O.Dropdown:Close()
	local iconRow = findRow(editor.tabs.text.form, L["INSERT_ICON"])
	iconRow.button.scripts.OnClick(iconRow.button)
	local rows = O.Dropdown.popup.buttons
	check(rows[2].text.font[1] == STANDARD_TEXT_FONT and rows[2].text.font[2] == 13 and rows[2].h == 28, "list rows: normal font, square icons")
	O.Dropdown:Close()

	-- Export of one panel, pasted back: added to the active layout
	P:Export({ chatId }, "Chat BG")
	local one = O.SharePage.exportText
	check(O.SharePage.page.exportInfo.textValue:find("Chat BG"), "panel export")
	O.SharePage:ShowImport()
	O.SharePage.page.importArea.edit:SetText(one)
	check(O.SharePage.decoded.kind == "panels" and not O.SharePage.page.nameBox.shown, "pasted panels: no layout name asked")
	O.SharePage:Import(false)
	local pastedId = ns.Database:FindPanel(main, "Chat BG (2)")
	check(pastedId and ns.Layouts.frames[pastedId] and ns.Database:GetLayout(ns.Layouts.activeId) == main, "panel added to the active layout")
	ns.Database:DeletePanel(mainId, pastedId)
	ns.Layouts:PanelChanged(pastedId, "removed")

	-- Gallery
	local before = count(main.panels)
	P.page.newPanel.scripts.OnClick(P.page.newPanel)
	check(O.Dropdown:Choose(1), "template chosen from the New panel menu")
	local barTplId, barTpl = ns.Database:FindPanel(main, L["TPL_INFO_BAR"])
	local lineId, line = ns.Database:FindPanel(main, L["TPL_INFO_BAR_LINE"])
	check(count(main.panels) == before + 2 and line and line.parent == "panel:" .. barTplId and line.background.colorMode == "CLASS", "template added, its panels linked")
	check(ns.Layouts.frames[barTplId].text.textValue:find("Valdrakken"), "template text variables")
	local glowLayout = O.AddTemplate(O.Templates[4], true)
	local glowId = next(ns.Database:GetLayout(glowLayout).panels)
	check(ns.Layouts.activeId == glowLayout and not ns.Layouts.frames[glowId].shown, "combat glow template hidden out of combat")
	ns.Layouts:Activate(mainId)
	for _, id in ipairs({ barTplId, lineId }) do
		ns.Database:DeletePanel(mainId, id)
		ns.Layouts:PanelChanged(id, "removed")
	end

	-- Panels and folders (frames were recycled by the layout switches above)
	chat = ns.Layouts.frames[chatId]
	local loadedBefore = chat.testLoaded
	P:NewPanel(nil)
	M.lastPopup.data.onAccept("Test panel")
	local testId, test = ns.Database:FindPanel(main, "Test panel")
	check(test and ns.Layouts.frames[testId] and ns.Layouts.frames[testId].shown and P.selected == testId, "panel created, drawn and selected")
	check(loadedBefore and chat.testLoaded == loadedBefore, "other panels keep running when a panel is added")
	P:Duplicate(testId)
	local dupId = ns.Database:FindPanel(main, "Test panel (2)")
	check(dupId and ns.Layouts.frames[dupId] and P.selected == dupId, "panel duplicated")
	P:Delete(dupId)
	M.lastPopup.data()
	check(not main.panels[dupId] and not ns.Layouts.frames[dupId] and P.selected == nil, "panel deleted, frame released")
	P:NewFolder()
	M.lastPopup.data.onAccept("Art")
	P:MoveToFolder(testId, editor)
	check(O.Dropdown:Choose("Art") and test.folder == "Art", "panel moved to a folder")
	P:RenameFolder("Art")
	M.lastPopup.data.onAccept("Deco")
	check(test.folder == "Deco" and main.folders[2] == "Deco", "folder renamed")
	P:DeleteFolder("Deco")
	M.lastPopup.data()
	check(test.folder == nil and #main.folders == 1, "folder deleted, panel kept")

	-- Library
	Options:Show("library")
	local lib = O.LibraryPage.page
	lib.nameBox.edit:SetText("Solid")
	lib.pathBox.edit:SetText("x")
	O.LibraryPage:Add()
	check(db.global.media.background.Solid == nil and lib.message.textValue == L["MEDIA_NAME_TAKEN"]:format("Solid"), "name used by another addon refused")
	lib.nameBox.edit:SetText("My Test")
	lib.pathBox.edit:SetText(" Interface/AddOns/Test//art.tga ")
	O.LibraryPage:Add()
	check(db.global.media.background["My Test"] == "Interface\\AddOns\\Test\\art.tga" and ns.Media.LSM:Fetch("background", "My Test", true), "media added with a clean path")
	ns.Media:RemoveFromLibrary("background", "My Test")
	check(db.global.media.background["My Test"] == nil, "media removed from the library")

	-- Import / export
	O.SharePage:ShowExport(mainId)
	local exported = O.SharePage.exportText
	check(exported and exported:sub(1, 6) == "!NXP1!" and O.SharePage.page.export.shown, "export tab")
	O.SharePage:ShowImport()
	local share = O.SharePage.page
	share.importArea.edit:SetText(exported)
	check(O.SharePage.decoded and O.SharePage.decoded.count == 7 and share.nameBox.edit.textValue == "Main UI", "pasted string decoded")
	check(share.noScripts.shown, "import without scripts offered")
	O.SharePage:Import(true)
	check(M.lastPopup.name == "NXPANELS_CONFIRM", "scripts need a confirmation")
	share.nameBox.edit:SetText("Imported copy")
	O.SharePage:Import(false)
	local copyId, copy = layoutByName("Imported copy")
	local scriptsLeft = 0
	for _, p in pairs(copy and copy.panels or {}) do scriptsLeft = scriptsLeft + count(p.scripts) end
	check(copy and ns.Layouts.activeId == copyId and scriptsLeft == 0, "imported without scripts and activated")

	-- Profiles
	Options:Show("profiles")
	local profiles = Options.pages.profiles.frame.form
	click(profiles.rows[2].buttons[1])
	M.lastPopup.data.onAccept("Test")
	check(ns.db:GetCurrentProfile() == "Test" and not ns.Layouts.activeId, "new empty profile")
	choose(findRow(profiles, L["DEFAULT_LAYOUT"]), mainId)
	check(ns.db.profile.layout == mainId and ns.Layouts.activeId == mainId, "layout chosen for the profile")
	choose(findRow(profiles, L["PROFILE"]), "Default")
	check(ns.db:GetCurrentProfile() == "Default", "profile switched")
	choose(findRow(profiles, L["DELETE_PROFILE"]), "Test")
	M.lastPopup.data()
	check(not ns.db.profiles.Test, "profile deleted")
	-- Layout per specialization, from the Profiles page
	M.spec = 2
	check(choose(findRow(profiles, "Spec2"), copyId) and ns.Layouts.activeId == copyId, "layout chosen for the current spec is shown")
	check(findRow(profiles, "Spec2").label.textColor[1] == O.Theme.colors.accent[1], "current spec highlighted")
	choose(findRow(profiles, "Spec2"), false)
	check(ns.db.profile.specLayouts.S63 == nil and ns.Layouts.activeId == ns.db.profile.layout, "spec back to the default layout")
	M.spec = nil
	-- Shared profile per class / faction
	local shared = profiles.rows[4]
	check(shared.buttons[1].label.textValue == L["PROFILE_OF_CLASS"]:format("Mage"), "class profile button")
	click(shared.buttons[2])
	check(ns.db:GetCurrentProfile() == "Alliance", "faction profile used")
	choose(findRow(profiles, L["PROFILE"]), "Default")
	choose(findRow(profiles, L["NEW_CHARACTERS"]), "class")
	check(ns.db.global.newCharacters == "class", "profile of new characters")

	-- Settings
	Options:Show("settings")
	local settings = Options.pages.settings.frame.form
	local minimap = findRow(settings, L["MINIMAP_BUTTON"])
	minimap.switch.scripts.OnClick(minimap.switch)
	check(ns.db.profile.minimap.hide == true, "minimap button hidden")
	setSlider(findRow(settings, L["GRID_SIZE"]), 16)
	choose(findRow(settings, L["THEME_STYLE"]), "night")
	check(ns.db.global.optionsTheme.style == "night" and M.lastPopup.name == "NXPANELS_CONFIRM", "style changed, reload asked")
	M.lastPopup.data()
	check(M.reloaded, "interface reloaded")
	check(findRow(settings, L["THEME_ACCENT"]).button.text.textValue == L["ACCENT_GOLD"], "accent shown")

	-- Edit mode
	ns.Layouts:Activate(mainId)
	local EM = O.EditMode
	Options:Show("panels")
	EM:Start()
	check(EM.active and not Options.frame.shown, "edit mode started, window hidden")
	check(EM.movers[testId] and EM.movers[chatId] and not EM.movers[waitingId], "movers for the shown panels only")
	local s = ns.db.global.editMode
	local testFrame = ns.Layouts.frames[testId]
	local m = EM.movers[testId]
	local function dragMover(target, fromX, toX, handle)
		testFrame.rect = { 860, 490, 200, 100 }
		M.cursor = { fromX, 500 }
		target.scripts.OnMouseDown(target, "LeftButton")
		M.cursor = { toX, 500 }
		EM.frame.scripts.OnUpdate(EM.frame, 0.01)
		local guide = EM.frame.vGuide.shown
		target.scripts.OnMouseUp(target, "LeftButton")
		return guide
	end
	s.snapPanels, s.snapGrid = false, true
	dragMover(m, 1000, 1005)
	check(test.anchor.x == 4 and test.anchor.y == 2 and EM.selected == testId, "moved and snapped to the grid")
	test.anchor.x, test.anchor.y = 0, 0
	dragMover(m, 1000, 1010)
	check(test.anchor.x == 10 and test.anchor.y == 2, "far from a grid line: free move (smooth), not steps")
	EM:Undo()
	M.ctrl = true
	EM.frame.scripts.OnKeyDown(EM.frame, "Z")
	M.ctrl = false
	check(test.anchor.x == 0 and test.anchor.y == 0, "Ctrl+Z undoes the move")
	EM.frame.scripts.OnKeyDown(EM.frame, "RIGHT")
	M.shift = true
	EM.frame.scripts.OnKeyDown(EM.frame, "UP")
	M.shift = false
	check(test.anchor.x == 1 and test.anchor.y == 10, "arrow keys, Shift for a bigger step")
	test.anchor.x, test.anchor.y = 0, 0
	s.snapPanels, s.snapGrid = true, false
	local guide = dragMover(m, 1000, 1005)
	check(test.anchor.x == 0 and guide, "snapped to the screen center, guide shown")
	M.shift = true
	dragMover(m, 1000, 1005)
	M.shift = false
	check(test.anchor.x == 5, "Shift: no snapping")
	test.anchor.x = 0
	s.snapPanels = false
	dragMover(m.handles[6], 1060, 1090)
	check(test.width == 230 and test.anchor.x == 15, "resized by the right edge, centered panel follows")
	ns.Layouts:ApplyActive()
	check(EM.movers[testId] and EM.movers[testId].target == ns.Layouts.frames[testId], "movers rebuilt with the layout")
	-- Several panels: Ctrl+click, alignment, moved together
	testFrame = ns.Layouts.frames[testId]
	local chatFrame = ns.Layouts.frames[chatId]
	test.anchor.x, test.anchor.y = 0, 0
	testFrame.rect = { 860, 490, 200, 100 }
	chatFrame.rect = { 100, 60, 321, 150 }
	EM:Select(testId)
	M.ctrl = true
	EM.movers[chatId].scripts.OnMouseDown(EM.movers[chatId], "LeftButton")
	M.ctrl = false
	check(EM.selection[testId] and EM.selection[chatId] and EM.selected == chatId and EM.frame.bar.align.shown, "Ctrl+click adds to the selection")
	EM:Align("LEFT")
	check(test.anchor.x == -760, "aligned on the main panel")
	EM:Undo()
	check(test.anchor.x == 0, "alignment undone")
	local chatX = chatPanel.anchor.x
	M.cursor = { 900, 520 }
	EM.movers[testId].scripts.OnMouseDown(EM.movers[testId], "LeftButton")
	M.cursor = { 930, 520 }
	M.shift = true
	EM.frame.scripts.OnUpdate(EM.frame, 0.01)
	M.shift = false
	EM.movers[testId].scripts.OnMouseUp(EM.movers[testId], "LeftButton")
	check(test.anchor.x == 30 and chatPanel.anchor.x == chatX + 30, "the selection moves together")
	EM:Undo()
	check(test.anchor.x == 0 and chatPanel.anchor.x == chatX, "group move undone")
	EM:Select(testId)
	EM.frame.scripts.OnKeyDown(EM.frame, "ESCAPE")
	check(EM.active and EM.selected == nil, "Escape deselects")
	EM.frame.scripts.OnKeyDown(EM.frame, "ESCAPE")
	check(not EM.active and Options.frame.shown, "Escape leaves, the window comes back")
	EM:Start()
	M.Fire("PLAYER_REGEN_DISABLED")
	check(not EM.active, "edit mode left when a fight starts")
	M.combat = true
	EM:Start()
	check(not EM.active, "no edit mode in combat")
	M.combat = false
	EM:Start(testId)
	local mover = EM.movers[testId]
	mover.scripts.OnClick(mover, "RightButton")
	check(not EM.active and Options.current == "panels" and P.selected == testId, "right-click opens the panel settings")

	-- Every language has the same texts
	local keys = {}
	for _, locale in ipairs({ "enUS", "frFR", "zhCN", "zhTW" }) do
		local set, n = {}, 0
		for line in io.lines("nxPanels/Locales/" .. locale .. ".lua") do
			local key = line:match('^L%["([%w_]+)"%]')
			if key then set[key] = true n = n + 1 end
		end
		keys[locale] = set
		check(n == count(keys.enUS), "same number of texts in " .. locale)
	end
	for key in pairs(keys.enUS) do
		check(keys.frFR[key] and keys.zhCN[key] and keys.zhTW[key], "text " .. key .. " translated")
	end

elseif scenario == "original" then
	check(#M.loadCalls == 0, "bridge not loaded when the original kgPanels is present")
	check(db.global.migration.source == "kgPanels", "imported from the original kgPanels")
	check(count(db.global.layouts) == 2, "layouts imported")
	check(M.disabled.kgPanels, "original addon disabled")
	check(M.popups[1] == "NXPANELS_MIGRATED", "reload popup shown")

elseif scenario == "handinstall" then
	check(#M.loadCalls == 0, "running legacy addon read without loading anything")
	check(db.global.migration.source == "kgPanels_Reloaded", "imported from the running kgPanels Reloaded")
	check(count(db.global.layouts) == 2, "layouts imported")
	check(deepEqual(kgPanelsDB, fixture()), "legacy data left untouched")
	check(M.disabled.kgPanels_Reloaded and M.disabled.kgPanelsConfig_Reloaded, "legacy addons disabled")
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

	-- The editor opens every real panel on every tab, the edit mode every layout
	local O = loadOptions()
	local P = O.PanelsPage
	local activeBefore = ns.Layouts.activeId
	ns.Options:Show("panels")
	local opened, failed = 0, 0
	for _, entry in ipairs(ns.Database:SortedLayouts()) do
		ns.Layouts:Activate(entry.id)
		for panelId in pairs(entry.layout.panels) do
			for _, tab in ipairs({ "general", "background", "border", "text", "display", "scripts" }) do
				P.tab = tab
				local ok, err = pcall(P.Select, P, panelId)
				opened = opened + 1
				if not ok then
					failed = failed + 1
					if failed <= 5 then print("  editor error: " .. tostring(err)) end
				end
			end
		end
		local ok, err = pcall(O.EditMode.Start, O.EditMode)
		check(ok and O.EditMode.active, "edit mode on " .. entry.layout.name .. ": " .. tostring(err))
		O.EditMode:Stop()
	end
	print(("  editor opened %d times"):format(opened))
	check(failed == 0, "editor works on every real panel")
	ns.Layouts:Activate(activeBefore)
end

for _, line in ipairs(M.printed) do
	if line:find("rror") then print("  chat: " .. line) end
end
print(("  %d checks, %d failed"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
