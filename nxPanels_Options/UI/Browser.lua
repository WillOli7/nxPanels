local _, O = ...
local T, W = O.Theme, O.Widgets
local C = T.colors
local L = O.L
local core = O.core

--[[
Texture browser: a grid of thumbnails instead of a list of names.
	Browser:Open(kind, current, onSelect)   kind = "background" | "border"
Backgrounds have a second tab with the Blizzard atlases (images of the game,
available to every player without any file).
]]
local Browser = {}
O.Browser = Browser

local WIDTH, HEIGHT = 760, 560
local CELL_W, CELL_H, GAP = 132, 104, 8

--[[
Decorative atlases of the game. The list is checked when it is shown: names
missing from the client are left out, so it works on every client version.
Any other atlas can be typed by name.
]]
Browser.ATLASES = {
	"auctionhouse-background-index", "auctionhouse-background-buy-commodities-market",
	"auctionhouse-background-summarylist", "auctionhouse-background-sell-left",
	"QuestBG-Parchment", "QuestBG-Alliance", "QuestBG-Horde", "QuestBG-ExilesReach",
	"GarrMission_MissionParchment", "GarrMission_RewardsBanner", "GarrLanding-SideToast-BG",
	"ChallengeMode-guild-background", "ChallengeMode-TimerBG", "ChallengeMode-TimerBG-back",
	"loottoast-bg-questrewardupgraded", "LootToast-MoreAwesome", "Toast-IconBG",
	"legionmission-landingpage-background", "UI-Frame-DiamondMetal-Header",
	"UI-HUD-UnitFrame-Player-PortraitOn", "UI-HUD-UnitFrame-Target-PortraitOn",
	"UI-HUD-UnitFrame-Player-PortraitOff", "UI-HUD-ActionBar-IconFrame",
	"UI-HUD-ActionBar-IconFrame-Border", "UI-HUD-MicroMenu-Highlightalert",
	"talents-background-warrior-arms", "talents-background-warrior-fury", "talents-background-warrior-protection",
	"talents-background-paladin-holy", "talents-background-paladin-protection", "talents-background-paladin-retribution",
	"talents-background-hunter-beastmastery", "talents-background-hunter-marksmanship", "talents-background-hunter-survival",
	"talents-background-rogue-assassination", "talents-background-rogue-outlaw", "talents-background-rogue-subtlety",
	"talents-background-priest-discipline", "talents-background-priest-holy", "talents-background-priest-shadow",
	"talents-background-deathknight-blood", "talents-background-deathknight-frost", "talents-background-deathknight-unholy",
	"talents-background-shaman-elemental", "talents-background-shaman-enhancement", "talents-background-shaman-restoration",
	"talents-background-mage-arcane", "talents-background-mage-fire", "talents-background-mage-frost",
	"talents-background-warlock-affliction", "talents-background-warlock-demonology", "talents-background-warlock-destruction",
	"talents-background-monk-brewmaster", "talents-background-monk-mistweaver", "talents-background-monk-windwalker",
	"talents-background-druid-balance", "talents-background-druid-feral", "talents-background-druid-guardian",
	"talents-background-druid-restoration", "talents-background-demonhunter-havoc", "talents-background-demonhunter-vengeance",
	"talents-background-evoker-devastation", "talents-background-evoker-preservation", "talents-background-evoker-augmentation",
	"dragonriding_vigor_background", "dragonflight-landingpage-background", "Dragonflight-Landingpage-BG",
	"covenantchoice-celebration-background", "Adventures-Missions-BG-01", "Adventures-Missions-BG-02",
	"collections-background-tile", "PetJournal-ListBG", "parchmentpopup-background",
	"CovenantSanctum-Renown-Background-Kyrian", "CovenantSanctum-Renown-Background-Venthyr",
	"CovenantSanctum-Renown-Background-NightFae", "CovenantSanctum-Renown-Background-Necrolord",
	"housing-dashboard-background", "delves-dashboard-background", "Professions-Specializations-Background",
}

local function atlasExists(name)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

