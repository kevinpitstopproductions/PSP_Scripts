--[[
 * ReaScript Name: PSP_Realtime Test.lua
 * @noindex
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-07-07)
 	+ Initial Release
--]]

--[[
 * About:
 * Real-time color change test using delta time
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

local window_flags =
    reaper.ImGui_WindowFlags_NoCollapse()

local color_scale = 1
local r, g, b = 0, 0, 0
local h, s, v = 0, 0, 0
local index = 0

-----------------
--- FUNCTIONS ---
-----------------

local function todo()
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    Msg("button pressed")

    reaper.Undo_EndBlock("undo action", -1)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end

------------
--- MAIN ---
------------

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions → Reapack → Browse Packages, and install ReaImGui first.", "Error", 0) return end
if (utils.GetUsingReaImGuiVersion() ~= utils.GetInstalledReaImGuiVersion()) then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version " .. utils.GetUsingReaImGuiVersion() .. " or later", "Error", 0) return end

settings.font_size = tonumber(reaper.GetExtState(section, "SD_font_size")) or 14

local ctx = reaper.ImGui_CreateContext('Template', reaper.ImGui_ConfigFlags_DockingEnable())
local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
    local rv

    index = index + reaper.ImGui_GetDeltaTime(ctx)
    if index > 1 then
        index = 0 end

    h = index --_, h = reaper.ImGui_DragDouble(ctx, "H", h, 0.01, 0, 1)
    _, s = reaper.ImGui_DragDouble(ctx, "S", s, 0.01, 0, 1)
    _, v = reaper.ImGui_DragDouble(ctx, "V", v, 0.01, 0, 1)
    _, a = reaper.ImGui_DragDouble(ctx, "A", a, 0.01, 0, 1)

    rv, r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v, a)

    r = math.ceil(math.map(r, 0, 1, 0, 255))
    g = math.ceil(math.map(g, 0, 1, 0, 255))
    b = math.ceil(math.map(b, 0, 1, 0, 255))

    local color =  reaper.ColorToNative( r, g, b )|0x1000000
    local items = "rv " .. tostring(rv) .. "\31" .. "r " .. tostring(r) .. "\31" .. "g " .. tostring(g) .. "\31" .. "b " .. tostring(b) .. "\31"
    local rv, current_item = reaper.ImGui_ListBox(ctx, "rgb", current_item, items)

    for i=0, reaper.CountMediaItems(0)-1 do
        local item = reaper.GetMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
    end
end

function loop()
    reaper.ImGui_PushFont(ctx, font)
    reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'My window', true, window_flags)
    
    if visible then
        frame() ; reaper.ImGui_End(ctx) end

    reaper.ImGui_PopFont(ctx)
    
    if open then
        reaper.defer(loop)
        reaper.UpdateArrange()
    else
        reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)