local _, ns = ...

--[[
Border renderer (replaces LibBackdrop and BackdropTemplate).

It reads the classic "edge file" format used by Blizzard and SharedMedia borders:
the texture holds 8 square segments side by side, 1/8 of the width each:
	0 LEFT, 1 RIGHT, 2 TOP, 3 BOTTOM, 4 TOPLEFT, 5 TOPRIGHT, 6 BOTTOMLEFT, 7 BOTTOMRIGHT
TOP and BOTTOM are stored vertically and drawn rotated. Sides repeat along
their length, drawn inside the frame like the legacy backdrop.

Texture coordinates and repeat counts are the ones of Blizzard's BackdropTemplate,
so borders look exactly as before (to the pixel): each segment is cropped by 1/128
on its sides and 1/16 at its ends.
]]
local Border = {}
ns.Border = Border

local SEGMENT = 1 / 8
local CROP_X = 1 / 128
local CROP_START = 0.0625
local CROP_END = 1 - CROP_START

-- Horizontal coordinates of a segment, cropped like the backdrop
local function segment(index)
	return index * SEGMENT + CROP_X, (index + 1) * SEGMENT - CROP_X
end
local SECTIONS = {
	LEFT = 0, RIGHT = 1, TOP = 2, BOT = 3,
	TOPLEFTCORNER = 4, TOPRIGHTCORNER = 5, BOTLEFTCORNER = 6, BOTRIGHTCORNER = 7,
}
Border.SECTIONS = SECTIONS

function Border:Create(frame)
	local textures = {}
	for section in pairs(SECTIONS) do
		textures[section] = frame:CreateTexture(nil, "BORDER")
	end
	frame.border = { textures = textures, size = 0 }
end

function Border:Hide(frame)
	for _, tex in pairs(frame.border.textures) do
		tex:Hide()
	end
	frame.border.size = 0
end

function Border:Apply(frame, file, size, color, hidden)
	if not file or not size or size <= 0 then
		self:Hide(frame)
		return
	end
	local b, t = frame.border, frame.border.textures
	b.size = size

	for section, index in pairs(SECTIONS) do
		local tex = t[section]
		tex:ClearAllPoints()
		if index >= 4 then
			tex:SetTexture(file, "CLAMP", "CLAMP")
			tex:SetSize(size, size)
			local x1, x2 = segment(index)
			tex:SetTexCoord(x1, x2, CROP_START, CROP_END)
		else
			tex:SetTexture(file, "CLAMP", "REPEAT")
		end
		tex:SetVertexColor(color.r, color.g, color.b, color.a)
		tex:SetShown(not (hidden and hidden[section]))
	end

	t.TOPLEFTCORNER:SetPoint("TOPLEFT", frame, "TOPLEFT")
	t.TOPRIGHTCORNER:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	t.BOTLEFTCORNER:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	t.BOTRIGHTCORNER:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

	t.LEFT:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -size)
	t.LEFT:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, size)
	t.LEFT:SetWidth(size)
	t.RIGHT:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -size)
	t.RIGHT:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, size)
	t.RIGHT:SetWidth(size)
	t.TOP:SetPoint("TOPLEFT", frame, "TOPLEFT", size, 0)
	t.TOP:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -size, 0)
	t.TOP:SetHeight(size)
	t.BOT:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", size, 0)
	t.BOT:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -size, 0)
	t.BOT:SetHeight(size)

	self:UpdateCoords(frame)
end

-- Side texture coordinates depend on the frame size (repeat count). Same formula as
-- the backdrop, effective scale included.
function Border:UpdateCoords(frame)
	local b = frame.border
	local size = b.size
	if not size or size <= 0 then return end
	local t = b.textures
	local width, height = frame:GetSize()
	local scale = frame:GetEffectiveScale()
	local hRepeat = math.max(0, width / size * scale - 2 - CROP_START)
	local vRepeat = math.max(0, height / size * scale - 2 - CROP_START)

	-- ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
	local x1, x2 = segment(SECTIONS.LEFT)
	t.LEFT:SetTexCoord(x1, CROP_START, x1, vRepeat, x2, CROP_START, x2, vRepeat)
	x1, x2 = segment(SECTIONS.RIGHT)
	t.RIGHT:SetTexCoord(x1, CROP_START, x1, vRepeat, x2, CROP_START, x2, vRepeat)

	-- Rotated
	x1, x2 = segment(SECTIONS.TOP)
	t.TOP:SetTexCoord(x1, hRepeat, x2, hRepeat, x1, CROP_START, x2, CROP_START)
	x1, x2 = segment(SECTIONS.BOT)
	t.BOT:SetTexCoord(x1, hRepeat, x2, hRepeat, x1, CROP_START, x2, CROP_START)
end
