--[[
 * ReaScript Name: PSP_Set Time After Snap Offset.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v1.1 (2021-04-14)
	+ Initial Release
 * v1.2 (2021-06-21)
	+ General Update
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

ext_name = "PSP_Scripts"
ext_save = "timeaftersnapoffset"

local is_complete = false
local text = ''

--- FUNCTIONS ---

function SaveSelectedItems (item_table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    item_table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
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

if not reaper.APIExists('ImGui_Begin') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0)
    return
end

if reaper.HasExtState(ext_name, ext_save) then
	text = reaper.GetExtState(ext_name, ext_save)
else
	text = '0.1'
end

local ctx = reaper.ImGui_CreateContext('Set Time After Snap Offset', 300, 60)

function loop()
	local rv

	if (reaper.ImGui_IsCloseRequested(ctx) or is_complete) then reaper.ImGui_DestroyContext(ctx) return end

	reaper.ImGui_SetNextWindowPos(ctx, 0, 0)
	reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_GetDisplaySize(ctx))
	reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

	--- GUI BEGIN ---
	
	if (reaper.ImGui_IsAnyItemActive(ctx) ~= true) then
		reaper.ImGui_SetKeyboardFocusHere(ctx)
	end

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
		is_complete = true
	end
	
	rv, text = reaper.ImGui_InputText(ctx, 'seconds', text, reaper.ImGui_InputTextFlags_CharsDecimal())
  
	--- GUI END --

	reaper.ImGui_End(ctx)
	reaper.defer(loop)
end
reaper.defer(loop)