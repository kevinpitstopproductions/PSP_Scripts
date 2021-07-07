--[[
 * ReaScript Name: PSP_Set Time After Snap Offset.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.3
--]]

--[[
 * Changelog:
 * v1.1 (2021-04-14)
	+ Initial Release
 * v1.2 (2021-06-21)
	+ General Update
 * v1.3 (2021-07-07)
 	+ Upgraded to ReaImGui v5
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

local window_flags = 
    reaper.ImGui_WindowFlags_NoCollapse()

local ext_name = "PSP_Scripts"
local ext_save = "timeaftersnapoffset"

local is_finished = false
local text = ''

--- FUNCTIONS ---

function SaveSelectedItems (item_table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    item_table[i+1] = reaper.GetSelectedMediaItem(0, i) end
end

function OffsetNudge(item_table, text)
	-- Unselect all items so that ApplyNudge() works
	reaper.Main_OnCommand(40289, 0)
	
	for _, item in ipairs(item_table) do
		-- Select item to allow ApplyNudge()
		reaper.SetMediaItemSelected( item, true )

		-- GET
		item_snapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
		item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

		-- if item has no snap offset, only change item length
		if (item_snapoffset == nil) or (item_snapoffset == 0) then
			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", tonumber(text))
		else
			-- remove offset
			reaper.ApplyNudge(0, 0, 3, 1, (item_length - item_snapoffset), true, 0)
			-- apply new offset
			reaper.ApplyNudge(0, 0, 3, 1, tonumber(text), false, 0)
		end

		-- Deselect item before continuing
		reaper.SetMediaItemSelected( item, false )
	end
	
	-- Reselect all items in original selection
	for _, item in ipairs(item_table) do
		reaper.SetMediaItemSelected( item, true )
	end
end

--- MAIN ---

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5-beta", "Error", 0) return end

if reaper.HasExtState(ext_name, ext_save) then
	text = reaper.GetExtState(ext_name, ext_save)
else
	text = '0.1'
end

local ctx = reaper.ImGui_CreateContext('PSP_Set Time After Snap Offset', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
	local rv
	
	if (reaper.ImGui_IsAnyItemActive(ctx) ~= true) then
		reaper.ImGui_SetKeyboardFocusHere(ctx) end

	if (reaper.ImGui_Button(ctx, 'Apply') or reaper.ImGui_IsKeyPressed(ctx, 13)) then
		reaper.PreventUIRefresh(1)
		reaper.Undo_BeginBlock() -- Begining of the undo block. 
		
		local item_table =  {}
		SaveSelectedItems(item_table)
		OffsetNudge(item_table, text)
		
		reaper.Undo_EndBlock("Set time after snap offset", - 1) -- End of the undo block. 
		reaper.UpdateArrange()
		reaper.PreventUIRefresh(-1)
		
		reaper.SetExtState(ext_name, ext_save, text, true)
		is_finished = true
	end
	
	rv, text = reaper.ImGui_InputText(ctx, 'seconds', text, reaper.ImGui_InputTextFlags_CharsDecimal())
end

function loop()
    reaper.ImGui_PushFont(ctx, font)
    reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'PSP_Set Time After Snap Offset', true, window_flags)

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