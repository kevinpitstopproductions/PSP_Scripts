--[[
 * ReaScript Name: PSP_Register JSON Credentials.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.4.1
--]]

--[[
 * Changelog:
 * v1.0 (2021-04-14)
	+ Initial Release
 * v1.2 (2021-05-12)
	+ Bug Fixes
 * v1.3 (2021-06-21)
	+ General Update
 * v1.4 (2021-07-07) 
 	+ Upgraded to ReaImGui v5
 * v1.4.1 (2021-07-08)
    + Better error message
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

local window_flags = 
    reaper.ImGui_WindowFlags_NoCollapse()

local ext_name = "PSP_Scripts"
local ext_save = "sttjsonkey"

local is_finished = false
local text = ''

--- FUNCTIONS ---

--- MAIN ---

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5 or later", "Error", 0) return end

if reaper.GetExtState(ext_name, ext_save) then
	text = reaper.GetExtState(ext_name, ext_save) end

local ctx = reaper.ImGui_CreateContext('Register JSON Credentials', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

function SetKey(text)
	reaper.SetExtState(ext_name, ext_save, text, 1) end

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
	_, text = reaper.ImGui_InputTextMultiline( ctx, '', text, window_width - 17, 170 )
end

function loop()
 	reaper.ImGui_PushFont(ctx, font)
  	reaper.ImGui_SetNextWindowSize(ctx, 400, 80, reaper.ImGui_Cond_FirstUseEver())
  	local visible, open = reaper.ImGui_Begin(ctx, 'Register JSON Credentials', true, window_flags)

	if is_finished then
		open = false end  
  	if visible then
    	frame()
    	reaper.ImGui_End(ctx)
  	end
  	reaper.ImGui_PopFont(ctx)
  
  	if open then
    	reaper.defer(loop)
  	else
    	reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)