--[[
 * ReaScript Name: PSP_Create Razor Edit Regions From Parent Items.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.1
--]]

--[[
 * Changelog:
 * v1.1 (2021-07-09)
 	+ Initial Release
--]]

--- DEBUG ---

local console = false

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

local re_table = {}

--- FUNCTIONS ---

--- MAIN ---

reaper.ClearConsole()

for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItemTrack(item)
    local track_index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")-1
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + item_start
    local index = track_index

    Msg("total tracks " .. reaper.CountTracks(0) .. "\n")
    Msg("Selected item is on track " .. string.format("%d",track_index))

    if reaper.GetTrack(0, track_index+1) then -- if item not on last track
        Msg("track exists after current track")
        Msg("current track depth is " .. reaper.GetTrackDepth(track))

        for j = track_index, reaper.CountTracks(0)-1 do
            if reaper.GetTrackDepth(reaper.GetTrack(0, j+1)) <= reaper.GetTrackDepth(track) then break end
            index = index + 1
        end

        Msg("last folder item for track is " .. string.format("%d",index))

        for j = track_index, index do
            Msg("add razor edits to " .. string.format("%d",j))
            track = reaper.GetTrack(0, j)

            local env_count = reaper.CountTrackEnvelopes(track)
            if env_count > 0 then
                Msg("track " .. string.format("%d",j) .. " has " .. env_count .. " envelopes")
                for e = 0, env_count-1 do
                    local env = reaper.GetTrackEnvelope(track, e)
                    local _, guid = reaper.GetSetEnvelopeInfo_String(env, "GUID", "", false)
                    re_table[track] = (re_table[track] or "") .. string.format([[%.16f %.16f "%s" ]], item_start, item_end, guid) 
                end
            end

            re_table[track] = (re_table[track] or "") .. string.format([[%.16f %.16f "" ]], item_start, item_end) 
        end
    else
        re_table[track] = (re_table[track] or "") .. string.format([[%.16f %.16f "" ]], item_start, item_end) 
    end

    for track, str in pairs(re_table) do
        reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", str, true ) end

    reaper.UpdateArrange()
end

