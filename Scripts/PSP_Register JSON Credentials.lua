--[[
 * ReaScript Name: PSP_Register JSON Credentials.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v1.0 (2021-04-14)
	+ Initial Release
 * v1.2 (2021-05-12)
	+ Bug Fixes
--]]

-- USER CONFIG AREA -----------------------------------------------------------

console = true -- true/false: display debug messages in the console

------------------------------------------------------- END OF USER CONFIG AREA

ext_name = "PSP_JSONCREDENTIALS"
ext_save = "key"

local ctx = reaper.ImGui_CreateContext('Copy / Paste JSON_CREDENTIALS', 1000, 210)
local is_complete = false

function Main(x)
	reaper.SetExtState(ext_name, ext_save, x, 1)
end

function loop()
	local rv

	if (reaper.ImGui_IsCloseRequested(ctx) or is_complete) then
		reaper.ImGui_DestroyContext(ctx)
	return
	end

	reaper.ImGui_SetNextWindowPos(ctx, 0, 0)
	reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_GetDisplaySize(ctx))
	reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

	if (reaper.ImGui_Button(ctx, 'Apply') or reaper.ImGui_IsKeyPressed(ctx, 13)) then
		Main(text)
		is_complete = true
	end
	
	rv, text = reaper.ImGui_InputTextMultiline( ctx, '', text, 1000, 170 )
  
	reaper.ImGui_End(ctx)
	
	reaper.defer(loop)
end
reaper.defer(loop)