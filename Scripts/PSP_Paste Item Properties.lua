--[[
 * ReaScript Name: Paste Item Properties
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-05-27)
	+ Initial Release
--]]

local function Main(item_count)
	
	local rate = reaper.GetExtState( "PSP_CopyItemInfo", "rate")
	local fadein = reaper.GetExtState( "PSP_CopyItemInfo", "fadein")
	local fadeout = reaper.GetExtState( "PSP_CopyItemInfo", "fadeout")
	local fadeinshape = reaper.GetExtState( "PSP_CopyItemInfo", "fadeinshape")
	local fadeoutshape = reaper.GetExtState( "PSP_CopyItemInfo", "fadeoutshape")
	local fadeinslope = reaper.GetExtState( "PSP_CopyItemInfo", "fadeinslope")
	local fadeoutslope = reaper.GetExtState( "PSP_CopyItemInfo", "fadoutslope")
	local length = reaper.GetExtState( "PSP_CopyItemInfo", "length")
	
	for i=0, item_count-1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		
		reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PLAYRATE", rate)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadein)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeout)	
		reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", fadeinshape)	
		reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", fadeoutshape)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", fadeinslope)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", fadeoutslope)
		reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
	end -- loop through selected items
end -- Main

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then

	Main(item_count)

	reaper.UpdateArrange()

end
