--[[
 * ReaScript Name: PSP_Item Fader.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.32
 * Version: 1.4b
--]]

--[[
 * Changelog:
 * v1.4b (2021-07-16)
	+ Allows being called externally
 * v1.3 (2021-07-14)
    + Added font scaling
 * v1.2.1 (2021-07-08)
    + Better error message
 * v1.2 (2021-07-01)
    + Upgraded to ReaImGui v5
 * v1.1 (2021-06-21)
    + General Update
 * v0.2 (2021-06-04)
	+ Beta Release
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

section = "PSP_Scripts"
settings = {}
itemaliasext = {} -- define "class"

local window_flags = 
    reaper.ImGui_WindowFlags_MenuBar() |
    reaper.ImGui_WindowFlags_NoCollapse()

local slider_flags = 
    reaper.ImGui_SliderFlags_AlwaysClamp() |
    reaper.ImGui_SliderFlags_NoInput()

local proj = 0
local fade_in, fade_out = 0, 100
local fade_in_curve, fade_out_curve = -1, -1
local is_realtime = false
local is_snap_relative = false
local itemlist_fadein = "linear\31fast start\31fast end\31fast start (steep)\31fast end (steep)\31slow start/end\31bezier curve\31"
local itemlist_fadeout = "linear\31fast end\31fast start\31fast end (steep)\31fast start (steep)\31slow start/end\31bezier curve\31"

-----------------
--- FUNCTIONS ---
-----------------

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
end

local function LoadPreset(preset_letter)
    fade_in = reaper.GetExtState(section, "fade_in_" .. preset_letter) or 0
    fade_out = reaper.GetExtState(section, "fade_out_" .. preset_letter) or 100
    fade_in_curve = reaper.GetExtState(section, "fade_in_curve_" .. preset_letter) or 0
    fade_out_curve = reaper.GetExtState(section, "fade_out_curve_" .. preset_letter) or 0
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

--------------
--- PUBLIC ---
--------------

function itemaliasext.ItemFader(preset_letter)
    LoadPreset(preset_letter)
    SetItemFades(fade_in, fade_out, is_snap_relative)
    SetFadeCurveShape(fade_in_curve, true)
    SetFadeCurveShape(fade_out_curve, false)
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

    local ctx = reaper.ImGui_CreateContext('Item Fader', reaper.ImGui_ConfigFlags_DockingEnable())
    local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
    reaper.ImGui_AttachFont(ctx, font)

    function frame()
        local rv
        local screen_width = reaper.ImGui_GetWindowWidth(ctx)

-- [[settings]] --
        if reaper.ImGui_BeginMenuBar(ctx) then
            if reaper.ImGui_BeginMenu(ctx, 'Settings') then
                if reaper.ImGui_MenuItem(ctx, 'Real-time mode', nil, is_realtime) then 
                    is_realtime = not is_realtime end
                if reaper.ImGui_MenuItem(ctx, 'Relative to snap offset', nil, is_snap_relative) then 
                    is_snap_relative = not is_snap_relative end
                reaper.ImGui_EndMenu(ctx)
            end
-- [[presets]] --
            if reaper.ImGui_BeginMenu(ctx, 'Save') then
                MenuItemSavePreset(ctx, '1')
                MenuItemSavePreset(ctx, '2')
                MenuItemSavePreset(ctx, '3')
                MenuItemSavePreset(ctx, '4')
                reaper.ImGui_EndMenu(ctx)
            end 
            if reaper.ImGui_BeginMenu(ctx, 'Load') then
                MenuItemLoadPreset(ctx, '1')
                MenuItemLoadPreset(ctx, '2')
                MenuItemLoadPreset(ctx, '3')
                MenuItemLoadPreset(ctx, '4')
                reaper.ImGui_EndMenu(ctx)
            end
            reaper.ImGui_EndMenuBar(ctx)
        end

-- [[Drag Slider "Range"]] --
        if not is_snap_relative then
            reaper.ImGui_SetNextItemWidth( ctx, -1 )
            rv, fade_in, fade_out = reaper.ImGui_DragFloatRange2( 
                ctx, "", fade_in, fade_out, 0.25, 0.0, 100.0, 'Fade in: %.1f', 'Fade out: ' .. string.format('%.1f ', tostring(100-fade_out)), slider_flags)

            if is_realtime and reaper.ImGui_IsItemEdited(ctx) then
                SetItemFades(fade_in, fade_out, is_snap_relative)
            elseif reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                SetItemFades(fade_in, fade_out, is_snap_relative) end
-- [[Drag Slider "Double" x 2]] --
        else
            reaper.ImGui_PushItemWidth(ctx, screen_width / 2 - 10)
            reaper.ImGui_PushID(ctx, "fade_in")
            rv, fade_in = reaper.ImGui_DragDouble(ctx, "", fade_in, 0.25, 0.0, 100.0, 'Fade in: %.1f', slider_flags)    
            reaper.ImGui_PopID(ctx)

            if is_realtime and reaper.ImGui_IsItemEdited(ctx) then
                SetItemFades(fade_in, fade_out, is_snap_relative)
            elseif reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                SetItemFades(fade_in, fade_out, is_snap_relative) end

            reaper.ImGui_SameLine(ctx, 0, 4)
            reaper.ImGui_PushItemWidth(ctx, -1)
            reaper.ImGui_PushID(ctx, "fade_out")
            rv, fade_out = reaper.ImGui_DragDouble(ctx, "", fade_out, 0.25, 0.0, 100.0, 'Fade out: ' .. string.format('%.1f ', tostring(100-fade_out)), slider_flags)

            reaper.ImGui_PopID(ctx)

            if is_realtime and reaper.ImGui_IsItemEdited(ctx) then
                SetItemFades(fade_in, fade_out, is_snap_relative)
            elseif reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                SetItemFades(fade_in, fade_out, is_snap_relative) end
        end

-- [[Combo Boxes]] --
        reaper.ImGui_PushID(ctx, "fade_in_curve")
        reaper.ImGui_PushItemWidth(ctx, screen_width / 2 - 10)

        rv, fade_in_curve = reaper.ImGui_ListBox( ctx, "", fade_in_curve, itemlist_fadein)
        if rv then SetFadeCurveShape(fade_in_curve, true) end

        reaper.ImGui_PopID(ctx)
        reaper.ImGui_SameLine(ctx, 0, 4)
        reaper.ImGui_PushID(ctx, "fade_out_curve")
        reaper.ImGui_PushItemWidth(ctx, -1)

        rv, fade_out_curve = reaper.ImGui_ListBox( ctx, "", fade_out_curve, itemlist_fadeout)
        if rv then SetFadeCurveShape(fade_out_curve, false) end

        reaper.ImGui_PopID(ctx)
    end

    function loop()
      reaper.ImGui_PushFont(ctx, font)
      reaper.ImGui_SetNextWindowSize(ctx, 433, 188, reaper.ImGui_Cond_FirstUseEver())
      local visible, open = reaper.ImGui_Begin(ctx, 'Item Fader', true, window_flags)

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
if reaper.HasExtState(section, "runitemfadergui") then
    is_gui = toboolean(reaper.GetExtState(section, "runitemfadergui"))
else
    is_gui = true end

if is_gui == true then
    GUI_MODE() end