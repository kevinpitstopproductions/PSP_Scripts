--[[
 * ReaScript Name: Create Regions for Each Item from Source Destination Names
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.19
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-01-16)
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

  -- INITIALIZE loop through selected items
  for i, item in ipairs(init_sel_items) do
	-- GET
	take = reaper.GetActiveTake(item)
	source = reaper.GetMediaItemTake_Source(take)
	filenamebuf = reaper.GetMediaSourceFileName( source, "" )
	item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
	item_end = (item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" ))
	
	-- Create Regions
	
	reaper.AddProjectMarker2( 0, true, item_start, item_end, filenamebuf:sub(4), -1, 0 )
  end
end

-- INIT

-- See if there is items selected
count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 0 then

  reaper.PreventUIRefresh(1)

  reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

  init_sel_items =  {}
  SaveSelectedItems(init_sel_items)

  main()

  reaper.Undo_EndBlock("Create source named regions", - 1) -- End of the undo block. Leave it at the bottom of your main function.

  reaper.UpdateArrange()

  reaper.PreventUIRefresh(-1)

end