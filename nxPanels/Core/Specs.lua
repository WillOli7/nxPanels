local _, ns = ...

--[[
Specializations, to activate a layout per specialization.
Keys are neutral and stable, so one profile can be shared by several classes:
	"S<specID>"   Retail: specialization id (unique across classes)
	"G1", "G2"    WoW Forever, TBC Anniversary: primary / secondary talents
]]
local Specs = {}
ns.Specs = Specs

-- Key of the current specialization, nil while unknown (loading, low level)
function Specs:Current()
	if ns.usesTalentGroups then
		local getGroup = C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup or GetActiveTalentGroup
		local group = getGroup and getGroup()
		return group and group > 0 and ("G" .. group) or nil
	end
	local getSpec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
	local index = getSpec and getSpec()
	if not index or index < 1 then return nil end
	local getInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo
	local id = getInfo and getInfo(index)
	return id and ("S" .. id) or nil
end

-- Specializations of the player's class: { { key = "...", name = "..." }, ... }
function Specs:List()
	local list = {}
	if ns.usesTalentGroups then
		list[1] = { key = "G1", name = TALENT_SPEC_PRIMARY or "1" }
		list[2] = { key = "G2", name = TALENT_SPEC_SECONDARY or "2" }
		return list
	end
	local _, _, classId = UnitClass("player")
	local count = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID
		and C_SpecializationInfo.GetNumSpecializationsForClassID(classId)
		---@diagnostic disable-next-line: deprecated -- fallback for clients without the C_ function
		or (GetNumSpecializationsForClassID and GetNumSpecializationsForClassID(classId)) or 0
	for i = 1, count do
		local id, name = GetSpecializationInfoForClassID(classId, i)
		if id then list[#list + 1] = { key = "S" .. id, name = name or tostring(id) } end
	end
	return list
end

function Specs:Init()
	local function changed()
		-- Only rebuilds when the layout to show is really different
		if ns.Layouts.activeId ~= ns.Database:GetActiveLayoutId() then
			ns.Layouts:ApplyActive()
		end
	end
	ns:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(_, unit)
		if unit == nil or unit == "player" then changed() end
	end)
	ns:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", changed)
	ns:RegisterEvent("PLAYER_ENTERING_WORLD", changed)
end

-- Name of the current specialization
function Specs:CurrentName()
	local key = self:Current()
	for _, spec in ipairs(self:List()) do
		if spec.key == key then return spec.name end
	end
end

-- Name and icon (file id) of the active talents. Retail: the current specialization.
-- WoW Forever, TBC Anniversary: the talent tree with the most points in the active
-- group. nil while unknown or without points
function Specs:CurrentTalents()
	local info = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
	if not info then return nil end
	if ns.usesTalentGroups then
		local group = C_SpecializationInfo.GetActiveSpecGroup and C_SpecializationInfo.GetActiveSpecGroup()
		local _, _, classId = UnitClass("player")
		local count = C_SpecializationInfo.GetNumSpecializationsForClassID
			and C_SpecializationInfo.GetNumSpecializationsForClassID(classId)
		if not count or count < 1 then count = 3 end
		local bestName, bestIcon, bestPoints = nil, nil, 0
		for i = 1, count do
			local _, name, _, icon, _, _, points = info(i, false, false, nil, nil, group)
			if points and points > bestPoints then bestName, bestIcon, bestPoints = name, icon, points end
		end
		return bestName, bestIcon
	end
	local index = C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
	if not index or index < 1 then return nil end
	local _, name, _, icon = info(index)
	return name, icon
end
