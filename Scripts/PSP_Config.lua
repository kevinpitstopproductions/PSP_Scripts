--[[
 * ReaScript Name: PSP_Config.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 0.5.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-07)
 	+ Initial Release
 * v0.3 (2021-06-08)
 	+ Added config option (mute env behind automation items)
 * v0.4 (2021-06-21)
	+ General Update
 * v0.5 (2021-07-07)
 	+ Upgraded to ReaImGui v5
 * v0.5.1 (2021-07-08)
 	+ Better error message
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text)) end end

--- VARIABLES ---

local section = "PSP_Scripts"
local settings = {}
local is_finished = false

local window_flags = 
    reaper.ImGui_WindowFlags_NoCollapse() |
    reaper.ImGui_WindowFlags_AlwaysAutoResize()

--- FUNCTIONS ---

local function toboolean(text)
	if text == "true" then return true
	else return false end
end

--- MAIN ---

if not reaper.APIExists('ImGui_GetVersion') then
	reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
	reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5 or later", "Error", 0) return end

settings.is_random = toboolean(reaper.GetExtState(section, "SD_is_random"))
settings.chop_end = reaper.GetExtState(section, "SD_chop_end")
settings.mute_envelope = toboolean(reaper.GetExtState(section, "SD_mute_envelope"))

local ctx = reaper.ImGui_CreateContext('PSP Config', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
  	local rv

  	if reaper.ImGui_CollapsingHeader(ctx, 'Sound Design') then
   		if reaper.ImGui_TreeNode(ctx, 'Take Marker Randomizer') then
	    	rv, settings.is_random = reaper.ImGui_Checkbox(ctx, "Is Random", settings.is_random)
	    	rv, settings.chop_end = reaper.ImGui_InputText(ctx, "Chop End (sec)", settings.chop_end, reaper.ImGui_InputTextFlags_CharsDecimal())
	    	reaper.ImGui_TreePop(ctx)
	    end
	    if reaper.ImGui_TreeNode(ctx, 'Trim Automation Items') then
	    	rv, settings.mute_envelope = reaper.ImGui_Checkbox(ctx, "Mute envelope behind automation items", settings.mute_envelope)
	    	reaper.ImGui_TreePop(ctx)
	    end
  	end

  	local button_width = 100

  	if reaper.ImGui_GetWindowWidth(ctx) < 300 then
  		button_width = reaper.ImGui_GetWindowWidth(ctx) / 3
  	else
  		button_width = 100
  	end

  	if reaper.ImGui_Button(ctx, "OK", button_width) then
  		reaper.SetExtState(section, "SD_is_random", tostring(settings.is_random), 1)
  		reaper.SetExtState(section, "SD_chop_end", tonumber(settings.chop_end), 1)
  		reaper.SetExtState(section, "SD_mute_envelope", tostring(settings.mute_envelope), 1)
  		is_finished = true
  	end

  	reaper.ImGui_SameLine( ctx )

  	if reaper.ImGui_Button(ctx, "Cancel", button_width) then
  		is_finished = true
  	end

  	reaper.ImGui_SameLine( ctx )

  	if reaper.ImGui_Button(ctx, "Apply", button_width) then
  		reaper.SetExtState(section, "SD_is_random", tostring(settings.is_random), 1)
  		reaper.SetExtState(section, "SD_chop_end", tonumber(settings.chop_end), 1)
  		reaper.SetExtState(section, "SD_mute_envelope", tostring(settings.mute_envelope), 1)
  	end
end

function loop()
  	reaper.ImGui_PushFont(ctx, font)
  	reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
  	local visible, open = reaper.ImGui_Begin(ctx, 'PSP Config', true, window_flags)

  	if is_finished then
  		open = false
  	end
  	if visible then
    	frame()
    	reaper.ImGui_End(ctx)
  	end
  	reaper.ImGui_PopFont(ctx)
  
  	if open then
    	reaper.defer(loop)
  	else
    	reaper.ImGui_DestroyContext(ctx)
  	end
end

reaper.defer(loop)