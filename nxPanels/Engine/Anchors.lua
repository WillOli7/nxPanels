local _, ns = ...

--[[
Parent and anchor references:
	"UIParent" or ""   the screen
	"panel:<id>"       another panel of the same layout
	any other string   a global frame name (another addon's frame, a Blizzard frame...)
]]
local Anchors = {}
ns.Anchors = Anchors

local function panelRef(ref)
	return type(ref) == "string" and ref:match("^panel:(.+)$")
end

-- Returns the frame, or nil when it does not exist (yet)
function Anchors:Resolve(ref, frames, selfId)
	if not ref or ref == "" or ref == "UIParent" then
		return UIParent
	end
	local id = panelRef(ref)
	if id then
		if id == selfId then return nil end
		return frames[id]
	end
	local frame = _G[ref]
	if type(frame) == "table" and type(frame.GetObjectType) == "function"
		and not (frame.IsForbidden and frame:IsForbidden()) then
		return frame
	end
end

--[[
Order in which the panels must be placed: a panel comes after the panels it is
parented or anchored to. Panels that are part of a loop are returned in `cyclic`
and get anchored to the screen instead.
]]
function Anchors:Order(panels)
	local order, cyclic, state = {}, {}, {}

	local ids = {}
	for id in pairs(panels) do ids[#ids + 1] = id end
	table.sort(ids)

	local function deps(panel)
		local list = {}
		for _, ref in ipairs({ panel.parent, panel.anchor.relativeTo }) do
			local id = panelRef(ref)
			if id and panels[id] then list[#list + 1] = id end
		end
		return list
	end

	local function visit(id)
		if state[id] == "done" then return end
		if state[id] == "visiting" then
			cyclic[id] = true
			return
		end
		state[id] = "visiting"
		for _, dep in ipairs(deps(panels[id])) do
			visit(dep)
			if cyclic[dep] and state[dep] == "visiting" then
				cyclic[id] = true
			end
		end
		state[id] = "done"
		order[#order + 1] = id
	end

	for _, id in ipairs(ids) do
		visit(id)
	end
	return order, cyclic
end
