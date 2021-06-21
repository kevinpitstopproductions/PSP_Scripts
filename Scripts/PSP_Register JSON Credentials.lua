--[[
 * ReaScript Name: PSP_Register JSON Credentials.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.3
--]]

--[[
 * Changelog:
 * v1.0 (2021-04-14)
	+ Initial Release
 * v1.2 (2021-05-12)
	+ Bug Fixes
 * v1.3 (2021-06-21)
	+ General Update
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

ext_name = "PSP_Scripts"
ext_save = "sttjsonkey"

local is_complete = false
local text = ''

--- FUNCTIONS ---

--- MAIN ---

if not reaper.APIExists('ImGui_Begin') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0)
    return
end

if reaper.GetExtState(ext_name, ext_save) then
	text = reaper.GetExtState(ext_name, ext_save)
end

local ctx = reaper.ImGui_CreateContext('Copy / Paste JSON_CREDENTIALS', 1000, 210)

function SetKey(text)
	reaper.SetExtState(ext_name, ext_save, text, 1)
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

	--- GUI BEGIN ---

	if (reaper.ImGui_Button(ctx, 'Apply', 100) or reaper.ImGui_IsKeyPressed(ctx, 13)) then
		SetKey(text)
		is_complete = true
	end

	reaper.ImGui_SameLine(ctx)
	if (reaper.ImGui_Button(ctx, 'Cancel', 100) or reaper.ImGui_IsKeyPressed(ctx, 13)) then
		reaper.DeleteExtState(ext_name, ext_save, 1)
		is_complete = true
	end

	local window_width = reaper.ImGui_GetWindowWidth(ctx)
	rv, text = reaper.ImGui_InputTextMultiline( ctx, '', text, window_width - 17, 170 )

	--- GUI END ---
  
	reaper.ImGui_End(ctx)
	reaper.defer(loop)
end
reaper.defer(loop)