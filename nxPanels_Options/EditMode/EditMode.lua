local _, O = ...
local T, W, Options = O.Theme, O.Widgets, O.Options
local C = T.colors
local L = O.L
local core = O.core

--[[
Edit mode: the panels of the active layout are moved and resized with the mouse.
- Drag a panel to move it, drag an edge or a corner to resize it.
- Snapping: grid, screen edges and center, edges and centers of the other panels
  (alignment guides show where it snapped). Shift while dragging: no snapping.
- Arrow keys move the selected panel (Shift: bigger step), Ctrl+Z undoes,
  Escape deselects then leaves.
All the geometry is computed in UIParent units, then converted to the units of
the panel data (offsets in parent units, size in the panel's own units or %).
]]
local EditMode = {}
O.EditMode = EditMode

local movers = {}       -- [panelId] = mover
EditMode.movers = movers
local undoStack = {}
local UNDO_MAX = 50
local HANDLE = 10
local MIN_SIZE = 4

local function S() return core.db.global.editMode end
local function accentAlpha(a) return { C.accent[1], C.accent[2], C.accent[3], a } end

local function activeLayout()
	return core.Database:GetLayout(core.Layouts.activeId)
end

local function panelOf(id)
	local layout = activeLayout()
	return layout and layout.panels[id]
end

local function uiScale() return UIParent:GetEffectiveScale() end

local function cursor()
	local x, y = GetCursorPosition()
	local s = uiScale()
	return x / s, y / s
end

-- Rectangle of a frame in UIParent units: left, bottom, right, top
local function rect(frame)
	local l, b, w, h = frame:GetRect()
	if not l then return end
	local s = frame:GetEffectiveScale() / uiScale()
	return l * s, b * s, (l + w) * s, (b + h) * s
end

local function round(v)
	return math.floor(v * 10 + 0.5) / 10
end

-- Horizontal and vertical part of an anchor point
local function hPart(point)
	if point:find("LEFT") then return "LEFT" end
	if point:find("RIGHT") then return "RIGHT" end
	return "CENTER"
end
local function vPart(point)
	if point:find("TOP") then return "TOP" end
	if point:find("BOTTOM") then return "BOTTOM" end
	return "CENTER"
end

---------------------------------------------------------------------------
-- Undo: each entry is a list of panel snapshots, restored together
---------------------------------------------------------------------------
local function snapshot(id)
	local p = panelOf(id)
	return p and { id = id, x = p.anchor.x, y = p.anchor.y, width = p.width, height = p.height }
end

local function snapshots(ids)
	local list = {}
	for _, id in ipairs(ids) do list[#list + 1] = snapshot(id) end
	return list
end

local function changedSince(list)
	for _, before in ipairs(list) do
		local p = panelOf(before.id)
		if p and (p.anchor.x ~= before.x or p.anchor.y ~= before.y or p.width ~= before.width or p.height ~= before.height) then
			return true
		end
	end
	return false
end

local function pushUndo(list)
	undoStack[#undoStack + 1] = list
	if #undoStack > UNDO_MAX then table.remove(undoStack, 1) end
end

function EditMode:Undo()
	local list = table.remove(undoStack)
	if not list then return end
	for _, entry in ipairs(list) do
		local p = panelOf(entry.id)
		if p then
			p.anchor.x, p.anchor.y, p.width, p.height = entry.x, entry.y, entry.width, entry.height
			core.Layouts:PanelChanged(entry.id, "look")
		end
	end
	self:RefreshInfo()
end

---------------------------------------------------------------------------
-- Selection: EditMode.selection = { [id] = true }; EditMode.selected is the
-- main panel (the last one clicked), the reference to align the others
---------------------------------------------------------------------------
EditMode.selection = {}

-- Is `id` attached (parent or anchor, directly or not) to `target`?
local function dependsOn(layout, id, target, seen)
	seen = seen or {}
	if seen[id] then return false end
	seen[id] = true
	local p = layout.panels[id]
	if not p then return false end
	for _, ref in ipairs({ p.parent, p.anchor.relativeTo }) do
		local other = type(ref) == "string" and ref:match("^panel:(.+)$")
		if other and (other == target or dependsOn(layout, other, target, seen)) then
			return true
		end
	end
	return false
end

local function selectedIds()
	local ids = {}
	for id in pairs(EditMode.selection) do ids[#ids + 1] = id end
	table.sort(ids)
	return ids
end

-- Selected panels that move by themselves: a panel attached to another
-- selected panel already follows it
local function movingIds()
	local layout = activeLayout()
	local ids = {}
	for _, id in ipairs(selectedIds()) do
		local follows = false
		for other in pairs(EditMode.selection) do
			if other ~= id and dependsOn(layout, id, other) then follows = true break end
		end
		if not follows then ids[#ids + 1] = id end
	end
	return ids
end

function EditMode:Paint()
	for id, m in pairs(movers) do
		local on = self.selection[id]
		local main = id == self.selected
		m.fill:SetVertexColor(unpack(accentAlpha(on and 0.28 or 0.12)))
		T:SetBorderColor(m.edges, main and C.accent or on and accentAlpha(0.85) or accentAlpha(0.5))
		for _, h in ipairs(m.handles) do h.dot:SetShown(main and not next(self.selection, next(self.selection))) end
	end
	self:RefreshInfo()
end

-- Selects one panel only (nil: nothing)
function EditMode:Select(id)
	if id and not movers[id] then id = nil end
	wipe(self.selection)
	if id then self.selection[id] = true end
	self.selected = id
	self:Paint()
end

-- Ctrl+click: adds or removes a panel
function EditMode:Toggle(id)
	if not movers[id] then return end
	if self.selection[id] then
		self.selection[id] = nil
		if self.selected == id then self.selected = next(self.selection) end
	else
		self.selection[id] = true
		self.selected = id
	end
	self:Paint()
end

---------------------------------------------------------------------------
-- Snapping
---------------------------------------------------------------------------
-- Lines a moving selection can snap to (screen and the other panels)
local function snapLines(exclude)
	local w, h = UIParent:GetWidth(), UIParent:GetHeight()
	local xs, ys = { 0, w / 2, w }, { 0, h / 2, h }
	local layout = activeLayout()
	for otherId, mover in pairs(movers) do
		local skip = exclude[otherId]
		if not skip then
			for id in pairs(exclude) do
				if dependsOn(layout, otherId, id) then skip = true break end
			end
		end
		if not skip and mover:IsShown() then
			local l, b, r, t = rect(mover.target)
			if l then
				xs[#xs + 1], xs[#xs + 2], xs[#xs + 3] = l, r, (l + r) / 2
				ys[#ys + 1], ys[#ys + 2], ys[#ys + 3] = b, t, (b + t) / 2
			end
		end
	end
	return xs, ys
end

-- Best correction so one of `values` lands on a line; nil when none is close enough
local function snapToLines(values, lines, distance)
	local best, line
	for _, v in ipairs(values) do
		for _, candidate in ipairs(lines) do
			local d = candidate - v
			if math.abs(d) <= distance and (not best or math.abs(d) < math.abs(best)) then
				best, line = d, candidate
			end
		end
	end
	return best, line
end

-- Correction putting `value` on the grid (centered on the screen)
local function snapToGrid(value, center)
	local g = S().gridSize
	return center + math.floor((value - center) / g + 0.5) * g - value
end

-- Snaps one axis. values[1] is the edge used for the grid.
-- Returns the correction and the guide position (panel or screen line)
local function snapAxis(values, lines, center)
	if IsShiftKeyDown() then return 0 end
	local s = S()
	if s.snapPanels then
		local d, line = snapToLines(values, lines, s.snapDistance)
		if d then return d, line end
	end
	if s.snapGrid then
		-- A magnet, not steps: only close to a line, so the panel still moves smoothly
		local d = snapToGrid(values[1], center)
		if math.abs(d) <= math.min(s.snapDistance, s.gridSize / 4) then return d end
	end
	return 0
end

-- UIParent units -> offset units of a panel
local function toParent(id)
	local frame = core.Layouts.frames[id]
	local parent = frame and frame:GetParent() or UIParent
	return uiScale() / parent:GetEffectiveScale()
end

---------------------------------------------------------------------------
-- Dragging
---------------------------------------------------------------------------
local drag

function EditMode:ShowGuides(gx, gy)
	local f = self.frame
	f.vGuide:SetShown(gx ~= nil)
	f.hGuide:SetShown(gy ~= nil)
	if gx then
		f.vGuide:ClearAllPoints()
		f.vGuide:SetPoint("TOP", f, "TOPLEFT", gx, 0)
		f.vGuide:SetPoint("BOTTOM", f, "BOTTOMLEFT", gx, 0)
	end
	if gy then
		f.hGuide:ClearAllPoints()
		f.hGuide:SetPoint("LEFT", f, "BOTTOMLEFT", 0, gy)
		f.hGuide:SetPoint("RIGHT", f, "BOTTOMRIGHT", 0, gy)
	end
end

local function updateDrag()
	local d = drag
	local p = panelOf(d.id)
	if not p then EditMode:EndDrag() return end
	local cx, cy = cursor()
	local dx, dy = cx - d.cx, cy - d.cy
	if not d.moved and math.abs(dx) < 2 and math.abs(dy) < 2 then return end
	d.moved = true
	local l, b, r, t = unpack(d.rect)
	local w, h = UIParent:GetWidth(), UIParent:GetHeight()
	local gx, gy

	if d.mode == "move" then
		-- The grabbed panel snaps, the rest of the selection moves with it
		local sx, sy
		sx, gx = snapAxis({ l + dx, (l + r) / 2 + dx, r + dx }, d.xs, w / 2)
		sy, gy = snapAxis({ b + dy, (b + t) / 2 + dy, t + dy }, d.ys, h / 2)
		dx, dy = dx + sx, dy + sy
		for _, item in ipairs(d.items) do
			local ip = panelOf(item.id)
			if ip then
				ip.anchor.x = round(item.x + dx * item.toParent)
				ip.anchor.y = round(item.y + dy * item.toParent)
				core.Layouts:PanelChanged(item.id, "geometry")
			end
		end
	else
		local e = d.edges
		local hp, vp = hPart(p.anchor.point), vPart(p.anchor.point)
		local x, y, width, height = d.x, d.y, d.width, d.height
		if e.right or e.left then
			local dw, s
			if e.right then
				s, gx = snapAxis({ r + dx }, d.xs, w / 2)
				dw = math.max(MIN_SIZE + l - r, dx + s)
				x = x + (hp == "RIGHT" and dw or hp == "CENTER" and dw / 2 or 0) * d.toParent
			else
				s, gx = snapAxis({ l + dx }, d.xs, w / 2)
				local dl = math.min(r - l - MIN_SIZE, dx + s)
				dw = -dl
				x = x + (hp == "LEFT" and dl or hp == "CENTER" and dl / 2 or 0) * d.toParent
			end
			width = width + dw * d.toWidth
		end
		if e.top or e.bottom then
			local dh, s
			if e.top then
				s, gy = snapAxis({ t + dy }, d.ys, h / 2)
				dh = math.max(MIN_SIZE + b - t, dy + s)
				y = y + (vp == "TOP" and dh or vp == "CENTER" and dh / 2 or 0) * d.toParent
			else
				s, gy = snapAxis({ b + dy }, d.ys, h / 2)
				local db = math.min(t - b - MIN_SIZE, dy + s)
				dh = -db
				y = y + (vp == "BOTTOM" and db or vp == "CENTER" and db / 2 or 0) * d.toParent
			end
			height = height + dh * d.toHeight
		end
		p.anchor.x, p.anchor.y = round(x), round(y)
		p.width, p.height = math.max(0, round(width)), math.max(0, round(height))
		core.Layouts:PanelChanged(d.id, "geometry")
	end
	EditMode:ShowGuides(gx, gy)
	EditMode:RefreshInfo()
end

-- mode "move": the selection (grabbed panel included); "resize": the grabbed panel
function EditMode:StartDrag(id, mode, edges)
	local frame = core.Layouts.frames[id]
	local p = panelOf(id)
	if not frame or not p then return end
	if not self.selection[id] or mode == "resize" then
		self:Select(id)
	elseif self.selected ~= id then
		self.selected = id
		self:Paint()
	end
	local l, b, r, t = rect(frame)
	if not l then return end
	local parent = frame:GetParent() or UIParent
	local ui = uiScale()
	local cx, cy = cursor()
	local ids = mode == "move" and movingIds() or { id }
	local exclude = {}
	for _, selected in ipairs(ids) do exclude[selected] = true end
	exclude[id] = true
	local xs, ys = snapLines(exclude)
	local items = {}
	for _, itemId in ipairs(ids) do
		local ip = panelOf(itemId)
		items[#items + 1] = { id = itemId, x = ip.anchor.x, y = ip.anchor.y, toParent = toParent(itemId) }
	end
	-- UIParent units -> panel data units
	local toFrame = ui / frame:GetEffectiveScale()
	drag = {
		id = id, mode = mode, edges = edges or {}, items = items,
		cx = cx, cy = cy, rect = { l, b, r, t },
		x = p.anchor.x, y = p.anchor.y, width = p.width, height = p.height,
		toParent = ui / parent:GetEffectiveScale(),
		toWidth = p.widthUnit == "%" and toFrame * 100 / math.max(1, parent:GetWidth()) or toFrame,
		toHeight = p.heightUnit == "%" and toFrame * 100 / math.max(1, parent:GetHeight()) or toFrame,
		xs = xs, ys = ys,
		before = snapshots(ids),
	}
	self.frame:SetScript("OnUpdate", updateDrag)
end

function EditMode:EndDrag()
	if not drag then return end
	local d = drag
	drag = nil
	self.frame:SetScript("OnUpdate", nil)
	self:ShowGuides(nil, nil)
	if changedSince(d.before) then
		pushUndo(d.before)
		-- Sizes in % of these panels and text/tiling: redraw everything once
		core.Layouts:RefreshAll()
	end
	self:RefreshInfo()
end

-- Aligns the selection on the main panel: LEFT, HCENTER, RIGHT, TOP, VCENTER, BOTTOM
function EditMode:Align(how)
	local ref = core.Layouts.frames[self.selected]
	if not ref then return end
	local rl, rb, rr, rt = rect(ref)
	local ids = movingIds()
	pushUndo(snapshots(ids))
	for _, id in ipairs(ids) do
		local frame = core.Layouts.frames[id]
		if id ~= self.selected and frame then
			local l, b, r, t = rect(frame)
			local dx, dy = 0, 0
			if how == "LEFT" then dx = rl - l
			elseif how == "RIGHT" then dx = rr - r
			elseif how == "HCENTER" then dx = (rl + rr) / 2 - (l + r) / 2
			elseif how == "TOP" then dy = rt - t
			elseif how == "BOTTOM" then dy = rb - b
			elseif how == "VCENTER" then dy = (rb + rt) / 2 - (b + t) / 2
			end
			local p = panelOf(id)
			local k = toParent(id)
			p.anchor.x = round(p.anchor.x + dx * k)
			p.anchor.y = round(p.anchor.y + dy * k)
			core.Layouts:PanelChanged(id, "geometry")
		end
	end
	self:RefreshInfo()
end

---------------------------------------------------------------------------
-- Keyboard
---------------------------------------------------------------------------
local ARROWS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

function EditMode:Nudge(key)
	local ids = movingIds()
	if #ids == 0 then return end
	local step = IsShiftKeyDown() and S().bigStep or 1
	pushUndo(snapshots(ids))
	for _, id in ipairs(ids) do
		local p = panelOf(id)
		p.anchor.x = p.anchor.x + ARROWS[key][1] * step
		p.anchor.y = p.anchor.y + ARROWS[key][2] * step
		core.Layouts:PanelChanged(id, "geometry")
	end
	self:RefreshInfo()
end

local function onKeyDown(self, key)
	local handled = true
	if key == "ESCAPE" then
		if EditMode.selected then EditMode:Select(nil) else EditMode:Stop() end
	elseif ARROWS[key] and EditMode.selected then
		EditMode:Nudge(key)
	elseif key == "Z" and IsControlKeyDown() then
		EditMode:Undo()
	else
		handled = false
	end
	if not InCombatLockdown() then
		self:SetPropagateKeyboardInput(not handled)
	end
end

---------------------------------------------------------------------------
-- Movers
---------------------------------------------------------------------------
local HANDLES = {
	{ "TOPLEFT", { left = true, top = true } }, { "TOPRIGHT", { right = true, top = true } },
	{ "BOTTOMLEFT", { left = true, bottom = true } }, { "BOTTOMRIGHT", { right = true, bottom = true } },
	{ "LEFT", { left = true } }, { "RIGHT", { right = true } },
	{ "TOP", { top = true } }, { "BOTTOM", { bottom = true } },
}

local function createHandle(mover, point, edges)
	local h = CreateFrame("Frame", nil, mover)
	h.edges = edges
	if point == "LEFT" or point == "RIGHT" then
		h:SetWidth(HANDLE)
		h:SetPoint("TOP", mover, "TOP" .. point, 0, -HANDLE / 2)
		h:SetPoint("BOTTOM", mover, "BOTTOM" .. point, 0, HANDLE / 2)
	elseif point == "TOP" or point == "BOTTOM" then
		h:SetHeight(HANDLE)
		h:SetPoint("LEFT", mover, point .. "LEFT", HANDLE / 2, 0)
		h:SetPoint("RIGHT", mover, point .. "RIGHT", -HANDLE / 2, 0)
	else
		h:SetSize(HANDLE, HANDLE)
		h:SetPoint("CENTER", mover, point)
	end
	h.dot = T:Fill(h, C.accent, "OVERLAY")
	h.dot:ClearAllPoints()
	h.dot:SetPoint("CENTER")
	if point == "LEFT" or point == "RIGHT" then
		h.dot:SetSize(2, 14)
	elseif point == "TOP" or point == "BOTTOM" then
		h.dot:SetSize(14, 2)
	else
		h.dot:SetSize(6, 6)
	end
	h:EnableMouse(true)
	h:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then EditMode:StartDrag(mover.id, "resize", self.edges) end
	end)
	h:SetScript("OnMouseUp", function() EditMode:EndDrag() end)
	return h
end

local function createMover()
	local m = CreateFrame("Button", nil, EditMode.frame)
	m.fill = T:Fill(m, accentAlpha(0.12), "BACKGROUND")
	m.edges = T:Border(m, accentAlpha(0.5))
	m.label = T:Text(m, T.fonts.small, C.text, "CENTER")
	m.label:SetPoint("CENTER")
	m.handles = {}
	for _, def in ipairs(HANDLES) do
		m.handles[#m.handles + 1] = createHandle(m, def[1], def[2])
	end
	m:RegisterForClicks("RightButtonUp")
	m:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end
		-- Ctrl+click adds to / removes from the selection
		if IsControlKeyDown() then
			EditMode:Toggle(self.id)
		else
			EditMode:StartDrag(self.id, "move")
		end
	end)
	m:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" then EditMode:EndDrag() end
	end)
	m:SetScript("OnClick", function(self)
		local id = self.id
		EditMode.reopen = false
		EditMode:Stop()
		Options:EditPanel(id)
	end)
	m:SetScript("OnEnter", function(self)
		if not EditMode.selection[self.id] then self.fill:SetVertexColor(unpack(accentAlpha(0.22))) end
	end)
	m:SetScript("OnLeave", function(self)
		if not EditMode.selection[self.id] then self.fill:SetVertexColor(unpack(accentAlpha(0.12))) end
	end)
	return m
end

local moverPool = {}

function EditMode:Build()
	for _, m in pairs(movers) do
		m:Hide()
		m:ClearAllPoints()
		moverPool[#moverPool + 1] = m
	end
	wipe(movers)
	local layout = activeLayout()
	if not layout then return end

	-- Big panels below, small ones above, so every panel can be grabbed
	local list = {}
	for id, frame in pairs(core.Layouts.frames) do
		if frame:IsVisible() and not core.Layouts.waiting[id] then
			local l, b, r, t = rect(frame)
			if l then list[#list + 1] = { id = id, frame = frame, area = (r - l) * (t - b) } end
		end
	end
	table.sort(list, function(a, b) return a.area > b.area end)

	local base = self.frame:GetFrameLevel() + 5
	for i, entry in ipairs(list) do
		local m = table.remove(moverPool) or createMover()
		m.id, m.target = entry.id, entry.frame
		m:SetAllPoints(entry.frame)
		m:SetFrameLevel(base + i * 2)
		for _, h in ipairs(m.handles) do h:SetFrameLevel(base + i * 2 + 1) end
		m.label:SetText(layout.panels[entry.id].name)
		m.label:SetWidth(math.max(20, (entry.frame:GetWidth() or 40) * entry.frame:GetEffectiveScale() / uiScale() - 4))
		m:Show()
		movers[entry.id] = m
	end
	-- Keeps the selection of the panels that still exist
	for id in pairs(self.selection) do
		if not movers[id] then self.selection[id] = nil end
	end
	if self.selected and not movers[self.selected] then self.selected = next(self.selection) end
	self:Paint()
end

---------------------------------------------------------------------------
-- Grid
---------------------------------------------------------------------------
function EditMode:DrawGrid()
	local grid = self.frame.grid
	grid.lines = grid.lines or {}
	local s = S()
	grid:SetShown(s.showGrid)
	local n = 0
	local function line(vertical, pos, center)
		n = n + 1
		local tex = grid.lines[n]
		if not tex then
			tex = grid:CreateTexture(nil, "BACKGROUND", nil, 1)
			tex:SetTexture(T.WHITE)
			grid.lines[n] = tex
		end
		tex:ClearAllPoints()
		if vertical then
			tex:SetPoint("TOPLEFT", grid, "TOPLEFT", pos, 0)
			tex:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", pos, 0)
			if PixelUtil then PixelUtil.SetWidth(tex, 1) else tex:SetWidth(1) end
		else
			tex:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", 0, pos)
			tex:SetPoint("BOTTOMRIGHT", grid, "BOTTOMRIGHT", 0, pos)
			if PixelUtil then PixelUtil.SetHeight(tex, 1) else tex:SetHeight(1) end
		end
		if center then
			tex:SetVertexColor(unpack(accentAlpha(0.5)))
		else
			tex:SetVertexColor(1, 1, 1, 0.08)
		end
		tex:Show()
	end
	if s.showGrid then
		local g = math.max(4, s.gridSize)
		local w, h = UIParent:GetWidth(), UIParent:GetHeight()
		local cx, cy = w / 2, h / 2
		for k = -math.floor(cx / g), math.floor(cx / g) do line(true, cx + k * g, k == 0) end
		for k = -math.floor(cy / g), math.floor(cy / g) do line(false, cy + k * g, k == 0) end
	end
	for i = n + 1, #grid.lines do grid.lines[i]:Hide() end
end

---------------------------------------------------------------------------
-- Toolbar
---------------------------------------------------------------------------
function EditMode:RefreshInfo()
	local bar = self.frame and self.frame.bar
	if not bar then return end
	local p = panelOf(self.selected)
	local count = #selectedIds()
	bar.align:SetShown(count > 1)
	if count > 1 then
		bar.info:SetText(L["EDIT_MULTI"]:format(count, p and p.name or ""))
		bar.info:SetTextColor(unpack(C.text))
		bar.editButton:Hide()
	elseif p then
		local function unit(value, u) return u == "%" and (round(value) .. "%") or tostring(round(value)) end
		bar.info:SetText(L["EDIT_INFO"]:format(p.name, round(p.anchor.x), round(p.anchor.y),
			unit(p.width, p.widthUnit), unit(p.height, p.heightUnit)))
		bar.info:SetTextColor(unpack(C.text))
		bar.editButton:Show()
	else
		bar.info:SetText(L["EDIT_MODE_HINT"])
		bar.info:SetTextColor(unpack(C.textDim))
		bar.editButton:Hide()
	end
	bar.gridValue:SetText(S().gridSize)
	bar.grid:SetChecked(S().showGrid)
	bar.snap:SetChecked(S().snapGrid or S().snapPanels)
	bar.undo:SetEnabledState(#undoStack > 0)
end

local function labeledSwitch(parent, text, onChange)
	local s = W.Switch(parent, onChange)
	s.label = T:Text(parent, T.fonts.normal, C.textDim, "RIGHT")
	s.label:SetPoint("RIGHT", s, "LEFT", -6, 0)
	s.label:SetText(text)
	return s
end

local function createToolbar(f)
	local bar = CreateFrame("Frame", nil, f)
	bar:SetSize(900, 92)
	bar:SetPoint("TOP", 0, -40)
	bar:SetFrameLevel(f:GetFrameLevel() + 2000)
	bar:EnableMouse(true)
	bar:SetMovable(true)
	bar:SetClampedToScreen(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", bar.StartMoving)
	bar:SetScript("OnDragStop", bar.StopMovingOrSizing)
	T:Fill(bar, C.window)
	T:Border(bar, C.accent)

	local title = T:Text(bar, T.fonts.header, C.accent)
	title:SetPoint("TOPLEFT", 16, -12)
	title:SetText(L["EDIT_MODE"])
	bar.layout = T:Text(bar, T.fonts.normal, C.textDim)
	bar.layout:SetPoint("LEFT", title, "RIGHT", 10, 0)

	local done = W.Button(bar, L["DONE"], 100, "primary", function() EditMode:Stop() end)
	done:SetPoint("TOPRIGHT", -12, -10)
	bar.undo = W.Button(bar, L["UNDO"], 90, "default", function() EditMode:Undo() end)
	bar.undo:SetPoint("RIGHT", done, "LEFT", -8, 0)

	bar.snap = labeledSwitch(bar, L["SNAP"], function(on)
		S().snapGrid, S().snapPanels = on, on
	end)
	bar.snap:SetPoint("RIGHT", bar.undo, "LEFT", -16, 0)
	bar.grid = labeledSwitch(bar, L["GRID"], function(on)
		S().showGrid = on
		EditMode:DrawGrid()
	end)
	bar.grid:SetPoint("RIGHT", bar.snap.label, "LEFT", -16, 0)

	local plus = W.Button(bar, "+", 24, "default", function()
		S().gridSize = math.min(128, S().gridSize + 4)
		EditMode:DrawGrid()
		EditMode:RefreshInfo()
	end)
	plus:SetHeight(22)
	plus:SetPoint("RIGHT", bar.grid.label, "LEFT", -16, 0)
	bar.gridValue = T:Text(bar, T.fonts.normal, C.text, "CENTER")
	bar.gridValue:SetWidth(30)
	bar.gridValue:SetPoint("RIGHT", plus, "LEFT", -2, 0)
	local minus = W.Button(bar, "-", 24, "default", function()
		S().gridSize = math.max(4, S().gridSize - 4)
		EditMode:DrawGrid()
		EditMode:RefreshInfo()
	end)
	minus:SetHeight(22)
	minus:SetPoint("RIGHT", bar.gridValue, "LEFT", -2, 0)

	bar.info = T:Text(bar, T.fonts.normal, C.textDim)
	bar.info:SetPoint("TOPLEFT", 16, -48)
	bar.info:SetWordWrap(true)
	bar.info:SetJustifyV("TOP")
	bar.editButton = W.Button(bar, L["PANEL_SETTINGS"], 150, "default", function()
		local id = EditMode.selected
		EditMode.reopen = false
		EditMode:Stop()
		Options:EditPanel(id)
	end)
	bar.editButton:SetPoint("BOTTOMRIGHT", -12, 8)

	-- Alignment on the main panel, shown with several panels selected
	bar.align = CreateFrame("Frame", nil, bar)
	bar.align:SetSize(470, 26)
	bar.align:SetPoint("BOTTOMRIGHT", -12, 8)
	local previous
	for i = 6, 1, -1 do
		local how = ({ "LEFT", "HCENTER", "RIGHT", "TOP", "VCENTER", "BOTTOM" })[i]
		local b = W.Button(bar.align, L["ALIGN_" .. how], 70, "default", function() EditMode:Align(how) end)
		b:SetHeight(24)
		if previous then b:SetPoint("RIGHT", previous, "LEFT", -4, 0) else b:SetPoint("RIGHT") end
		previous = b
	end
	local alignLabel = T:Text(bar.align, T.fonts.normal, C.textDim, "RIGHT")
	alignLabel:SetPoint("RIGHT", previous, "LEFT", -8, 0)
	alignLabel:SetText(L["ALIGN"])
	bar.align:Hide()
	bar.info:SetPoint("RIGHT", bar.editButton, "LEFT", -10, 0)
	f.bar = bar
end

---------------------------------------------------------------------------
-- Start / stop
---------------------------------------------------------------------------
function EditMode:Create()
	if self.frame then return end
	local f = CreateFrame("Frame", "nxPanelsEditMode", UIParent)
	f:SetAllPoints(UIParent)
	f:SetFrameStrata("FULLSCREEN")
	f:EnableMouse(true)
	f:EnableKeyboard(true)
	f:SetScript("OnKeyDown", onKeyDown)
	f:SetScript("OnMouseDown", function() EditMode:Select(nil) end)
	f:Hide()
	T:Fill(f, { 0, 0, 0, 0.3 })

	f.grid = CreateFrame("Frame", nil, f)
	f.grid:SetAllPoints(f)
	f.vGuide = f:CreateTexture(nil, "OVERLAY")
	f.vGuide:SetTexture(T.WHITE)
	f.vGuide:SetVertexColor(1, 0.82, 0, 0.9)
	f.vGuide:SetWidth(1)
	f.hGuide = f:CreateTexture(nil, "OVERLAY")
	f.hGuide:SetTexture(T.WHITE)
	f.hGuide:SetVertexColor(1, 0.82, 0, 0.9)
	f.hGuide:SetHeight(1)
	f.vGuide:Hide()
	f.hGuide:Hide()
	self.frame = f
	createToolbar(f)

	-- The layout was rebuilt (activated, profile changed...): new frames
	hooksecurefunc(core.Layouts, "ApplyActive", function()
		if EditMode.active then EditMode:Build() end
	end)
	-- Leaves the edit mode when a fight starts
	core:RegisterEvent("PLAYER_REGEN_DISABLED", function() EditMode:Stop() end)
	core:RegisterEvent("DISPLAY_SIZE_CHANGED", function()
		if EditMode.active then EditMode:DrawGrid() end
	end)
end

function EditMode:Start(panelId)
	if self.active then
		if panelId then self:Select(panelId) else self:Stop() end
		return
	end
	if InCombatLockdown() then
		core:Print(L["EDIT_MODE_COMBAT"])
		return
	end
	local layout = activeLayout()
	if not layout then
		core:Print(L["LAYOUT_NONE"])
		return
	end
	self:Create()
	O.Dropdown:Close()
	self.reopen = Options.frame ~= nil and Options.frame:IsShown()
	if self.reopen then Options.frame:Hide() end
	self.active = true
	wipe(undoStack)
	self.frame.bar.layout:SetText(layout.name)
	self.frame:Show()
	-- Panels hidden by their display conditions are shown while editing
	core.Visibility:SetForceShow(true)
	self:DrawGrid()
	self:Build()
	self:Select(panelId)
end

function EditMode:Stop()
	if not self.active then return end
	self:EndDrag()
	self.active = false
	self.frame:Hide()
	core.Visibility:SetForceShow(false)
	for _, m in pairs(movers) do m:Hide() end
	if self.reopen then
		self.reopen = false
		Options:Show()
	end
end

Options:RegisterPage({
	key = "editmode",
	title = L["EDIT_MODE"],
	icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
	action = function() EditMode:Start() end,
})
