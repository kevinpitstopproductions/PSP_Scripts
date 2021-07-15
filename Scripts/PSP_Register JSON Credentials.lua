--[[
 * ReaScript Name: PSP_Register JSON Credentials.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.5
--]]

--[[
 * Changelog:
 * v1.5 (2021-07-14)
 	+ Added Font scaling
 * v1.4.1 (2021-07-08)
    + Better error message
 * v1.4 (2021-07-07) 
 	+ Upgraded to ReaImGui v5
 * v1.3 (2021-06-21)
	+ General Update
 * v1.2 (2021-05-12)
	+ Bug Fixes
 * v1.0 (2021-04-14)
	+ Initial Release
--]]

----------------
--- INCLUDES ---
----------------

local scripts_directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(scripts_directory .. "PSP_Utils.lua") -- load shared utilities

-------------
--- DEBUG ---
-------------

local console = true
local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

-----------------
--- VARIABLES ---
-----------------

local window_flags = 
    reaper.ImGui_WindowFlags_NoCollapse()

local section = "PSP_Scripts"
local settings = {}

local is_finished = false

-----------------
--- FUNCTIONS ---
-----------------

function SetKey(text)
	reaper.SetExtState(section, "sttjsonkey", text, 1)
end

------------
--- MAIN ---
------------

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions → Reapack → Browse Packages, and install ReaImGui first.", "Error", 0) return end
if (utils.GetUsingReaImGuiVersion() ~= utils.GetInstalledReaImGuiVersion()) then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version " .. utils.GetUsingReaImGuiVersion() .. " or later", "Error", 0) return end

local text = reaper.GetExtState(section, "sttjsonkey") or ''

settings.font_size = tonumber(reaper.GetExtState(section, "SD_font_size")) or 14

local ctx = reaper.ImGui_CreateContext('Register JSON Credentials', reaper.ImGui_ConfigFlags_DockingEnable())
local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
	local rv

	if reaper.ImGui_Button(ctx, 'Apply', 100) or reaper.ImGui_IsKeyPressed(ctx, 13) then
		SetKey(text)
		is_finished = true
	end

	reaper.ImGui_SameLine(ctx)
	if reaper.ImGui_Button(ctx, 'Cancel', 100) then
		is_finished = true
	end

	local window_width = reaper.ImGui_GetWindowWidth(ctx)
	_, text = reaper.ImGui_InputTextMultiline(ctx, '', text, window_width - 17, 170)
end

function loop()
 	reaper.ImGui_PushFont(ctx, font)
  	reaper.ImGui_SetNextWindowSize(ctx, 400, 80, reaper.ImGui_Cond_FirstUseEver())
  	local visible, open = reaper.ImGui_Begin(ctx, 'Register JSON Credentials', true, window_flags)

	if is_finished then
		open = false end  

  	if visible then
    	frame() ; reaper.ImGui_End(ctx)
  	end
  	reaper.ImGui_PopFont(ctx)
  
  	if open then
    	reaper.defer(loop)
  	else
    	reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)