--[[
 * ReaScript Name: GU-on_[GE]_Item Fader
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-04)
  + Beta Release
--]]

--- DEBUG ---

local console = true

local function Msg(text)
    if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end
end -- Msg

--- VARIABLES ---

section = "PSP_Scripts"
settings = {}

local window_flags =
    reaper.ImGui_WindowFlags_NoTitleBar() | 
    reaper.ImGui_WindowFlags_MenuBar() | 
    reaper.ImGui_WindowFlags_NoResize()

local proj = 0
local fade_in, fade_out = 0, 100
local fade_in_curve, fade_out_curve = -1, -1
local is_realtime = false
local is_snap_relative = false

--- FUNCTIONS ---

local function SetItemFades(fade_in, fade_out, is_snap_relative)
    item_count = reaper.CountSelectedMediaItems(proj)

    if item_count > 0 then
        for i=0, item_count-1 do
            local item = reaper.GetSelectedMediaItem(proj, i)
            local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

            if not is_snap_relative then
                reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", item_length * (fade_in/100))
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", item_length * (100-fade_out)/100)
            else
                local item_snap_offset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
                reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", item_snap_offset * (fade_in/100))
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", item_length * (100-fade_out)/100 - item_snap_offset)
            end
        end -- iterate through items
    end -- check if any are items selected
    reaper.UpdateArrange()
end -- SetItemFades

local function SetFadeCurveShape(curve_shape, is_fade_in)
    item_count = reaper.CountSelectedMediaItems(proj)

    if item_count > 0 then
        for i=0, item_count-1 do
            local item = reaper.GetSelectedMediaItem(proj, i)

            if is_fade_in then
                reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", curve_shape)
            else
                reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", curve_shape)
            end
        end -- iterate through items
    end -- check if any items selected
    reaper.UpdateArrange()
end -- SetFadeCurveShape

local function SavePreset(fade_in, fade_out, fade_in_curve, fade_out_curve, preset_letter)
    reaper.SetExtState(section, "fade_in_" .. preset_letter, fade_in, 1)
    reaper.SetExtState(section, "fade_out_" .. preset_letter, fade_out, 1)
    reaper.SetExtState(section, "fade_in_curve_" .. preset_letter, fade_in_curve  , 1)
    reaper.SetExtState(section, "fade_out_curve_" .. preset_letter, fade_out_curve, 1)
end -- SavePreset

local function LoadPreset(preset_letter)
    if reaper.HasExtState(section, "fade_in_" .. preset_letter) then
        fade_in = reaper.GetExtState(section, "fade_in_" .. preset_letter) else
        fade_in = 0 end
    if reaper.HasExtState(section, "fade_out_" .. preset_letter) then
        fade_out = reaper.GetExtState(section, "fade_out_" .. preset_letter) else
        fade_out = 100 end
    if reaper.HasExtState(section, "fade_in_curve_" .. preset_letter) then
        fade_in_curve = reaper.GetExtState(section, "fade_in_curve_" .. preset_letter) else
        fade_in_curve = 0 end
    if reaper.HasExtState(section, "fade_out_curve_" .. preset_letter) then
        fade_out_curve = reaper.GetExtState(section, "fade_out_curve_" .. preset_letter) else
        fade_out_curve = 0 end

    return fade_in, fade_out, fade_in_curve, fade_out_curve
end -- LoadPreset

--- MAIN ---

reaper.defer(function()
    reaper.Undo_BeginBlock()
    ctx = reaper.ImGui_CreateContext('Item Fader', 433, 188)
    viewport = reaper.ImGui_GetMainViewport(ctx)
    draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    loop()
end)

