--[[
 * ReaScript Name: Copy Item Properties
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.0 (2021-05-27)
	+ Initial Release
 * v1.1 (2021-05-27)
	+ Bug Fix
--]]

local function SaveSelectedItems (init_table, item_count)
	for i = 0, item_count-1 do
		local entry = {}

		entry.item = reaper.GetSelectedMediaItem(0, i)
		entry.rate = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(entry.item), "D_PLAYRATE")	
		entry.fadein = reaper.GetMediaItemInfo_Value(entry.item, "D_FADEINLEN")	
		entry.fadeout = reaper.GetMediaItemInfo_Value(entry.item, "D_FADEOUTLEN")	
		entry.fadeinshape = reaper.GetMediaItemInfo_Value(entry.item, "C_FADEINSHAPE")	
		entry.fadeoutshape = reaper.GetMediaItemInfo_Value(entry.item, "C_FADEOUTSHAPE")	
		entry.fadeinslope = reaper.GetMediaItemInfo_Value(entry.item, "D_FADEINDIR")	
		entry.fadeoutslope = reaper.GetMediaItemInfo_Value(entry.item, "D_FADEOUTDIR")
		entry.length = reaper.GetMediaItemInfo_Value(entry.item, "D_LENGTH")

		table.insert(init_table, entry)
	end -- item count
end --SaveSelectedItems

local function Main(init_table, item_count)
	SaveSelectedItems(init_table, item_count)

	reaper.SetExtState( "PSP_CopyItemInfo", "fadein", init_table[1].fadein, 1)
	reaper.SetExtState( "PSP_CopyItemInfo", "rate", init_table[1].rate, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadein", init_table[1].fadein, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeout", init_table[1].fadeout, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeinshape", init_table[1].fadeinshape, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeoutshape", init_table[1].fadeoutshape, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeinslope", init_table[1].fadeinslope, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadoutslope", init_table[1].fadeoutslope, 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "length", init_table[1].length, 1 )
end -- Main

local init_table = {}

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then

	Main(init_table, item_count)
	
end