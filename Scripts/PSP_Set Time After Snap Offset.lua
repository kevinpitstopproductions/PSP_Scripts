--[[
 * ReaScript Name: GU-on Set Time After Snap Offset
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-04-14)
	+ Initial Release
--]]

-- USER CONFIG AREA -----------------------------------------------------------

console = true -- true/false: display debug messages in the console

------------------------------------------------------- END OF USER CONFIG AREA

ext_name = "GU_SetTimeAfterSnapOffset"
ext_save = ""

local ctx = reaper.ImGui_CreateContext('Set Time After Snap Offset', 300, 60)
local is_complete = false

function SaveSelectedItems (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

function Main(x)
	-- Unselect all items so that ApplyNudge() works
	reaper.Main_OnCommand(40289, 0)
	
	for i, item in ipairs(init_sel_items) do
		-- Select item to allow ApplyNudge()
		reaper.SetMediaItemSelected( item, true )

		-- GET
		item_snapoffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
		item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

		-- If item doesn't have snap offset, only change item length
		if (item_snapoffset == nil) or (item_snapoffset == 0) then
			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", x)
		else
			-- remove offset
			reaper.ApplyNudge(0, 0, 3, 1, (item_length - item_snapoffset), true, 0)
			-- apply new offset
			reaper.ApplyNudge(0, 0, 3, 1, x, false, 0)
		end

		-- Deselect item before continuing
		reaper.SetMediaItemSelected( item, false )
	end
	
	-- Reselect all items in original selection
	for i, item in ipairs(init_sel_items) do
		reaper.SetMediaItemSelected( item, true )
	end
end

-- Get Ext State
if reaper.HasExtState(ext_name, "saved_val") then
	ext_save = reaper.GetExtState(ext_name, "saved_val")
else
	ext_save = 0
end

-- INIT
reaper.ImGui_SetKeyboardFocusHere(ctx)
function loop()
	local rv

	if (reaper.ImGui_IsCloseRequested(ctx) or is_complete) then
		reaper.ImGui_DestroyContext(ctx)
	return
	end

	reaper.ImGui_SetNextWindowPos(ctx, 0, 0)
	reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_GetDisplaySize(ctx))
	reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())
	
	if (reaper.ImGui_IsAnyItemActive(ctx) ~= true) then
		reaper.ImGui_SetKeyboardFocusHere(ctx)
		text = ext_save
	end

	if (reaper.ImGui_Button(ctx, 'Apply') or reaper.ImGui_IsKeyPressed(ctx, 13)) then
		reaper.PreventUIRefresh(1)
		reaper.Undo_BeginBlock() -- Begining of the undo block. 
		
		init_sel_items =  {}
		SaveSelectedItems(init_sel_items)
		Main(text)
		
		reaper.Undo_EndBlock("Set time after snap offset", - 1) -- End of the undo block. 
		reaper.UpdateArrange()
		reaper.PreventUIRefresh(-1)
		
		reaper.SetExtState(ext_name, "saved_val", tostring(text), true)
		is_complete = true
	end
	
	rv, text = reaper.ImGui_InputText(ctx, 'seconds', text, reaper.ImGui_InputTextFlags_CharsDecimal())
  
	reaper.ImGui_End(ctx)
	
	reaper.defer(loop)
end
reaper.defer(loop)