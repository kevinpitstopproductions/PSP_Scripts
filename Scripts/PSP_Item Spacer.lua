--[[
 * ReaScript Name: PSP_Item Spacer.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.2
--]]

--[[
 * Changelog:
 * v0.3 (2021-06-18)
	+ Beta Release
 * v1.1 (2021-06-21)
	+ General Update
 * v1.2 (2021-07-01)
    + Upgraded to ReaImGui v5
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

local window_flags = 
    reaper.ImGui_WindowFlags_NoCollapse()

local item_table = {}
local max_space = 2

--- FUNCTIONS ---

--- MAIN ---

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5-beta", "Error", 0) return end

local ctx = reaper.ImGui_CreateContext('Item Spacer', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
local rv

_, max_space = reaper.ImGui_InputText( ctx, "Max Offset in Seconds", max_space, reaper.ImGui_InputTextFlags_CharsDecimal())

if max_space == nil or max_space == "" then
    max_space = 0 end

rv, item_space = reaper.ImGui_SliderDouble(ctx, "Item Offset in Seconds", item_space, 0, max_space, '%.3f', reaper.ImGui_SliderFlags_Logarithmic())

if rv then
    if reaper.CountSelectedMediaItems(0) > 0 then
        for i=0, reaper.CountSelectedMediaItems(0)-1 do
            if i > 0 then
                local item = reaper.GetSelectedMediaItem(0, i)
                local previous_item = reaper.GetSelectedMediaItem(0, i-1)
                local last_item_pos = reaper.GetMediaItemInfo_Value(previous_item, "D_POSITION")
                reaper.SetMediaItemInfo_Value(item, "D_POSITION", last_item_pos + item_space)
            end end end end

if reaper.ImGui_IsKeyPressed( ctx, 32 ) then -- space-bar plays
    reaper.Main_OnCommand(40044, 0) end
end

function loop()
    reaper.ImGui_PushFont(ctx, font)
    reaper.ImGui_SetNextWindowSize(ctx, 400, 80, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'PSP_Item Spacer', true, window_flags)

    if visible then
        frame()
        reaper.ImGui_End(ctx)
    end
    reaper.ImGui_PopFont(ctx)
  
    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)