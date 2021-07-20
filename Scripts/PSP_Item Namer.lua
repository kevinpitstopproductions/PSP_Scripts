--[[
 * ReaScript Name: PSP_Item Namer.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.32
 * Version: 0.2
--]]

--[[
 * Changelog:
 * v0.2 (2021-07-20)
    + Added preset saving/loading
 * v0.1 (2021-06-21)
    + Initial Release
--]]

--[[
todo:

add option to chose own delimiter
add option to set trailing zeros

--]]

----------------
--- INCLUDES ---
----------------

local scripts_directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(scripts_directory .. "PSP_Utils.lua") -- load shared utilities

-------------
--- DEBUG ---
-------------

local console = true
local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

-----------------
--- VARIABLES ---
-----------------

local section = "PSP_Scripts"
local settings = {}
itemaliasext = {} -- define "class"

local window_flags =
    reaper.ImGui_WindowFlags_NoCollapse()|
    reaper.ImGui_WindowFlags_MenuBar()

local marker_table = {}
local region_table = {}

local input_string = ''
local final_string = ''
local NA = "*No Item selected*" --[[const]]--

local tooltip = {}
tooltip.trackvar = 0

-----------------
--- FUNCTIONS ---
-----------------

local function GetOutermostParentTrack(track)
    local current_track = track
    local depth = 0
    while reaper.GetParentTrack( current_track ) do
        current_track = reaper.GetParentTrack(current_track) 
        depth = depth + 1
    end
    return current_track, depth
end

local function GetTrackAtLevel(track, level)
    local _, depth = GetOutermostParentTrack(track)
    local current_track = track
    while reaper.GetTrackDepth(current_track) ~= (depth-level) and reaper.GetParentTrack(current_track) do
        current_track = reaper.GetParentTrack(current_track)
    end
    local _, track_name = reaper.GetTrackName(current_track)
    return track_name
end

local function GetItemRegionOrMarker( pos, isregion )
    local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( 0, pos )
    if isregion then
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )
        return name
    else
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( markeridx )
        return name
    end
end

local function ParseString(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match) end
    return result
end

local function CreateMarkerRegionList(marker_table, region_table)
    local mr_count, num_markers, num_regions = reaper.CountProjectMarkers( 0 )

    for i=0, mr_count-1 do
        local entry = {}
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)

        entry.index = markrgnindexnumber
        entry.pos = pos
        entry.name = name

        if isrgn then
            entry.rgnend = rgnend
            table.insert(region_table, entry)
        else
            table.insert(marker_table, entry) end
    end
end

local function GetRegionWithTag(tag, start_pos)
    for _, region in ipairs(region_table) do
        if region.pos <= start_pos and region.rgnend >= start_pos then
            if region.name:find(tag .. "=") then
                return region.name:gsub(tag .. "=", "") end end end
end

local function EnumerateFX(fx_count, item, delimiter)
    delimiter = delimiter or "_"
    local fx_string = ''
    for j=0, fx_count-1 do
        local _, buf = reaper.TakeFX_GetFXName(reaper.GetActiveTake(item), j, '')

        local first = buf:find("%:") + 2
        local last = #buf
        if buf:find("%(") then
            last = buf:find("%(") - 2 end
        buf = buf:sub(first, last)

        if j+1 == fx_count then
            fx_string = fx_string .. buf
        else
            fx_string = fx_string .. buf .. delimiter end
    end return fx_string
end

local function GetTempoAndTimeSignature(item_start_pos)
    local tempo_table = {}
    local index = reaper.CountTempoTimeSigMarkers(0)-1
    local retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, index )
    while timepos > item_start_pos and index ~= 0 do
        index = index-1
        retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, index )
    end

    local bpcurrent, bpi
    if timesig_num <= 0 then
       bpcurrent, bpi = reaper.GetProjectTimeSignature2(0)
       timesig_num = bpi
    end

    if timesig_denom <= 0 then
        _, timesig_denom, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, 0 )
    end

    if bpm <= 0 then bpm = reaper.Master_GetTempo() end -- if there are no tempo markers, get main tempo + time sig

    table.insert(tempo_table, string.format("%d",tostring(bpm)))
    table.insert(tempo_table, string.format("%d",tostring(timesig_num)) .. "-" .. string.format("%d",tostring(timesig_denom)))

    return tempo_table