function Browser:AtlasItems()
	local items = {}
	for _, name in ipairs(self.ATLASES) do
		if atlasExists(name) then
			items[#items + 1] = { value = "atlas:" .. name, text = name, atlas = name }
		end
	end
	return items
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local cells = {}

local function cell(i)
	local c = cells[i]
	if c then return c end
	local f = Browser.frame
	c = CreateFrame("Button", nil, f.scroll.content)
	c:SetSize(CELL_W, CELL_H)
	c.bg = T:Fill(c, C.card)
	c.edges = T:Border(c, C.line)
	c.preview = CreateFrame("Frame", nil, c)
	c.preview:SetPoint("TOPLEFT", 6, -6)
	c.preview:SetPoint("TOPRIGHT", -6, -6)
	c.preview:SetHeight(CELL_H - 34)
	T:Fill(c.preview, C.input)
	c.tex = c.preview:CreateTexture(nil, "ARTWORK")
	c.tex:SetPoint("TOPLEFT", 2, -2)
	c.tex:SetPoint("BOTTOMRIGHT", -2, 2)
	core.Border:Create(c.preview)
	c.label = T:Text(c, T.fonts.small, C.textDim, "CENTER")
	c.label:SetPoint("BOTTOMLEFT", 4, 8)
	c.label:SetPoint("BOTTOMRIGHT", -4, 8)
	c:SetScript("OnEnter", function(self)
		self.bg:SetVertexColor(unpack(C.cardHover))
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.item.text, 1, 1, 1)
		GameTooltip:Show()
	end)
	c:SetScript("OnLeave", function(self)
		self.bg:SetVertexColor(unpack(C.card))
		GameTooltip:Hide()
	end)
	c:SetScript("OnClick", function(self) Browser:Choose(self.item.value) end)
	cells[i] = c
	return c
end

local function draw(c, item, kind)
	c.tex:Hide()
	core.Border:Hide(c.preview)
	if item.atlas then
		c.tex:SetTexCoord(0, 1, 0, 1)
		c.tex:SetAtlas(item.atlas)
		c.tex:Show()
	elseif kind == "border" and item.border then
		core.Border:Apply(c.preview, item.border, 14, { r = 1, g = 1, b = 1, a = 1 })
	elseif item.texture then
		c.tex:SetTexCoord(0, 1, 0, 1)
		c.tex:SetTexture(item.texture)
		c.tex:SetVertexColor(1, 1, 1, 1)
		c.tex:Show()
	end
end

function Browser:Fill()
	local f = self.frame
	if self.kind == "icon" then return self:FillIcons() end
	local filter = strtrim(f.search.edit:GetText() or ""):lower()
	f.placeholder:SetShown(filter == "")
	local items = self.tab == "atlas" and self:AtlasItems() or O.Options:MediaItems(self.kind)
	local columns = math.max(1, math.floor((WIDTH - 40 + GAP) / (CELL_W + GAP)))
	local shown = 0
	for _, item in ipairs(items) do
		if filter == "" or tostring(item.text):lower():find(filter, 1, true) then
			shown = shown + 1
			local c = cell(shown)
			c.item = item
			local col, row = (shown - 1) % columns, math.floor((shown - 1) / columns)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", col * (CELL_W + GAP), -row * (CELL_H + GAP))
			c.label:SetText(item.text)
			T:SetBorderColor(c.edges, item.value == self.current and C.accent or C.line)
			draw(c, item, self.kind)
			c:Show()
		end
	end
	for i = shown + 1, #cells do cells[i]:Hide() end
	f.empty:SetShown(shown == 0)
	f.scroll:SetContentHeight(math.ceil(shown / columns) * (CELL_H + GAP))
	f.atlasRow:SetShown(self.tab == "atlas")
	f.count:SetText(self.tab == "atlas" and L["ATLAS_COUNT"]:format(shown) or "")
end

function Browser:Choose(value)
	local onSelect = self.onSelect
	self:Close()
	if onSelect then onSelect(value) end
end

function Browser:Close()
	if self.frame then self.frame:Hide() end
end

