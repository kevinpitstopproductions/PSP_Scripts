--[[
 * ReaScript Name: PSP_Copy Item Properties.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.3
--]]

--[[
 * Changelog:
 * v1.0 (2021-05-27)
	+ Initial Release
 * v1.2 (2021-05-27)
	+ Bug Fix
 * v1.3 (2021-06-21)
	+ General Update
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES --- 

--- FUNCTIONS ---

local function SaveExtState(item_count)
	local item = reaper.GetSelectedMediaItem(0, 0)
	local take = reaper.GetActiveTake(item)

	-- todo: add support for start offset
	reaper.SetExtState( "PSP_CopyItemInfo", "rate", 		reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadein", 		reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeout", 		reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeinshape", 	reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeoutshape", reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadeinslope", 	reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "fadoutslope", 	reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR"), 1 )
	reaper.SetExtState( "PSP_CopyItemInfo", "length", 		reaper.GetMediaItemInfo_Value(item, "D_LENGTH"), 1 )
end

--- MAIN ---

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then
	if item_count > 1 then
		Msg("Multiple items selected, first item will be used.")
	end

	SaveExtState(item_count)
end