--[[
 * ReaScript Name: PSP_Paste Item Properties.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.1 (2021-05-27)
	+ Initial Release
 * v1.2 (2021-06-21)
	+ General Update
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES --- 

--- FUNCTIONS ---

local function SetItemProperties(item_count)
	-- GET
	local rate = reaper.GetExtState( "PSP_CopyItemInfo", "rate")
	local fadein = reaper.GetExtState( "PSP_CopyItemInfo", "fadein")
	local fadeout = reaper.GetExtState( "PSP_CopyItemInfo", "fadeout")
	local fadeinshape = reaper.GetExtState( "PSP_CopyItemInfo", "fadeinshape")
	local fadeoutshape = reaper.GetExtState( "PSP_CopyItemInfo", "fadeoutshape")
	local fadeinslope = reaper.GetExtState( "PSP_CopyItemInfo", "fadeinslope")
	local fadeoutslope = reaper.GetExtState( "PSP_CopyItemInfo", "fadoutslope")
	local length = reaper.GetExtState( "PSP_CopyItemInfo", "length")
	
	-- SET
	for i=0, item_count-1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		local take = reaper.GetActiveTake(item)
		
		-- todo: add support for start offset
		reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", rate)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadein)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeout)	
		reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", fadeinshape)	
		reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", fadeoutshape)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", fadeinslope)	
		reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", fadeoutslope)
		reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
	end
end

--- MAIN ---

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    SetItemProperties(item_count)

    reaper.Undo_EndBlock("undo action", -1)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end
