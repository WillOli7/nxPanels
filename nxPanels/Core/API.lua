local _, ns = ...

--[[
Public API, also available to the panel scripts as "nxPanels".
Every function works with both call styles: nxPanels.FetchFrame("name")
and nxPanels:FetchFrame("name").
]]
local API = {}
ns.API = API
_G.nxPanels = API

API.version = ns.version

-- Internal namespace, used by the nxPanels modules (options, import)
API.__ns = ns

local function arg(a, b)
	if a == API then return b end
	return a
end

-- Frame of a panel of the active layout, by id or by name
function API.GetPanelFrame(a, b)
	local key = arg(a, b)
	local layout = ns.Database:GetLayout(ns.Layouts.activeId)
	local id = ns.Database:FindPanel(layout, key)
	return id and ns.Layouts.frames[id]
end
API.FetchFrame = API.GetPanelFrame

-- Name and id of the active layout
function API.GetActiveLayout()
	local id = ns.Layouts.activeId
	local layout = ns.Database:GetLayout(id)
	if layout then
		return layout.name, id
	end
end

-- Activates a layout by id or by name; returns true on success
function API.ActivateLayout(a, b)
	local id = ns.Database:FindLayout(arg(a, b))
	if not id then return false end
	ns.Layouts:Activate(id)
	return true
end

function API.Print(...)
	if ... == API then
		API.Print(select(2, ...))
		return
	end
	ns:Print(strjoin(" ", tostringall(...)))
end

--[[
Media packs: another addon adds its art to nxPanels (and to every addon using
LibSharedMedia). kind = "background", "border", "font" or "statusbar".
	nxPanels.RegisterMedia("background", "My Pack: Stone", "Interface\\AddOns\\MyPack\\stone.tga")
]]
function API.RegisterMedia(...)
	local kind, name, path = ...
	if kind == API then kind, name, path = select(2, ...) end
	if type(kind) ~= "string" or type(name) ~= "string" or not path then return false end
	return ns.Media.LSM:Register(kind, name, path) and true or false
end
