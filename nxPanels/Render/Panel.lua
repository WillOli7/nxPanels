local _, ns = ...

-- Creates, recycles and draws the panel frames
local Panel = {}
ns.Panel = Panel

local pool = {}
local ownKeys = setmetatable({}, { __mode = "k" })   -- [frame] = keys set by nxPanels

---------------------------------------------------------------------------
-- Texture coordinates: rotation (cached per degree) and flips
---------------------------------------------------------------------------
local rotations = setmetatable({}, {
	__index = function(cache, degrees)
		local rad = math.rad(degrees)
		local A, B = math.cos(rad), math.sin(rad)
		-- Rotate each corner (UL, LL, UR, LR) around the center of the texture
		local coords = {}
		for i, corner in ipairs({ { 0, 0 }, { 0, 1 }, { 1, 0 }, { 1, 1 } }) do
			local dx, dy = corner[1] - 0.5, corner[2] - 0.5
			coords[i * 2 - 1] = 0.5 + dx * A - dy * B
			coords[i * 2] = 0.5 + dx * B + dy * A
		end
		cache[degrees] = coords
		return coords
	end,
})

local function texCoords(bg)
	local c
	if bg.texCoord then
		c = { unpack(bg.texCoord) }
	else
		c = { unpack(rotations[math.floor(bg.rotation or 0) % 360]) }
	end
	-- c = ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
	if bg.flipH then
		c = { c[5], c[6], c[7], c[8], c[1], c[2], c[3], c[4] }
	end
	if bg.flipV then
		c = { c[3], c[4], c[1], c[2], c[7], c[8], c[5], c[6] }
	end
	return c
end

---------------------------------------------------------------------------
-- Pool
---------------------------------------------------------------------------
local function onSizeChanged(sizer)
	local frame = sizer:GetParent()
	ns.Border:UpdateCoords(frame)
	Panel:UpdateTiling(frame)
end

function Panel:Acquire(panelId)
	local frame = table.remove(pool)
	if not frame then
		frame = CreateFrame("Frame", nil, UIParent)
		frame.bg = frame:CreateTexture(nil, "BACKGROUND")
		frame.text = frame:CreateFontString(nil, "OVERLAY")
		ns.Border:Create(frame)
		-- Internal child: follows the panel size without using the panel's own
		-- OnSizeChanged script, which belongs to the user scripts (RESIZE)
		frame.sizer = CreateFrame("Frame", nil, frame)
		frame.sizer:SetAllPoints(frame)
		frame.sizer:SetScript("OnSizeChanged", onSizeChanged)
		-- Keys of a new frame: everything else was added by the panel scripts
		local keys = {}
		for key in pairs(frame) do keys[key] = true end
		keys.panelId, keys.tileSize, keys.textTemplate, keys.nxManaged = true, true, true, true
		ownKeys[frame] = keys
	end
	frame.panelId = panelId
	-- Stable global name, so other addons and scripts can anchor to a panel
	_G["nxPanel_" .. panelId] = frame
	return frame
end

