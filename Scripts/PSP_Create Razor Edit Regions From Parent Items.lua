--[[
 * ReaScript Name: PSP_Create Razor Edit Regions From Parent Items.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-07-08)
 	+ Initial Release
--]]

--[[
P_RAZOREDITS : const char * : list of razor edit areas, as space-separated triples of start time, end time, and envelope GUID string.
Example: "0.00 1.00 \"\" 0.00 1.00 "{xyz-...}"
]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

local re_table = {}

--- FUNCTIONS ---

local function GetGUID(track, envidx)
    local _, guid = reaper.GetSetEnvelopeInfo_String(reaper.GetTrackEnvelope(track, envidx), "GUID", "", false) return guid end

--- MAIN ---

local function Main(re_table)
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItemTrack(item)
        local track_index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        local track_depth = 1
        local top_track_depth = reaper.GetTrackDepth(track)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + item_start

        for e=0, reaper.CountTrackEnvelopes(track)-1 do
            re_table[track] = (re_table[track] or "") .. string.format([[%.16f %.16f "%s" ]], item_start, item_end, GetGUID(track, e)) end

        while (track_depth > top_track_depth) and (track_index < reaper.CountTracks(0)) do
            track_index = track_index + 1
            track_depth = reaper.GetTrackDepth(reaper.GetTrack(0, track_index))
        end

        for j=reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"), track_index do
            track = reaper.GetTrack(0, j-1)
            re_table[track] = (re_table[track] or "") .. string.format([[%.16f %.16f "" ]], item_start, item_end) 
        end
    end

    for track, str in pairs(re_table) do
        reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", str, true ) end
end

if reaper.CountSelectedMediaItems(0) > 0 then
    Main(re_table)
end