end

function reaper.NF_AnalyzeTakeLoudness_IntegratedOnly_Out(take)
    retval, lufsIntegrated = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take)
    return string.format("%.2f", lufsIntegrated)
end

function reaper.GetTrackName_Out(track)
    retval, buf = reaper.GetTrackName(track)
    return buf
end

local function MenuItem(ctx, wildcard, tooltip, selector)
    selector = selector or 0
    if reaper.ImGui_MenuItem(ctx, wildcard, nil) then
        input_string = input_string .. wildcard end
    
    if reaper.ImGui_IsItemHovered(ctx) then
        local vertical = reaper.ImGui_GetMouseWheel(ctx)
        if vertical > 0 then
            selector = selector + 1 end
        if vertical < 0 then
            selector = selector - 1 end
        reaper.ImGui_SetNextWindowSize(ctx, 200, 0.0)
        reaper.ImGui_BeginTooltip(ctx)
        reaper.ImGui_PushTextWrapPos(ctx, 0.0)
        reaper.ImGui_Text(ctx, tooltip)
        reaper.ImGui_PopTextWrapPos(ctx) 
        reaper.ImGui_EndTooltip(ctx)
    end

    if selector < 0 then selector = 0 end

    return selector
end

local function SavePreset(text, preset_letter)
    reaper.SetExtState(section, "SD-in_wildcard_string" .. preset_letter, text, 1)
end

local function LoadPreset(preset_letter)
    return reaper.GetExtState(section, "SD-in_wildcard_string" .. preset_letter) or ''
end

local function MenuItemSavePreset(ctx ,text, letter)
    if reaper.ImGui_MenuItem(ctx, 'Preset ' .. letter, nil, false) then 
        SavePreset(text, letter) end
end

local function MenuItemLoadPreset(ctx, letter)
    local text = LoadPreset(letter)
    local rv = reaper.ImGui_MenuItem(ctx, 'Preset ' .. letter, nil, false)
    local is_clicked = reaper.ImGui_IsItemEdited( ctx )
    local should_process = true
    if reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_SetTooltip(ctx, LoadPreset(letter)) end
    return is_clicked, text 
end

