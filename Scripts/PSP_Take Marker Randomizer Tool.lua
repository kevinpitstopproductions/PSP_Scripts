--[[
 * ReaScript Name: PSP_Take Marker Randomizer Tool.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.1 (2021-06-21)
    + General Update
 * v0.4 (2021-06-07)
    + Bug Fixes
 * v0.2 (2021-06-03)
	+ Beta Release
--]]

-------------
--- DEBUG ---
-------------

local console = false
local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

-----------------
--- VARIABLES ---
-----------------

local section = "PSP_Scripts"
local settings = {}

local function toboolean(text)
    if text == "true" then return true
    else return false end
end

------------
--- MAIN ---
------------

settings.is_random = toboolean(reaper.GetExtState(section, "SD_is_random")) or false
settings.chop_end = reaper.GetExtState(section, "SD_chop_end") or 0

local take_table = {}
local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then
    for i=0, item_count-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_start_offs = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
        local take_count = reaper.CountTakes(item)
        if take_count > 0 then
            for t=0, take_count-1 do
                local take = reaper.GetTake(item, t)
                local take_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
                local take_marker_count = reaper.GetNumTakeMarkers(take)
                local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                local last_take = 0
                if take_marker_count > 0 then
                    for m=0, take_marker_count-1 do
                        local entry = {}
                        local cur_take_marker, take_marker_name, _ = reaper.GetTakeMarker(take, m)

                        entry.take_marker_start = cur_take_marker
                        entry.take_marker_name = take_marker_name
                        reaper.SetTakeMarker(take, m, "tk"..tostring(m+1))

                        if m ~= take_marker_count-1 then
                            local next_take_marker, _, _ = reaper.GetTakeMarker(take, m+1)
                            entry.take_marker_length = next_take_marker-cur_take_marker
                        else
                            local media_source =  reaper.GetMediaItemTake_Source(take)
                            local media_source_length, _ = reaper.GetMediaSourceLength(media_source)
                            entry.take_marker_length = media_source_length-cur_take_marker
                        end

                        table.insert(take_table, entry)
                        local diff = math.abs(take_offset-(cur_take_marker-(item_start_offs*take_rate)))

                        if diff < 0.00001 then
                            last_take = string.gsub(take_marker_name, "tk", "")
                            last_take = tonumber(last_take)
                        end
                    end

                    if settings.is_random then 
                        local random_number = 0

                        repeat random_number = math.random(take_marker_count) 
                            until random_number ~= last_take -- avoid randomizing to same take marker

                        reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", take_table[random_number].take_marker_start - (item_start_offs*take_rate))
                        reaper.SetMediaItemLength(item, (take_table[random_number].take_marker_length/take_rate) + item_start_offs - settings.chop_end, 1)
                    else
                        if last_take == #take_table then -- if at end of table, start from 1 again
                            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", take_table[1].take_marker_start - (item_start_offs*take_rate))
                            reaper.SetMediaItemLength(item, (take_table[1].take_marker_length/take_rate) + item_start_offs - settings.chop_end, 1)
                        else
                            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", take_table[last_take+1].take_marker_start - (item_start_offs*take_rate))
                            reaper.SetMediaItemLength(item, (take_table[last_take+1].take_marker_length/take_rate) + item_start_offs - settings.chop_end, 1)
                        end
                    end

                    for p=#take_table, 0, -1 do
                        table.remove(take_table, p) end
                end
            end
        end 
    end
end

reaper.UpdateArrange()