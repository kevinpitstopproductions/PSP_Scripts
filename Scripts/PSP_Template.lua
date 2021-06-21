--[[
 * ReaScript Name: Template.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-21)
 	+ Initial Release
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES ---

--- FUNCTIONS ---

local function todo()
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    SaveSelectedItems(item_table)

    CreateRegionsFromItemTable(item_table)

    reaper.Undo_EndBlock("undo action", -1)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end

--- MAIN ---

if not reaper.APIExists('ImGui_Begin') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0)
    return
end

local ctx = reaper.ImGui_CreateContext('My script')

function loop()
    local visible, open = reaper.ImGui_Begin(ctx, 'My window', true)
    
    todo()
    
    if visible then
        reaper.ImGui_Text(ctx, 'Hello World!')
        reaper.ImGui_End(ctx)
    end
    
    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

reaper.defer(loop)