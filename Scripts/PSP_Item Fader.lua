--[[
 * ReaScript Name: PSP_Item Fader.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.2.1
--]]

--[[
 * Changelog:
 * v0.2 (2021-06-04)
	+ Beta Release
 * v1.1 (2021-06-21)
	+ General Update
 * v1.2 (2021-07-01)
    + Upgraded to ReaImGui v5
 * v1.2.1 (2021-07-08)
    + Better error message
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

section = "PSP_Scripts"
settings = {}

local window_flags = 
    reaper.ImGui_WindowFlags_MenuBar() |
    reaper.ImGui_WindowFlags_NoCollapse()

local proj = 0
local fade_in, fade_out = 0, 100
local fade_in_curve, fade_out_curve = -1, -1
local is_realtime = false
local is_snap_relative = false

--- FUNCTIONS ---

local function SetItemFades(fade_in, fade_out, is_snap_relative)
    local item_count = reaper.CountSelectedMediaItems(proj)

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
        end
    end reaper.UpdateArrange()
end

local function SetFadeCurveShape(curve_shape, is_fade_in)
    local item_count = reaper.CountSelectedMediaItems(proj)

    if item_count > 0 then
        for i=0, item_count-1 do
            local item = reaper.GetSelectedMediaItem(proj, i)

            if is_fade_in then
                reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", curve_shape)
            else
                reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", curve_shape) end
        end
    end reaper.UpdateArrange()
end 

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
end

local function MenuItemSavePreset(ctx, letter)
    if reaper.ImGui_MenuItem(ctx, 'Preset ' .. letter, nil, false) then 
        SavePreset(fade_in, fade_out, fade_in_curve, fade_out_curve, letter) end  
end

local function MenuItemLoadPreset(ctx, letter)
    if reaper.ImGui_MenuItem(ctx, 'Preset ' .. letter, nil, false) then
        fade_in, fade_out, fade_in_curve, fade_out_curve = LoadPreset(letter) 
        SetItemFades(fade_in, fade_out, is_snap_relative)
        SetFadeCurveShape(fade_in_curve, true)
        SetFadeCurveShape(fade_out_curve, false)
    end
end

--- MAIN ---

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5 or later", "Error", 0) return end

local ctx = reaper.ImGui_CreateContext('Item Fader', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
    local rv

    local screen_width = reaper.ImGui_GetWindowWidth(ctx)
    local items

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
            MenuItemSavePreset(ctx, 'A')
            MenuItemSavePreset(ctx, 'B')
            MenuItemSavePreset(ctx, 'C')
            MenuItemSavePreset(ctx, 'D')
            reaper.ImGui_EndMenu(ctx)
        end 
        if reaper.ImGui_BeginMenu(ctx, 'Load') then
            MenuItemLoadPreset(ctx, 'A')
            MenuItemLoadPreset(ctx, 'B')
            MenuItemLoadPreset(ctx, 'C')
            MenuItemLoadPreset(ctx, 'D')
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
            SetItemFades(fade_in, fade_out, is_snap_relative) end
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

    items = "linear\31fast start\31fast end\31fast start (steep)\31fast end (steep)\31slow start/end\31bezier curve\31"
    rv, fade_in_curve = reaper.ImGui_ListBox( ctx, "", fade_in_curve, items)
    if rv then
        SetFadeCurveShape(fade_in_curve, true) end

    reaper.ImGui_PopID(ctx)
    reaper.ImGui_SameLine(ctx, 0, 4)
    reaper.ImGui_PushID(ctx, "fade_out_curve")
    reaper.ImGui_PushItemWidth(ctx, -1)

    items = "linear\31fast end\31fast start\31fast end (steep)\31fast start (steep)\31slow start/end\31bezier curve\31"
    rv, fade_out_curve = reaper.ImGui_ListBox( ctx, "", fade_out_curve, items)

    if rv then
        SetFadeCurveShape(fade_out_curve, false) end

    reaper.ImGui_PopID(ctx)
end

function loop()
  reaper.ImGui_PushFont(ctx, font)
  reaper.ImGui_SetNextWindowSize(ctx, 433, 188, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Item Fader', true, window_flags)

  if visible then
    frame()
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  
  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)