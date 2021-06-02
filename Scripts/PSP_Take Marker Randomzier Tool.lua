--[[
 * ReaScript Name: Randomize Items (Take Markers)
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-02)
  + Beta Release
--]]

local console = true
local take_table = {}

local function Msg(text)
  if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end
end -- Msg

local function Main(take_table, take, take_marker_count)
  for i=0, take_marker_count-1 do
    -- GET
    local entry = {}
    local cur_take_marker, take_marker_name, _ = reaper.GetTakeMarker(take, i)
    -- SET
    entry.take_marker_start = cur_take_marker
    entry.take_marker_name = take_marker_name
    reaper.SetTakeMarker(take, i, "tk"..tostring(i+1))
    if i ~= take_marker_count-1 then
      local next_take_marker, _, _ = reaper.GetTakeMarker(take, i+1)

      entry.take_marker_length = next_take_marker-cur_take_marker
    else
      local media_source =  reaper.GetMediaItemTake_Source(take)
      local media_source_length, _ = reaper.GetMediaSourceLength(media_source)

      entry.take_marker_length = media_source_length-cur_take_marker
    end -- check if on last marker
    table.insert(take_table, entry)
  end -- loop through take markers
end -- Main

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then
  for i=0, item_count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take_count = reaper.CountTakes(item)
    if take_count > 0 then
      for t=0, take_count-1 do
        local take = reaper.GetTake(item, t)
        local take_marker_count = reaper.GetNumTakeMarkers(take)
        if take_marker_count > 0 then
          for i=0, take_marker_count-1 do

            local entry = {}
            local cur_take_marker, take_marker_name, _ = reaper.GetTakeMarker(take, i)

            entry.take_marker_start = cur_take_marker
            entry.take_marker_name = take_marker_name
            reaper.SetTakeMarker(take, i, "tk"..tostring(i+1))
            if i ~= take_marker_count-1 then
              local next_take_marker, _, _ = reaper.GetTakeMarker(take, i+1)

              entry.take_marker_length = next_take_marker-cur_take_marker
            else
              local media_source =  reaper.GetMediaItemTake_Source(take)
              local media_source_length, _ = reaper.GetMediaSourceLength(media_source)

              entry.take_marker_length = media_source_length-cur_take_marker
            end -- check if on last marker
            table.insert(take_table, entry)
          end -- LOOP through take markers
            local random_number = math.random(take_marker_count)

            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", take_table[random_number].take_marker_start)
            reaper.SetMediaItemLength(item, take_table[random_number].take_marker_length, 1)
        end -- check markers in take
      end -- LOOP through takes
    end -- check takes in item 
  end -- LOOP through items
end -- check items in selection