--[[
 * ReaScript Name: PSP_Set Time Before Snap Offset.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v1.0 (2021-04-14)
	+ Initial Release
 * v1.1 (2021-04-28)
	+ Bug Fixes
 * v1.2 (2021-06-21)
	+ General Update
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

ext_name = "PSP_Scripts"
ext_save = "timebeforesnapoffset"

local is_complete = false
local text = ''

--- FUNCTIONS ---

function SaveSelectedItems (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

function OffsetNudge(item_table, text)
	-- Unselect all items so that ApplyNudge() works
	reaper.Main_OnCommand(40289, 0)
	
	for _, item in ipairs(item_table) do
		-- Select item to allow ApplyNudge()
		reaper.SetMediaItemSelected( item, true )     

		-- GET
		local item_snapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
		
		-- remove offset
		reaper.ApplyNudge(0, 0, 1, 1, item_snapoffset, false, 0)
		reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", 0)
		
		-- apply new offset
		reaper.ApplyNudge(0, 0, 1, 1, tonumber(text), true, 0)
		reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", tonumber(text))

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

local ctx = reaper.ImGui_CreateContext('Set Time Before Snap Offset', 300, 60)

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
		
		reaper.Undo_EndBlock("Set time before snap offset", - 1) -- End of the undo block. 
		reaper.UpdateArrange()
		reaper.PreventUIRefresh(-1)
		
		reaper.SetExtState(ext_name, ext_save, text, true)
		is_complete = true
	end
	
	rv, text = reaper.ImGui_InputText(ctx, 'seconds', text, reaper.ImGui_InputTextFlags_CharsDecimal())
  
  	--- GUI END ---

	reaper.ImGui_End(ctx)
	reaper.defer(loop)
end
reaper.defer(loop)