local function create()
	local f = CreateFrame("Frame", "nxPanelsBrowser", UIParent)
	f:SetSize(WIDTH, HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	T:Fill(f, C.window)
	T:Border(f, C.accent)
	tinsert(UISpecialFrames, "nxPanelsBrowser")
	Browser.frame = f

	f.title = T:Text(f, T.fonts.header, C.text)
	f.title:SetPoint("TOPLEFT", 20, -18)
	local close = W.Button(f, "X", 28, "ghost", function() Browser:Close() end)
	close:SetPoint("TOPRIGHT", -12, -12)

	f.tabs = W.Tabs(f, {
		{ key = "media", text = L["BROWSER_MEDIA"] },
		{ key = "atlas", text = L["BROWSER_ATLAS"] },
	}, function(key)
		Browser.tab = key
		if f.scroll then Browser:Fill() end
	end)
	f.tabs:SetPoint("TOPLEFT", 20, -44)
	f.tabs:SetPoint("TOPRIGHT", -20, -44)

	f.search = W.EditBox(f, 260, 24)
	f.search:SetPoint("TOPLEFT", 20, -90)
	f.placeholder = T:Text(f.search, T.fonts.normal, C.textMuted)
	f.placeholder:SetPoint("LEFT", 8, 0)
	f.placeholder:SetText(L["SEARCH"])
	f.search.edit:SetScript("OnTextChanged", function() Browser:Fill() end)
	f.count = T:Text(f, T.fonts.small, C.textMuted, "RIGHT")
	f.count:SetPoint("TOPRIGHT", -20, -96)

	-- Any atlas by name (the list only holds a selection)
	local atlasRow = CreateFrame("Frame", nil, f)
	atlasRow:SetPoint("TOPLEFT", 20, -122)
	atlasRow:SetPoint("TOPRIGHT", -20, -122)
	atlasRow:SetHeight(28)
	local atlasLabel = T:Text(atlasRow, T.fonts.normal, C.textDim)
	atlasLabel:SetPoint("LEFT")
	atlasLabel:SetText(L["ATLAS_NAME"])
	f.atlasBox = W.EditBox(atlasRow, 300, 24)
	f.atlasBox:SetPoint("LEFT", atlasLabel, "RIGHT", 10, 0)
	f.atlasStatus = T:Text(atlasRow, T.fonts.small, C.textMuted)
	local use = W.Button(atlasRow, L["ATLAS_USE"], 110, "primary", function()
		local name = strtrim(f.atlasBox.edit:GetText() or "")
		if atlasExists(name) then Browser:Choose("atlas:" .. name) end
	end)
	use:SetPoint("LEFT", f.atlasBox, "RIGHT", 8, 0)
	f.atlasStatus:SetPoint("LEFT", use, "RIGHT", 10, 0)
	f.atlasBox.edit:SetScript("OnTextChanged", function(self)
		local name = strtrim(self:GetText() or "")
		local ok = name ~= "" and atlasExists(name)
		use:SetEnabledState(ok)
		f.atlasStatus:SetText(name == "" and "" or ok and L["ATLAS_FOUND"] or L["ATLAS_UNKNOWN"])
		f.atlasStatus:SetTextColor(unpack(ok and C.success or C.danger))
	end)
	f.atlasRow = atlasRow

	f.scroll = W.Scroll(f)
	f.scroll:SetPoint("TOPLEFT", 20, -160)
	f.scroll:SetPoint("BOTTOMRIGHT", -16, 16)
	f.empty = T:Text(f.scroll.content, T.fonts.normal, C.textDim)
	f.empty:SetPoint("TOPLEFT", 4, -8)
	f.empty:SetText(L["BROWSER_EMPTY"])
	f.scroll:HookScript("OnMouseWheel", function()
		if Browser.kind == "icon" then Browser:FillIcons() end
	end)
	f:SetScript("OnHide", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- Every icon of the game (the list used for the macro icons): thousands of
-- them, so only the visible cells exist and are moved while scrolling
---------------------------------------------------------------------------
local ICON, ICON_GAP = 40, 4
local iconCells = {}

function Browser:GameIcons()
	if self.icons then return self.icons end
	local list = {}
	-- By name: a function missing on a client must not stop the others
	for _, name in ipairs({ "GetLooseMacroIcons", "GetMacroIcons", "GetLooseMacroItemIcons", "GetMacroItemIcons" }) do
		local fill = _G[name]
		if fill then pcall(fill, list) end
	end
	-- Older clients give texture names instead of file ids
	for i, icon in ipairs(list) do
		if type(icon) == "string" and not icon:find("\\") then list[i] = "Interface\\Icons\\" .. icon end
	end
	self.icons = list
	return list
end

local function iconCell(i)
	local c = iconCells[i]
	if c then return c end
	c = CreateFrame("Button", nil, Browser.frame.scroll.content)
	c:SetSize(ICON, ICON)
	c.tex = c:CreateTexture(nil, "ARTWORK")
	c.tex:SetAllPoints(c)
	c.edges = T:Border(c, C.line)
	c:SetScript("OnEnter", function(self) T:SetBorderColor(self.edges, C.accent) end)
	c:SetScript("OnLeave", function(self) T:SetBorderColor(self.edges, C.line) end)
	c:SetScript("OnClick", function(self) Browser:Choose(self.icon) end)
	iconCells[i] = c
	return c
end

function Browser:FillIcons()
	local f = self.frame
	local icons = self:GameIcons()
	local step = ICON + ICON_GAP
	local columns = math.max(1, math.floor((f.scroll:GetWidth() - 8 + ICON_GAP) / step))
	local rows = math.ceil(#icons / columns)
	f.scroll:SetContentHeight(rows * step)
	local first = math.floor(f.scroll:GetVerticalScroll() / step)
	local visibleRows = math.ceil(f.scroll:GetHeight() / step) + 1
	local n = 0
	for row = first, math.min(rows - 1, first + visibleRows) do
		for col = 0, columns - 1 do
			local index = row * columns + col + 1
			local icon = icons[index]
			if icon then
				n = n + 1
				local c = iconCell(n)
				c.icon = icon
				c.tex:SetTexture(icon)
				c:ClearAllPoints()
				c:SetPoint("TOPLEFT", col * step, -row * step)
				c:Show()
			end
		end
	end
	for i = n + 1, #iconCells do iconCells[i]:Hide() end
	f.empty:SetShown(#icons == 0)
	f.count:SetText(L["ICON_COUNT"]:format(#icons))
end

-- Opens the browser; onSelect(value) receives the chosen texture key
function Browser:Open(kind, current, onSelect)
	if not self.frame then create() end
	local f = self.frame
	self.kind, self.current, self.onSelect = kind, current, onSelect
	-- Icons: one grid, no tabs nor search (icons have no name)
	local icons = kind == "icon"
	f.tabs:SetShown(not icons)
	f.search:SetShown(not icons)
	f.scroll:ClearAllPoints()
	f.scroll:SetPoint("TOPLEFT", 20, icons and -56 or -160)
	f.scroll:SetPoint("BOTTOMRIGHT", -16, 16)
	for _, c in ipairs(cells) do c:Hide() end
	for _, c in ipairs(iconCells) do c:Hide() end
	if icons then
		f.title:SetText(L["BROWSER_TITLE_ICON"])
		f.atlasRow:Hide()
		f.count:ClearAllPoints()
		f.count:SetPoint("TOPRIGHT", -56, -22)
		f.scroll:SetVerticalScroll(0)
		f:Show()
		self:FillIcons()
		return
	end
	f.count:ClearAllPoints()
	f.count:SetPoint("TOPRIGHT", -20, -96)
	f.title:SetText(kind == "border" and L["BROWSER_TITLE_BORDER"] or L["BROWSER_TITLE_BACKGROUND"])
	-- Borders have no atlas tab (an atlas is not an edge file)
	f.tabs.buttons[2]:SetShown(kind ~= "border")
	local isAtlas = type(current) == "string" and current:find("^atlas:") ~= nil
	f.search.edit:SetText("")
	f.atlasBox.edit:SetText(isAtlas and current:sub(7) or "")
	f.scroll:SetVerticalScroll(0)
	f:Show()
	f.tabs:Select((isAtlas and kind ~= "border") and "atlas" or "media")
end
