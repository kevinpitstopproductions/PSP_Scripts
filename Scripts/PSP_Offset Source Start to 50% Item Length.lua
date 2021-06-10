--[[
 * ReaScript Name: PSP_Offset Source Start to 50% Item Length.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.1 (2021-04-19)
 	+ Initial Release
--]]

-- USER CONFIG AREA -----------------------------------------------------------

console = false -- true/false: display debug messages in the console

------------------------------------------------------- END OF USER CONFIG AREA

function SaveSelectedItems (table)
	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		table[i+1] = reaper.GetSelectedMediaItem(0, i)
	end
end

function main()
	for i, item in ipairs(init_sel_items) do
		-- get
		local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local take = reaper.GetActiveTake(item)
		local take_startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
		
		-- set
		reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", (item_length / 2))
	end
end

-- See if there is items selected
count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 0 then

	reaper.PreventUIRefresh(1)

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	init_sel_items =  {}
	SaveSelectedItems(init_sel_items)

	main()

	reaper.Undo_EndBlock("offset source start", - 1) -- End of the undo block. Leave it at the bottom of your main function.

	reaper.UpdateArrange()

	reaper.PreventUIRefresh(-1)

end
