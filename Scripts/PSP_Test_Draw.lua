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

local colors = {}
    colors.black = 0x000000C8
    colors.white = 0xFFFFFFC8

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
    if reaper.ImGui_Button(ctx, "Button") then
        todo() end

    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    local p = {reaper.ImGui_GetMousePos(ctx)}--reaper.ImGui_GetCursorScreenPos(ctx)}
    local sz = 36.0
    local x = p[1] + 4.0
    local y = p[2] + 4.0

    reaper.ImGui_Text(ctx, "x: " .. x .. " y: " .. y)
    reaper.ImGui_DrawList_AddCircle(draw_list, x, y, sz*0.5, colors.white, 0, 2 )
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
        reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)