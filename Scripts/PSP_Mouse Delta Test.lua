--[[
 * ReaScript Name: Template.lua
 * NoIndex: true
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.32
 * Version: 0.2
--]]

--[[
 * Changelog:
 * v0.2 (2021-07-20)
    + Updated and refactored
 * v0.1 (2021-07-07)
 	+ Initial Release
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

local last_val = 0
local scale = 5

-----------------
--- FUNCTIONS ---
-----------------

-- https://www.love2d.org/forums/viewtopic.php?p=198129#p198129
function lerp(from, to, t)
  return t < 0.5 and from + (to-from)*t or to + (from-to)*(1-t)
end

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
    if reaper.ImGui_Button(ctx, "Button") then
        todo() end

    local t = reaper.ImGui_GetDeltaTime(ctx)
    local track = reaper.GetSelectedTrack(0, 0)
    local x, y = 0, 0
    if reaper.ImGui_IsMouseDown(ctx, reaper.ImGui_MouseButton_Right()) then
        x, y = reaper.ImGui_GetMouseDelta(ctx) end
    local val = math.abs(x) + math.abs(y)
    val = math.map(val, 0, 255, 0, 1)
    val = lerp(last_val, val, t * scale)
    val = math.clamp(val, 0, 1)

    last_val = val

    _, scale = reaper.ImGui_DragDouble(ctx, "Scale", scale, 0.01, 0, 10)
    reaper.ImGui_Text(ctx, val)
    if track then
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", val) end
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
    else
        reaper.SetMediaTrackInfo_Value( reaper.GetSelectedTrack(0, 0), "D_VOL", 0 )
        reaper.ImGui_DestroyContext(ctx) 
    end
end

reaper.defer(loop)