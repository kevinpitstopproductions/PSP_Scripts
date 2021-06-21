--[[
 * ReaScript Name: PSP_Convert Stretch Markers to Take Markers.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v1.1 (2021-06-02)
  + Initial Release
 * v1.2 (2021-06-21)
  + Bug Fix
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES --- 

--- FUNCTIONS ---

--- MAIN ---

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then
	for i=0, item_count-1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		local take_count = reaper.CountTakes(item)
		if take_count > 0 then
			for t=0, take_count-1 do
				local take = reaper.GetTake(item, t)
				local s_marker_count = reaper.GetTakeNumStretchMarkers(take)
				if s_marker_count > 0 then
					for s=0, s_marker_count-1 do
						local _, _, srcpos = reaper.GetTakeStretchMarker( take, s )
						reaper.SetTakeMarker( take, s, "tk"..tostring(s+1), srcpos, 0 )
					end -- LOOP through stretch markers

					--for s=s_marker_count, 0, -1 do
					reaper.DeleteTakeStretchMarkers(take, 0, s_marker_count)
					--end -- LOOP through stretch markers
				end -- check if stretch markers
			end -- LOOP through takes
		end -- check if takes
	end -- LOOP through items
end -- check if items

reaper.UpdateArrange()