--[[
 * ReaScript Name: PSP_Item Spacer.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-18)
  + Beta Release
--]]

--- DEBUG ---

local console = true

local function Msg(text)
    if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end
end -- Msg

--- FUNCTIONS ---

--- MAIN ---

function main()

end

local ctx = reaper.ImGui_CreateContext('Item Spacer', 507, 59)

local item_table = {}
local max_space = 2;

function loop()
local rv
local item_count

if reaper.ImGui_IsCloseRequested(ctx) then
    reaper.ImGui_DestroyContext(ctx)
return
end

reaper.ImGui_SetNextWindowPos(ctx, 0, 0)
reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_GetDisplaySize(ctx))
reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

--- GUI START

rv, max_space = reaper.ImGui_InputText( ctx, "Max Offset in Seconds", max_space, reaper.ImGui_InputTextFlags_CharsDecimal())

rv, item_space = reaper.ImGui_SliderDouble(ctx, "Item Offset in Seconds", item_space, 0, max_space, '%.3f', reaper.ImGui_SliderFlags_Logarithmic())

if rv then
    item_count = reaper.CountSelectedMediaItems(0)

    if item_count > 0 then
        for i=0, item_count-1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            if i > 0 then
                local previous_item = reaper.GetSelectedMediaItem(0, i-1)
                local last_item_pos = reaper.GetMediaItemInfo_Value(previous_item, "D_POSITION")
                reaper.SetMediaItemInfo_Value(item, "D_POSITION", last_item_pos + item_space)
            end
        end
    end
end

--- GUI END

reaper.ImGui_End(ctx)
reaper.defer(loop)
end

loop()