--[[
 * ReaScript Name: PSP_Offset Source Start to 50% Item Length.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.27
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v1.2 (2021-06-21)
	+ General Update
 * v1.1 (2021-04-19)
 	+ Initial Release
--]]

-------------
--- DEBUG ---
-------------

local console = true
local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

-----------------
--- VARIABLES ---
-----------------

-----------------
--- FUNCTIONS ---
-----------------

function SaveSelectedItems (table)
	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		table[i+1] = reaper.GetSelectedMediaItem(0, i) end
end

function OffsetTakeSource(item_table)
	for _, item in ipairs(item_table) do
		local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local take = reaper.GetActiveTake(item)
		local take_startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
		
		reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", (item_length / 2))
	end
end

------------
--- MAIN ---
------------

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then
	reaper.PreventUIRefresh(1)
	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	local item_table =  {}
	SaveSelectedItems(item_table)
	OffsetTakeSource(item_table)

	reaper.Undo_EndBlock("offset source start", - 1) -- End of the undo block. Leave it at the bottom of your main function.
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)
end
