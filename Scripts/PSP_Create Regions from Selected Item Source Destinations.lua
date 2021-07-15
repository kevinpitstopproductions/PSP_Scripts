--[[
 * ReaScript Name: PSP_Create Regions from Selected Item Source Destinations.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.19
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v1.2 (2021-06-21)
    + General Update
 * v1.1 (2021-01-16)
	+ Initial Release
--]]

-------------
--- DEBUG ---
-------------

console = true
local function Msg(value) if console then reaper.ShowConsoleMsg(tostring(value) .. "\n") end end

-----------------
--- FUNCTIONS --- 
-----------------

function SaveSelectedItems (item_table)
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
        item_table[i+1] = reaper.GetSelectedMediaItem(0, i) end
end

function CreateRegionsFromItemTable(item_table)
    for _, item in ipairs(item_table) do
        local take = reaper.GetActiveTake(item)
        local source = reaper.GetMediaItemTake_Source(take)
        local filenamebuf = reaper.GetMediaSourceFileName( source, "" )
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local item_end = (item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" ))
      
        reaper.AddProjectMarker2( 0, true, item_start, item_end, filenamebuf:sub(4), -1, 0 )
    end
end

------------
--- Main ---
------------

local item_count = reaper.CountSelectedMediaItems(0)
local item_table = {}

if item_count > 0 then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    SaveSelectedItems(item_table)

    CreateRegionsFromItemTable(item_table)

    reaper.Undo_EndBlock("Create source named regions", -1)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end