function Panel:Release(frame)
	frame:Hide()
	frame:EnableMouse(false)
	frame:ClearAllPoints()
	frame:SetParent(UIParent)
	ns.TextVars:Set(frame, "")
	ns.Visibility:Forget(frame)
	if frame.panelId and _G["nxPanel_" .. frame.panelId] == frame then
		_G["nxPanel_" .. frame.panelId] = nil
	end
	frame.panelId = nil
	frame.tileSize = nil
	-- Values stored by the scripts (self.done = true...) must not follow the
	-- frame to another panel
	local keys = ownKeys[frame]
	if keys then
		for key in pairs(frame) do
			if not keys[key] then frame[key] = nil end
		end
	end
	pool[#pool + 1] = frame
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
-- Size and position only (cheap: used while dragging in edit mode)
function Panel:ApplyGeometry(frame, panel, parent, anchor)
	if frame:GetParent() ~= parent then frame:SetParent(parent) end
	local scale = panel.scale and panel.scale > 0 and panel.scale or 1
	frame:SetScale(scale)

	local width = panel.widthUnit == "%" and parent:GetWidth() * panel.width / 100 or panel.width
	local height = panel.heightUnit == "%" and parent:GetHeight() * panel.height / 100 or panel.height
	frame:SetSize(math.max(width, 0), math.max(height, 0))

	local a = panel.anchor
	frame:ClearAllPoints()
	frame:SetPoint(a.point, anchor, a.relativePoint, a.x / scale, a.y / scale)
end

function Panel:Apply(frame, panel, parent, anchor)
	self:ApplyGeometry(frame, panel, parent, anchor)
	frame:SetFrameStrata(panel.strata)
	frame:SetFrameLevel(math.max(0, panel.level))
	frame:EnableMouse(panel.mouse)

	self:ApplyBackground(frame, panel)
	self:ApplyBorder(frame, panel)
	self:ApplyText(frame, panel)
end

-- Colors only (automatic colors changed: target, ...)
function Panel:ApplyColors(frame, panel)
	self:ApplyBackground(frame, panel)
	self:ApplyBorder(frame, panel)
end

function Panel:ApplyBorder(frame, panel)
	local border = panel.border
	local r, g, b, a = ns.Colors:Get(border.colorMode, border.color)
	ns.Border:Apply(frame, ns.Media:Fetch("border", border.texture, frame.panelId), border.size,
		{ r = r, g = g, b = b, a = a }, border.hidden)
end

-- Blizzard atlas of a texture key "atlas:<name>": file and texture rectangle
local function atlasOf(key)
	local name = type(key) == "string" and key:match("^atlas:(.+)$")
	if not name then return end
	local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
	if not info then return false end
	return info.file or info.filename, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
end

function Panel:ApplyBackground(frame, panel)
	local bg, tex = panel.background, frame.bg
	local insets = bg.insets
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", frame, "TOPLEFT", insets.left, -insets.top)
	tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insets.right, insets.bottom)

	local atlasFile, left, right, top, bottom = atlasOf(bg.texture)
	local path
	if atlasFile ~= nil then
		path = atlasFile or nil
	else
		path = ns.Media:Fetch("background", bg.texture, frame.panelId)
	end
	frame.tileSize = nil
	if not path then
		tex:Hide()
		return
	end
	tex:Show()
	tex:SetDrawLayer("BACKGROUND", bg.subLevel)
	tex:SetBlendMode(bg.blend)
	tex:SetAlpha(bg.alpha)

	local r, g, b, a = ns.Colors:Get(bg.colorMode, bg.color)
	local c2 = bg.color2
	-- An atlas is a part of a bigger sheet: it cannot be repeated
	if bg.tile and not atlasFile then
		tex:SetTexture(path, "REPEAT", "REPEAT")
		tex:SetVertexColor(r, g, b, a)
		frame.tileSize = bg.tileSize
		self:UpdateTiling(frame)
		return
	end

	tex:SetTexture(path)
	tex:SetHorizTile(false)
	tex:SetVertTile(false)
	-- The color alpha never exceeds the background opacity (legacy behavior)
	if bg.style == "SOLID" then
		tex:SetVertexColor(r, g, b, math.min(a, bg.alpha))
	elseif bg.style == "GRADIENT" then
		tex:SetGradient(bg.orientation,
			CreateColor(r, g, b, math.min(a, bg.alpha)),
			CreateColor(c2.r, c2.g, c2.b, math.min(c2.a, bg.alpha)))
	else
		tex:SetVertexColor(1, 1, 1, 1)
	end
	local c = texCoords(bg)
	if atlasFile then
		-- Rotation and flips inside the rectangle of the atlas
		for i = 1, 8, 2 do
			c[i] = left + c[i] * (right - left)
			c[i + 1] = top + c[i + 1] * (bottom - top)
		end
	end
	tex:SetTexCoord(unpack(c))
end

-- Tiled backgrounds: fixed tile size, or the texture's own size when 0
function Panel:UpdateTiling(frame)
	local tileSize = frame.tileSize
	if not tileSize then return end
	local tex = frame.bg
	if tileSize > 0 then
		tex:SetHorizTile(false)
		tex:SetVertTile(false)
		local width, height = tex:GetSize()
		tex:SetTexCoord(0, width / tileSize, 0, height / tileSize)
	else
		tex:SetTexCoord(0, 1, 0, 1)
		tex:SetHorizTile(true)
		tex:SetVertTile(true)
	end
end

function Panel:ApplyText(frame, panel)
	local t, fs = panel.text, frame.text
	local font = ns.Media:FetchFont(t.font, frame.panelId)
	if not fs:SetFont(font, t.size, t.outline) then
		fs:SetFont(ns.Media:DefaultFont(), t.size, t.outline)
	end
	fs:ClearAllPoints()
	fs:SetPoint("CENTER", frame.bg, "CENTER", t.x, t.y)
	fs:SetJustifyH(t.justifyH)
	fs:SetJustifyV(t.justifyV)
	fs:SetTextColor(t.color.r, t.color.g, t.color.b, t.color.a)
	-- "||" is how the legacy editor stored a single "|" (color and texture codes).
	-- {zone}, {time}... are replaced and kept up to date by TextVars
	ns.TextVars:Set(frame, (t.value:gsub("||", "|")))
end
