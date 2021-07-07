--[[
 * ReaScript Name: PSP_Create Volume Trim Automation Items from Selected Items.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.5
--]]

--[[
 * Changelog:
 * v1.0 (2021-05-28)
	+ Initial Release
 * v1.1 (2021-05-28)
    + Bug Fix
 * v1.3 (2021-06-08)
    + Added config option (mute env behind automation items)
 * v1.4 (2021-06-21)
	+ General Update
 * v1.5 (2021-07-07)
    + Fixed to work with selection across multiple tracks
--]]

--- DEBUG ---

console = true

local function Msg(value) if console then reaper.ShowConsoleMsg(tostring(value) .. "\n") end end

--- VARIABLES ---

_UNITYGAIN = 716.3

local section = "PSP_Scripts"
local settings = {}

--- FUNCTIONS ---

local function toboolean(text)
  if text == "true" then return true
  else return false end
end

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
    end
    if fadetype == "fadeout" then
        if shape == 0 then return 0
        elseif shape == 1 then return 4
        elseif shape == 2 then return 3
        elseif shape == 3 then return 4
        elseif shape == 4 then return 3
        elseif shape == 5 then return 5 
        elseif shape == 6 then return 2
        else return 0 end
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then return true end end return false
end

local function GetTrackList(track_list, item_count)
    for i=0, item_count-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)

        if #track_list == 0 then
            table.insert(track_list, track) end

        for _, spot in ipairs(track_list) do
            if not table.contains(track_list, track) then table.insert(track_list, track) end end
    end
end

local function ShowTrackEnvelope(track, envelope)
    local _, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)

    BR_envelope = reaper.BR_EnvAlloc(envelope, false)
    active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling, automationItemsOptions = reaper.BR_EnvGetProperties( BR_envelope )
    reaper.BR_EnvSetProperties(BR_envelope, true, true, armed, inLane, laneHeight, defaultShape, faderScaling, automationItemsOptionsIn)
    reaper.BR_EnvFree(BR_envelope, true)
end

local function ClearAutomationSelection()
    local track_count = reaper.CountTracks(0)
    for t=0, track_count-1 do
        local track = reaper.GetTrack(0, t)
        local envelope_count = reaper.CountTrackEnvelopes(track)
        for e=0, envelope_count-1 do
            local envelope = reaper.GetTrackEnvelope(track, e)
            local AI_count = reaper.CountAutomationItems(envelope)
            for a=0, AI_count-1 do
                reaper.GetSetAutomationItemInfo(envelope, a, "D_UISEL", 0, 1) end
        end
    end
end

local function ClearAutomationItems(track_list)
    for _, track in ipairs(track_list) do
        reaper.SetOnlyTrackSelected(track)
        reaper.Main_OnCommand("42020", 0) -- Track: Toggle track trim envelope visible

        local envelope = reaper.GetTrackEnvelopeByName(track, "Trim Volume")
        if envelope then
            local AI_count = reaper.CountAutomationItems(envelope)

            ShowTrackEnvelope(track, envelope) 

            if settings.mute_envelope then reaper.SetEnvelopePoint( envelope, 0, 0, 0, 0, 0, 0, 0 ) end

            for i=AI_count-1, 0, -1 do
                reaper.GetSetAutomationItemInfo(envelope, i, "D_UISEL", 1, 1)
                reaper.Main_OnCommand("42086", 0) -- Envelope: Delete automation items
            end
        end
    end
end

local function AddAutomationItems(item_count)
    for i=0, item_count-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take_name = reaper.GetTakeName(reaper.GetActiveTake(item))
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_end = item_start + item_length
        local item_fadeinlength = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        local item_fadeoutlength = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        local item_fadeinshape = ConvertItemFadeToEnvelopeFade(reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE"), "fadein")
        local item_fadeoutshape = ConvertItemFadeToEnvelopeFade(reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE"), "fadeout")
	
        local track =  reaper.GetMediaItem_Track( item )
        local envelope = reaper.GetTrackEnvelopeByName(track, "Trim Volume")

        if envelope then
            local AI_index = reaper.InsertAutomationItem(envelope, -1, item_start, item_length)
            
            local retval, AI_name = reaper.GetSetAutomationItemInfo_String(envelope, AI_index, "P_POOL_NAME", take_name, 1)
            if retval then
                reaper.DeleteEnvelopePointRangeEx(envelope, AI_index, item_start, item_end)

                -- reaper.InsertEnvelopePointEx(envelope, autoitem_idx, time, value, shape, tension, selected, noSortIn)
                reaper.InsertEnvelopePointEx(envelope, AI_index, item_start, 0, item_fadeinshape, 0, 0, 0)
                reaper.InsertEnvelopePointEx(envelope, AI_index, item_start+item_fadeinlength, _UNITYGAIN, 0, 0, 0, 0)
                reaper.InsertEnvelopePointEx(envelope, AI_index, item_end-item_fadeoutlength, _UNITYGAIN, item_fadeoutshape, 0, 0, 0)

                reaper.GetSetAutomationItemInfo(envelope, AI_index, "D_UISEL", 0, 1)
            end
        end
    end
end

--- MAIN ---

if reaper.HasExtState(section, "SD_mute_envelope") then 
    settings.mute_envelope = toboolean(reaper.GetExtState(section, "SD_mute_envelope")) else
    settings.mute_envelope = false end

local item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then

    local track_list = {}

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    GetTrackList(track_list, item_count)

    ClearAutomationSelection()
    ClearAutomationItems(track_list)
    AddAutomationItems(item_count)

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Create Automation Items", -1)
    reaper.PreventUIRefresh(-1)

end