local function GetCurrentTooltips()
    local item_count = reaper.CountSelectedMediaItems(0)
    local item_notes = NA
    local item_number = NA
    local take_name  = NA
    local track_name = NA
    local track_number = NA
    local parentest_track = NA
    local track_depth0, track_depth1 = NA, NA
    local fx_name, fxX_name = "*No FX*", "*No FX*"
    local region_name, marker_name = "*No Region*", "*No Marker*"
    local tempo, time_signature = NA, NA
    if item_count > 0 then
        local item = reaper.GetSelectedMediaItem(0, 0)
        local take = reaper.GetActiveTake(item)
        local item_track = reaper.GetMediaItem_Track(item)
        local fx_count = reaper.TakeFX_GetCount(reaper.GetActiveTake(item))
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_notes = reaper.ULT_GetMediaItemNote(item)
        if item_notes == '' then item_notes="*No Notes*" end
        _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", '', 0)
        _, track_name = reaper.GetTrackName(item_track)
        track_number = math.floor(reaper.GetMediaTrackInfo_Value(item_track, "IP_TRACKNUMBER"))
        _, parentest_track = reaper.GetTrackName(GetOutermostParentTrack(item_track))
        track_depth = GetTrackAtLevel(item_track, tooltip.trackvar)
        region_name = GetItemRegionOrMarker(item_pos, true) ; marker_name = GetItemRegionOrMarker(item_pos, false)
        if region_name == '' then region_name = "*No Region*" end
        if marker_name == '' then marker_name = "*No Marker*" end
        item_number = math.floor(reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")+1)
        tempo = GetTempoAndTimeSignature(item_pos)[1]
        time_signature = GetTempoAndTimeSignature(item_pos)[2]
        if fx_count > 0 then
            fx_name = EnumerateFX(fx_count, item)
            fxX_name = EnumerateFX(fx_count, item, "-")
        end
    end
-------------------------
-- Project Information --
-------------------------
    tooltip.project = "Name of current Project. This is the name of the .rpp on disk\n\n" .. reaper.GetProjectName(0, '')
    tooltip.author = "Name of Project Author. Set in Project Settings->Notes\n\n" .. reaper.GetSetProjectAuthor(0, 0, '')
    tooltip.tracknumber = "Number of Track that Item is on\n\n" .. track_number
    tooltip.track = "Name of Track that Item is on\n\n" .. track_name
    tooltip.trackX = "Name of Track that is x levels higher than Item's current Track. X is capped at outermost Track\n\n*supports mousewheel scroll*\n\n" .. 
        "track at (" .. tooltip.trackvar .. ") is: " .. (track_depth or NA)
    tooltip.parentest = "Name of outermost parent Track for Item\n\n" .. parentest_track
    tooltip.regionX = "Name of Region surrounding Item whose tag prepended by \"=\" is specifed in brackets\n\n" ..
        "e.g. If a Region is named \"type=drum\"\nusing wildcard \"$region(type)\"\nwill produce the result \"drum\""
    tooltip.region = "Name of Region whose start position is nearest to the left edge of Item's edge\n\n" .. region_name
    tooltip.marker = "Name of Marker nearest to the left of Item's left edge\n\n" .. marker_name
    tooltip.tempo = "Tempo marker BPM value nearest to the left of Item's left edge\n\n" .. tempo
    tooltip.timesignature = "Tempo marker time signature value nearest to the left edge of a given Item\n\n" .. time_signature
    tooltip.fxX = "A list of all FX on Item, separated by a custom character\n\n" .. fxX_name
    tooltip.fx = "A list of all FX on Item, separated by underscores\n\n" .. fx_name
-------------------
-- Project Order --
-------------------
    tooltip.itemcount = "Total quantity of selected Items\n\n" .. item_count
    tooltip.itemindex = "Index of Item in selection\n\n" .. 1
----------------------------
-- Media Item Information --
----------------------------
    tooltip.item = "Name of Item's Active Take\n\n" .. take_name
    tooltip.itemnumber = "Index of Item on Track\n\n" .. item_number
    tooltip.itemnotes = "String consisting of Item's Notes\n\n" .. item_notes
---------------
-- Date/Time --
--------------- 
    tooltip.time = "The current time as hh-mm-ss\n\n" .. os.date("%H" .. "-" .. "%M" .. "-" .. "%S")
    tooltip.date = "The current date as YY-MM-DD\n\n" .. os.date("%Y" .. "-" .."%m" .. "-" .. "%d")
    tooltip.year2 = "The current year as YY\n\n" .. os.date("%y") 
    tooltip.year = "The current year as YYYY\n\n" .. os.date("%Y")
    tooltip.monthname = "The current month's name\n\n" .. os.date("%b")
    tooltip.month = "The current month as MM\n\n" .. os.date("%m")
    tooltip.dayname = "The current day's name\n\n" .. os.date("%a") 
    tooltip.day = "The current day as DD\n\n" .. os.date("%d")
    tooltip.hour12 = "The current hour in 12 hour format\n\n" .. os.date("%I")
    tooltip.hour = "The current hour in 24 hour format\n\n" .. os.date("%H")
    tooltip.ampm = "The current time of day as AM or PM\n\n" .. os.date("%p")
    tooltip.minute = "The current minute as mm\n\n" .. os.date("%M")
    tooltip.second = "The current second as ss\n\n" .. os.date("%S")
--------------
-- Metering --
--------------
    tooltip.lufs = "Integrated loudness of Item as dBFS"
    tooltip.peak = "Max peak value of all active channels of an audio item active take, post item gain, post take volume envelope, post-fade, pre fader, pre item FX"
    tooltip.rms = "Returns the average overall (non-windowed) RMS level of active channels of an audio item active take, post item gain, post take volume envelope, post-fade, pre fader, pre item FX"
end

local function main()
    local item_count = reaper.CountSelectedMediaItems(0)
    CreateMarkerRegionList(marker_table, region_table)

    if item_count > 0 then
        local temp_table = ParseString(input_string, "_")

        for i=0, item_count-1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + item_start

            for j, tag in ipairs(temp_table) do
                local new_string = ''
                local item_track = reaper.GetMediaItem_Track(item)
                local _, track_name = reaper.GetTrackName(item_track)
                local fx_count = reaper.TakeFX_GetCount(reaper.GetActiveTake(item))
-------------------------
-- Project Information --
-------------------------
                tag = tag:gsub("$project", reaper.GetProjectName(0, ''))
                tag = tag:gsub("$author", reaper.GetSetProjectAuthor(0, 0, '' ))
                tag = tag:gsub("$tracknumber", math.floor(reaper.GetMediaTrackInfo_Value(item_track, "IP_TRACKNUMBER")))
                tag = tag:gsub("$track%((%d)%)", function(n) return GetTrackAtLevel(item_track, n) end)
                tag = tag:gsub("$track", track_name)
                tag = tag:gsub("$parentest", reaper.GetTrackName_Out(GetOutermostParentTrack(item_track)))
                tag = tag:gsub("$region%((.+)%)", function(n) return GetRegionWithTag(n, item_start) end)
                tag = tag:gsub("$region", GetItemRegionOrMarker(item_start, true))
                tag = tag:gsub("$marker", GetItemRegionOrMarker(item_start, false))
                tag = tag:gsub("$tempo", GetTempoAndTimeSignature(item_start)[1])
                tag = tag:gsub("$timesignature", GetTempoAndTimeSignature(item_start)[2])
                tag = tag:gsub("$fx%[(.)%]", function(n) return EnumerateFX(fx_count, item, tostring(n)) end)
                tag = tag:gsub("$fx", EnumerateFX(fx_count, item))
-------------------
-- Project Order --
-------------------
                tag = tag:gsub("$itemcount", item_count)
                tag = tag:gsub("$itemindex", i+1)
                --> TODO: track-terminiated count
                --> TODO: region-terminated count (per track)
                --> TODO: marker-terminated count (per track)
                --> TODO: custom iterator count
----------------------------
-- Media Item Information --
----------------------------
                tag = tag:gsub("$itemnumber", math.floor(reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")+1))
                tag = tag:gsub("$itemnotes", reaper.ULT_GetMediaItemNote(item))
                tag = tag:gsub("$item", reaper.GetTakeName(reaper.GetActiveTake(item)))
                -- takemarker[x]
                -- takemarker
---------------
-- Date/Time --
---------------
                tag = tag:gsub("$time", os.date("%H" .. "-" .. "%M" .. "-" .. "%S"))
                tag = tag:gsub("$date", os.date("%Y" .. "-" .."%m" .. "-" .. "%d"))
                tag = tag:gsub("$year2", os.date("%y"))
                tag = tag:gsub("$year", os.date("%Y"))
                tag = tag:gsub("$monthname", os.date("%b"))
                tag = tag:gsub("$month", os.date("%m"))
                tag = tag:gsub("$dayname", os.date("%a"))
                tag = tag:gsub("$day", os.date("%d"))
                tag = tag:gsub("$hour12", os.date("%I"))
                tag = tag:gsub("$hour", os.date("%H"))
                tag = tag:gsub("$ampm", os.date("%p"))
                tag = tag:gsub("$minute", os.date("%M"))
                tag = tag:gsub("$second", os.date("%S"))
-------------------
-- LUFS/RMS/Peak --
-------------------
                if tag:find("$lufs") then tag = tag:gsub("$lufs", reaper.NF_AnalyzeTakeLoudness_IntegratedOnly_Out(reaper.GetActiveTake(item))) end
                if tag:find("$peak") then tag = tag:gsub("$peak", string.format("%.2f", reaper.NF_GetMediaItemMaxPeak(item))) end
                if tag:find("$rms") then tag = tag:gsub("$rms", string.format("%.2f", reaper.NF_GetMediaItemAverageRMS(item))) end
----------------
-- Write Tags --
----------------
                if j < #temp_table then
                    final_string = final_string .. tag .. "_" 
                else
                    final_string = final_string .. tag end
            end

            reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake(item), "P_NAME", final_string, 1 )
            final_string = ''
        end
    end
end

--------------
--- PUBLIC ---
--------------

function itemaliasext.ItemNamer(preset_letter)
    input_string =LoadPreset(preset_letter)
    main()
end

------------
--- MAIN ---
------------

local function GUI_MODE()
    if not reaper.APIExists('ImGui_GetVersion') then
        reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions → Reapack → Browse Packages, and install ReaImGui first.", "Error", 0) return end
    if (utils.GetUsingReaImGuiVersion() ~= utils.GetInstalledReaImGuiVersion()) then
        reaper.ShowMessageBox("Please ensure that you are running ReaImGui version " .. utils.GetUsingReaImGuiVersion() .. " or later", "Error", 0) return end

    settings.font_size = tonumber(reaper.GetExtState(section, "SD_font_size")) or 14

    local ctx = reaper.ImGui_CreateContext('Item Namer', reaper.ImGui_ConfigFlags_DockingEnable())
    local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
    reaper.ImGui_AttachFont(ctx, font)

    function frame()
        local rv

    --[[Wildcards]]--
        if reaper.ImGui_BeginMenuBar(ctx) then
            if reaper.ImGui_BeginMenu(ctx, 'Wildcards') then
                GetCurrentTooltips()
    ---[[Project Information]]---
                if reaper.ImGui_BeginMenu(ctx, 'Project Information') then
                    MenuItem(ctx, '$project', tooltip.project)
                    MenuItem(ctx, '$author', tooltip.author)
                    MenuItem(ctx, '$tracknumber', tooltip.tracknumber)
                    MenuItem(ctx, '$track', tooltip.track)
                    tooltip.trackvar = MenuItem(ctx, '$track(' .. tooltip.trackvar .. ')', tooltip.trackX, tooltip.trackvar)
                    MenuItem(ctx, '$parentest', tooltip.parentest)
                    MenuItem(ctx, '$region', tooltip.region)
                    MenuItem(ctx, '$region(name)', tooltip.regionX)
                    MenuItem(ctx, '$marker', tooltip.marker)
                    MenuItem(ctx, '$tempo', tooltip.tempo)
                    MenuItem(ctx, '$timesignature', tooltip.timesignature)
                    MenuItem(ctx, '$fx', tooltip.fx)
                    MenuItem(ctx, '$fx[-]', tooltip.fxX)
                    reaper.ImGui_EndMenu(ctx) 
                end
    ---[[Project Order]]---
                if reaper.ImGui_BeginMenu(ctx, 'Project Order') then
                    MenuItem(ctx, '$itemcount', tooltip.itemcount)
                    --MenuItem(ctx, '$itemindex', tooltip.itemindex)
                    reaper.ImGui_EndMenu(ctx) 
                end
    ---[[Media Item Information]]---
                if reaper.ImGui_BeginMenu(ctx, 'Media Item Information') then
                    MenuItem(ctx, '$item', tooltip.item)
                    MenuItem(ctx, '$itemnumber', tooltip.itemnumber)
                    MenuItem(ctx, '$itemnotes', tooltip.itemnotes)
                    --take marker
                    reaper.ImGui_EndMenu(ctx)
                end
    ---[[Date/Time]]---
                if reaper.ImGui_BeginMenu(ctx, 'Date/Time') then
                    MenuItem(ctx, '$date', tooltip.date)
                    MenuItem(ctx, '$time', tooltip.time)
                    MenuItem(ctx, '$year2', tooltip.year2)
                    MenuItem(ctx, '$year', tooltip.year)
                    MenuItem(ctx, '$monthname', tooltip.monthname)
                    MenuItem(ctx, '$month', tooltip.month)
                    MenuItem(ctx, '$dayname', tooltip.dayname)
                    MenuItem(ctx, '$day', tooltip.day)
                    MenuItem(ctx, '$hour12', tooltip.hour12)
                    MenuItem(ctx, '$hour', tooltip.hour)
                    MenuItem(ctx, '$ampm', tooltip.ampm)
                    MenuItem(ctx, '$minute', tooltip.minute)
                    MenuItem(ctx, '$second', tooltip.second)
                    reaper.ImGui_EndMenu(ctx)
                end
                if reaper.ImGui_BeginMenu(ctx, 'Metering') then
                    MenuItem(ctx, "$lufs", tooltip.lufs)
                    MenuItem(ctx, "$peak", tooltip.peak)
                    MenuItem(ctx, "$rms", tooltip.rms)
                    reaper.ImGui_EndMenu(ctx)
                end reaper.ImGui_EndMenu(ctx)
            end 
    --[[presets]]--
            if reaper.ImGui_BeginMenu(ctx, 'Save') then
                MenuItemSavePreset(ctx, input_string, '1')
                MenuItemSavePreset(ctx, input_string, '2')
                MenuItemSavePreset(ctx, input_string, '3')
                MenuItemSavePreset(ctx, input_string, '4')
                reaper.ImGui_EndMenu(ctx)
            end 
            if reaper.ImGui_BeginMenu(ctx, 'Load') then
                if MenuItemLoadPreset(ctx, '1') then
                    _, input_string = MenuItemLoadPreset(ctx, '1') end
                if MenuItemLoadPreset(ctx, '2') then
                    _, input_string = MenuItemLoadPreset(ctx, '2') end
                if MenuItemLoadPreset(ctx, '3') then
                    _, input_string = MenuItemLoadPreset(ctx, '3') end
                if MenuItemLoadPreset(ctx, '4') then
                    _, input_string = MenuItemLoadPreset(ctx, '4') end
                reaper.ImGui_EndMenu(ctx)
            end
            reaper.ImGui_EndMenuBar(ctx)
        end 

        reaper.ImGui_PushItemWidth(ctx, reaper.ImGui_GetWindowWidth(ctx) - 16)
        rv, input_string = reaper.ImGui_InputText( ctx, "", input_string )

        if reaper.ImGui_Button(ctx, "Apply") or reaper.ImGui_IsKeyPressed(ctx, 10) then
            reaper.PreventUIRefresh(1)
            reaper.Undo_BeginBlock()

            main()

            reaper.Undo_EndBlock("undo action", -1)
            reaper.UpdateArrange()
            reaper.PreventUIRefresh(-1)
        end
    end

    function loop()
        reaper.ImGui_PushFont(ctx, font)
        reaper.ImGui_SetNextWindowSize(ctx, 422, 102, reaper.ImGui_Cond_FirstUseEver())
        local visible, open = reaper.ImGui_Begin(ctx, 'Item Namer', true, window_flags)
        
        if visible then
            frame() ; reaper.ImGui_End(ctx) end

        reaper.ImGui_PopFont(ctx)
        
        if open then
            reaper.defer(loop)
        else
            reaper.ImGui_DestroyContext(ctx) end
    end

    reaper.defer(loop)
end

-- Whether to run GUI or access as a library
local is_gui
if reaper.HasExtState(section, "runitemnamergui") then
    is_gui = toboolean(reaper.GetExtState(section, "runitemnamergui"))
else
    is_gui = true end

if is_gui == true then
    GUI_MODE() end