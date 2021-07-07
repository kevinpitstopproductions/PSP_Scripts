--[[
 * ReaScript Name: PSP_Take Rate Adjuster.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-07-07)
	+ Initial Release
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text)) end end

--- VARIABLES ---

local is_finished = false
local rate_slider = 1.0

--- FUNCTIONS ---

local function ResetTable(item_table)
	if #item_table ~= nil then
		for k in pairs (item_table) do
    		item_table [k] = nil end end
end

local function SaveSelectedItems (item_table, rate_table)
	ResetTable(item_table)

	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		item = reaper.GetSelectedMediaItem(0, i)
		take = reaper.GetActiveTake(item)
		item_table[i+1] = item
		rate_table[i+1] = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
	end
end

local function SetTakeRate(x)
	for i, item in ipairs(init_sel_items) do
		take = reaper.GetActiveTake(item)
		reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", x * init_sel_take_rates[i] )
	end
end

local function DoTablesMatch(a, b)
	string_a = ""
	string_b = ""

	for i, item in ipairs(init_sel_items) do
		take = reaper.GetActiveTake(item)
		--output = ""
		_, str_out = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", 0)
		if str_out ~= nil then	
			string_a = string_a .. str_out
		end
	end

	for i, item in ipairs(b) do
		take = reaper.GetActiveTake(item)
		--output = ""
		_, str_out = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", 0)
		if str_out ~= nil then	
			string_b = string_b .. str_out end
	end

	return string_a == string_b
end

reaper.Undo_BeginBlock()

--- Main ---

if not reaper.APIExists('ImGui_GetVersion') then
	reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
	reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5-beta", "Error", 0) return end

local ctx = reaper.ImGui_CreateContext('PSP Take Rate Adjuster', reaper.ImGui_ConfigFlags_DockingEnable())
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

init_sel_items = {}
init_sel_take_rates = {}

temp_table = {}
temp_rate = {}

SaveSelectedItems(init_sel_items, init_sel_take_rates)

function frame()
  	local rv

  	SaveSelectedItems(temp_table, temp_rate)

	if (DoTablesMatch(init_sel_items, temp_table) == false) then
		SaveSelectedItems(init_sel_items, init_sel_take_rates)
		rate_slider = 1.0
	end

	rv, rate_slider = reaper.ImGui_DragDouble( ctx, 'rate slider', rate_slider, 0.01, 0, 10)

	SetTakeRate(rate_slider)
	reaper.UpdateArrange()

	if (reaper.ImGui_Button(ctx, 'Close')) or (reaper.ImGui_IsKeyPressed(ctx, 13)) or (reaper.ImGui_IsKeyPressed(ctx, 27)) then
		is_finished = true
	end

	if reaper.ImGui_IsKeyPressed(ctx, 32) then
		reaper.SetTakeRate_OnCommand(40044, 0)
	end
end

function loop()
	reaper.ImGui_PushFont(ctx, font)
  	reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
  	local visible, open = reaper.ImGui_Begin(ctx, 'PSP Config', true, window_flags)

  	if is_finished then
  		open = false
  	end
  	if visible then
    	frame()
    	reaper.ImGui_End(ctx)
  	end
  	reaper.ImGui_PopFont(ctx)
  
  	if open then
    	reaper.defer(loop)
  	else
    	reaper.ImGui_DestroyContext(ctx)
    	reaper.Undo_EndBlock("Adjust take rate", 0)
  	end
end

reaper.defer(loop)