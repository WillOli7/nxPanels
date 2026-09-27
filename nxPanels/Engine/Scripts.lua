local _, ns = ...
local L = ns.L

--[[
User scripts of the panels.

- Compiled once per layout activation, in a shared environment: scripts read the
  game globals normally, and the variables they create are shared between panels
  (they no longer leak into the global namespace of the game).
- Scripts use self.bg, self.text, nxPanels:FetchFrame(), arg1... of OnEvent and
  the pressed / released locals of CLICK.
- A script that raises an error is reported once and switched off until the next
  reload, instead of flooding the chat.
]]
local Scripts = {}
ns.Scripts = Scripts

-- hook = { frame script, parameters, header run before the user code }
local HOOKS = {
	EVENT = { "OnEvent", "self, event, ...", "local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = ..." },
	UPDATE = { "OnUpdate", "self, elapsed" },
	SHOW = { "OnShow", "self" },
	HIDE = { "OnHide", "self" },
	ENTER = { "OnEnter", "self, motion" },
	LEAVE = { "OnLeave", "self, motion" },
	RESIZE = { "OnSizeChanged", "self, width, height" },
	DROP = { "OnReceiveDrag", "self" },
}
local FRAME_SCRIPTS = {
	"OnEvent", "OnUpdate", "OnShow", "OnHide", "OnEnter", "OnLeave",
	"OnSizeChanged", "OnReceiveDrag", "OnMouseDown", "OnMouseUp",
}

local env = setmetatable({}, { __index = _G })
Scripts.env = env

local reported = {}

local function report(panelName, hook, err)
	local key = panelName .. "\0" .. hook
	if reported[key] then return end
	reported[key] = true
	ns:Print(L["SCRIPT_ERROR"], panelName, hook, tostring(err))
end

-- The user code starts on line 1, so error line numbers match the editor
local function compile(code, args, header, chunkName)
	local source = ("return function(%s) %s %s\nend"):format(args, header or "", code)
	local chunk, err = loadstring(source, chunkName)
	if not chunk then return nil, err end
	setfenv(chunk, env)
	return chunk()
end

local function guard(fn, frame, scriptName, panelName, hook)
	return function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			frame:SetScript(scriptName, nil)
			report(panelName, hook, err)
		end
	end
end

function Scripts:Attach(frame, panel)
	env.nxPanels = ns.API
	local scripts = panel.scripts
	local name = panel.name

	-- LOAD runs first, once
	local code = scripts.LOAD
	if code and code:find("%S") then
		local fn, err = compile(code, "self, nxPanels", nil, ("=%s:LOAD"):format(name))
		if fn then
			local ok, runErr = pcall(fn, frame, ns.API)
			if not ok then report(name, "LOAD", runErr) end
		else
			ns:Print(L["SCRIPT_COMPILE_ERROR"], name, "LOAD", err)
		end
	end

	for hook, def in pairs(HOOKS) do
		code = scripts[hook]
		if code and code:find("%S") then
			local fn, err = compile(code, def[2], def[3], ("=%s:%s"):format(name, hook))
			if fn then
				frame:SetScript(def[1], guard(fn, frame, def[1], name, hook))
			else
				ns:Print(L["SCRIPT_COMPILE_ERROR"], name, hook, err)
			end
		end
	end

	-- CLICK: called on mouse down (pressed) and mouse up (released)
	code = scripts.CLICK
	if code and code:find("%S") then
		local down, err = compile(code, "self, button", "local pressed = true", ("=%s:CLICK"):format(name))
		local up = down and compile(code, "self, button", "local released = true", ("=%s:CLICK"):format(name))
		if down and up then
			frame:SetScript("OnMouseDown", guard(down, frame, "OnMouseDown", name, "CLICK"))
			frame:SetScript("OnMouseUp", guard(up, frame, "OnMouseUp", name, "CLICK"))
		else
			ns:Print(L["SCRIPT_COMPILE_ERROR"], name, "CLICK", err)
		end
	end
end

function Scripts:Detach(frame)
	for _, script in ipairs(FRAME_SCRIPTS) do
		frame:SetScript(script, nil)
	end
	frame:UnregisterAllEvents()
end

function Scripts:ResetErrors()
	wipe(reported)
end
