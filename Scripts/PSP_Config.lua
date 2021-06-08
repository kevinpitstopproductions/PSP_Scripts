--[[
 * ReaScript Name: Config
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 0.2
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-07)
 	+ Initial Release
 * v0.2 (2021-06-08)
 	+ Added config option (mute env behind automation items)
--]]

--- DEBUG

local console = true

local function Msg(text)
	if console then reaper.ShowConsoleMsg(tostring(text)) end 
end

--- VARIABLES

local section = "PSP_Scripts"
local settings = {}
local is_finished = false

--- FUNCTIONS

local function toboolean(text)
	if text == "true" then return true
	else return false end
end -- toboolean

--- MAIN

settings.is_random = toboolean(reaper.GetExtState(section, "SD_is_random"))
settings.chop_end = reaper.GetExtState(section, "SD_chop_end")
settings.mute_envelope = toboolean(reaper.GetExtState(section, "SD_mute_envelope"))

reaper.defer(function()
	ctx = reaper.ImGui_CreateContext('PSP Config', 300, 60)
	viewport = reaper.ImGui_GetMainViewport(ctx)
	loop()
end)

function loop()
	local rv

	if reaper.ImGui_IsCloseRequested(ctx) or is_finished then
		reaper.ImGui_DestroyContext(ctx)
		return
	end

	reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
	reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
	reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

	if reaper.ImGui_CollapsingHeader(ctx, 'Sound Design') then
   		if reaper.ImGui_TreeNode(ctx, 'Take Marker Randomizer') then
	    	rv, settings.is_random = reaper.ImGui_Checkbox(ctx, "Is Random", settings.is_random)
	    	rv, settings.chop_end = reaper.ImGui_InputText(ctx, "Chop End (sec)", settings.chop_end, reaper.ImGui_InputTextFlags_CharsDecimal())
	    	reaper.ImGui_TreePop(ctx)
	    end -- Sub Header
	    if reaper.ImGui_TreeNode(ctx, 'Trim Automation Items') then
	    	rv, settings.mute_envelope = reaper.ImGui_Checkbox(ctx, "Mute envelope behind automation items", settings.mute_envelope)
	    	reaper.ImGui_TreePop(ctx)
	    end -- Sub Header
  	end -- Main Header

  	if reaper.ImGui_Button(ctx, "Save Changes") then
  		reaper.SetExtState(section, "SD_is_random", tostring(settings.is_random), 1)
  		reaper.SetExtState(section, "SD_chop_end", tonumber(settings.chop_end), 1)
  		reaper.SetExtState(section, "SD_mute_envelope", tostring(settings.mute_envelope), 1)
  		is_finished = true
  	end

  	reaper.ImGui_SameLine( ctx )

  	if reaper.ImGui_Button(ctx, "Cancel") then
  		is_finished = true
  	end

	reaper.ImGui_End(ctx)
  
	reaper.defer(loop)
end -- loop