function loop()
    local rv

    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock("Item Fader", -1)
        return
    end

    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
    rv, open = reaper.ImGui_Begin(ctx, 'Item Fader', open, window_flags) 

    --- GUI START

    local screen_width =  reaper.ImGui_GetWindowWidth(ctx)

    -- [[menu]]
    if reaper.ImGui_BeginMenuBar(ctx) then
        if reaper.ImGui_BeginMenu(ctx, 'Settings') then
            if reaper.ImGui_MenuItem(ctx, 'Real-time mode', nil, is_realtime) then 
                is_realtime = not is_realtime end
            if reaper.ImGui_MenuItem(ctx, 'Relative to snap offset', nil, is_snap_relative) then 
                is_snap_relative = not is_snap_relative end
            reaper.ImGui_EndMenu(ctx)
        end
        -- [[presets]]
        if reaper.ImGui_BeginMenu(ctx, 'Save') then
            if reaper.ImGui_MenuItem(ctx, 'Preset A', nil, false) then 
                SavePreset(fade_in, fade_out, fade_in_curve, fade_out_curve, "A") end           
            if reaper.ImGui_MenuItem(ctx, 'Preset B', nil, false) then 
                SavePreset(fade_in, fade_out, fade_in_curve, fade_out_curve, "B") end
            if reaper.ImGui_MenuItem(ctx, 'Preset C', nil, false) then 
                SavePreset(fade_in, fade_out, fade_in_curve, fade_out_curve, "C") end
            if reaper.ImGui_MenuItem(ctx, 'Preset D', nil, false) then 
                SavePreset(fade_in, fade_out, fade_in_curve, fade_out_curve, "D") end
            reaper.ImGui_EndMenu(ctx)
        end 
        if reaper.ImGui_BeginMenu(ctx, 'Load') then
            if reaper.ImGui_MenuItem(ctx, 'Preset A', nil, false) then 
                fade_in, fade_out, fade_in_curve, fade_out_curve = LoadPreset("A") 
                SetItemFades(fade_in, fade_out, is_snap_relative)
                SetFadeCurveShape(fade_in_curve, true)
                SetFadeCurveShape(fade_out_curve, false)
            end
            if reaper.ImGui_MenuItem(ctx, 'Preset B', nil, false) then 
                fade_in, fade_out, fade_in_curve, fade_out_curve = LoadPreset("B")
                SetItemFades(fade_in, fade_out, is_snap_relative)
                SetFadeCurveShape(fade_in_curve, true)
                SetFadeCurveShape(fade_out_curve, false)
            end
            if reaper.ImGui_MenuItem(ctx, 'Preset C', nil, false) then
                fade_in, fade_out, fade_in_curve, fade_out_curve = LoadPreset("C")
                SetItemFades(fade_in, fade_out, is_snap_relative)
                SetFadeCurveShape(fade_in_curve, true)
                SetFadeCurveShape(fade_out_curve, false)
            end
            if reaper.ImGui_MenuItem(ctx, 'Preset D', nil, false) then 
                fade_in, fade_out, fade_in_curve, fade_out_curve = LoadPreset("D")
                SetItemFades(fade_in, fade_out, is_snap_relative)
                SetFadeCurveShape(fade_in_curve, true)
                SetFadeCurveShape(fade_out_curve, false)
            end
            reaper.ImGui_EndMenu(ctx)
        end
        reaper.ImGui_EndMenuBar(ctx)
    end

    -- [[Drag Slider A]]
    if not is_snap_relative then
        reaper.ImGui_SetNextItemWidth( ctx, -1 )
        rv, fade_in, fade_out = reaper.ImGui_DragFloatRange2( 
            ctx, "", fade_in, fade_out, 0.25, 0.0, 100.0, 'Fade in: %.1f', 'Fade out: ' .. string.format('%.1f ', tostring(100-fade_out)), reaper.ImGui_SliderFlags_AlwaysClamp())

        if is_realtime and reaper.ImGui_IsItemEdited(ctx) then
            SetItemFades(fade_in, fade_out, is_snap_relative)
        elseif reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
            SetItemFades(fade_in, fade_out, is_snap_relative)
        end
    -- [[Drag Slider B]]
    else
        reaper.ImGui_PushItemWidth(ctx, screen_width / 2 - 10)
        reaper.ImGui_PushID(ctx, "fade_in")
        rv, fade_in = reaper.ImGui_DragDouble(ctx, "", fade_in, 0.25, 0.0, 100.0, 'Fade in: %.1f')    
        reaper.ImGui_PopID(ctx)

        if is_realtime and reaper.ImGui_IsItemEdited(ctx) then
            SetItemFades(fade_in, fade_out, is_snap_relative)
        elseif reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
            SetItemFades(fade_in, fade_out, is_snap_relative)
        end

        reaper.ImGui_SameLine(ctx, 0, 4)
        reaper.ImGui_PushItemWidth(ctx, -1)
        reaper.ImGui_PushID(ctx, "fade_out")
        rv, fade_out = reaper.ImGui_DragDouble(ctx, "", fade_out, 0.25, 0.0, 100.0, 'Fade out: ' .. string.format('%.1f ', tostring(100-fade_out)))    
        reaper.ImGui_PopID(ctx)

        if is_realtime and reaper.ImGui_IsItemEdited(ctx) then
            SetItemFades(fade_in, fade_out, is_snap_relative)
        elseif reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
            SetItemFades(fade_in, fade_out, is_snap_relative)
        end
    end

    -- [[Combo Boxes]] 
    reaper.ImGui_PushID(ctx, "fade_in_curve")
    reaper.ImGui_PushItemWidth(ctx, screen_width / 2 - 10)

    --rv, fade_in_curve = reaper.ImGui_Combo( ctx, "", fade_in_curve, "linear\31exponential\31")
    items = "linear\31fast start\31fast end\31fast start (steep)\31fast end (steep)\31slow start/end\31bezier curve\31"
    rv, fade_in_curve = reaper.ImGui_ListBox( ctx, "", fade_in_curve, items)
    if rv then
        SetFadeCurveShape(fade_in_curve, true)
    end
    reaper.ImGui_PopID(ctx)

    reaper.ImGui_SameLine(ctx, 0, 4)
    reaper.ImGui_PushID(ctx, "fade_out_curve")
    reaper.ImGui_PushItemWidth(ctx, -1)
    --rv, fade_out_curve = reaper.ImGui_Combo( ctx, "", fade_out_curve, "linear\31exponential\31")
    items = "linear\31fast end\31fast start\31fast end (steep)\31fast start (steep)\31slow start/end\31bezier curve\31"
    rv, fade_out_curve = reaper.ImGui_ListBox( ctx, "", fade_out_curve, items)

    if rv then
        SetFadeCurveShape(fade_out_curve, false)
    end
    reaper.ImGui_PopID(ctx)

    --- GUI END

    reaper.ImGui_End(ctx)
    reaper.defer(loop)
end