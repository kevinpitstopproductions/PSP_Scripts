--[[
 * ReaScript Name: Create Volume Trim Automation Items from Selected Items
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-05-27)
	+ Initial Release
--]]

-- CONSTANTS

_UNITYGAIN = 716.3

-- HELPERS

console = true

local function Msg(value)
    if console then
        reaper.ShowConsoleMsg(tostring(value) .. "\n")
    end
end -- Msg

-- FUNCTIONS

local function ConvertItemFadeToEnvelopeFade(shape, fadetype)
    if fadetype == "fadein" then
        if shape == 0 then return 0
        elseif shape == 1 then return 3
        elseif shape == 2 then return 4
        elseif shape == 3 then return 3
        elseif shape == 4 then return 4
        elseif shape == 5 then return 5 
        elseif shape == 6 then return 2
        else return 0 end
    end -- fadein loop

    if fadetype == "fadeout" then
        if shape == 0 then return 0
        elseif shape == 1 then return 4
        elseif shape == 2 then return 3
        elseif shape == 3 then return 4
        elseif shape == 4 then return 3
        elseif shape == 5 then return 5 
        elseif shape == 6 then return 2
        else return 0 end
    end -- fadeout loop
end -- ConvertItemFadeToEnvelopeFade

local function GetTrackList(track_list, sel_item_count)
    for i=0, sel_item_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)
        item_track = reaper.GetMediaItemTrack(item)

        if #track_list == 0 then
            table.insert(track_list, item_track)
        end

        for _, track in ipairs(track_list) do
            if track ~= item_track then table.insert(track_list, item_track) end
        end -- loop through track list
    end -- loop through selected items
end -- GetTrackList

local function ShowTrackEnvelope(envelope)
    BR_envelope = reaper.BR_EnvAlloc(envelope, false)
    local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling, automationItemsOptions = reaper.BR_EnvGetProperties(BR_envelope)
    reaper.BR_EnvSetProperties( BR_envelope, active, true, armed, inLane, laneHeight, defaultShape, faderScaling, automationItemsOptionsIn )
    reaper.BR_EnvFree( BR_envelope, true )
end --ShowTrackEnvelope  

local function ClearAutomationSelection()
    track_count = reaper.CountTracks(0)
    for t=0, track_count-1 do
        track = reaper.GetTrack(0, i)
        envelope_count = reaper.CountTrackEnvelopes(t)
            for e=0, envelope_count-1 do
                envelope = reaper.GetTrackEnvelope(track, e)
                AI_count = reaper.CountAutomationItems(envelope)
                    for a=0, AI_count-1 do
                        reaper.GetSetAutomationItemInfo(envelope, a, "D_UISEL", 0, 1)
                    end -- loop through automation items
            end -- loop through envelopes
    end -- loop through tracks
end -- ClearAutomationSelection

local function ClearAutomationItems(track_list)
    for _, track in ipairs(track_list) do
        envelope = reaper.GetTrackEnvelopeByName(track, "Trim Volume")
        AI_count = reaper.CountAutomationItems(envelope)

        ShowTrackEnvelope(envelope)

         reaper.SetEnvelopePoint( envelope, 0, 0, 0, 0, 0, 0, 0 )

        for i=AI_count, 0, -1 do
            reaper.GetSetAutomationItemInfo(envelope, i, "D_UISEL", 1, 1)
            reaper.Main_OnCommand("42086", 0)
        end -- loop through automation items
    end -- loop through tracks
end -- ClearAutomationItems

local function AddAutomationItems(sel_item_count)
    for i=0, sel_item_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)
        item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        item_end = item_start + item_length
        item_fadeinlength = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        item_fadeoutlength = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        item_fadeinshape = ConvertItemFadeToEnvelopeFade(reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE"), "fadein")
        item_fadeoutshape = ConvertItemFadeToEnvelopeFade(reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE"), "fadeout")

        track = reaper.GetMediaItem_Track(item)
        envelope = reaper.GetTrackEnvelopeByName(track, "Trim Volume")

        AI_index = reaper.InsertAutomationItem(envelope, i, item_start, item_length)
        reaper.GetSetAutomationItemInfo_String(envelope, AI_index, "P_POOL_NAME", reaper.GetTakeName(reaper.GetActiveTake(item)), 1)

        reaper.DeleteEnvelopePointRangeEx(envelope, AI_index, item_start, item_end)

        -- reaper.InsertEnvelopePointEx(envelope, autoitem_idx, time, value, shape, tension, selected, noSortIn)
        reaper.InsertEnvelopePointEx(envelope, AI_index, item_start, 0, item_fadeinshape, 0, 0, 0)
        reaper.InsertEnvelopePointEx(envelope, AI_index, item_start+item_fadeinlength, _UNITYGAIN, 0, 0, 0, 0)
        reaper.InsertEnvelopePointEx(envelope, AI_index, item_end-item_fadeoutlength, _UNITYGAIN, item_fadeoutshape, 0, 0, 0)

        reaper.GetSetAutomationItemInfo(envelope, i, "D_UISEL", 0, 1)
    end
end --AddAutomationItems

-- Init

sel_item_count = reaper.CountSelectedMediaItems(0)

if sel_item_count > 0 then

    local track_list = {}

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    GetTrackList(track_list, sel_item_count)

    ClearAutomationItems(track_list)
    AddAutomationItems(sel_item_count)

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Create Automation Items", -1)
    reaper.PreventUIRefresh(-1)

end