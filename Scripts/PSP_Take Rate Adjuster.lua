--[[
 * ReaScript Name: PSP_Take Rate Adjuster.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 1.3
--]]

--[[
 * Changelog:
 * v1.3 (2021-07-14)
	+ Added font scaling
 * v1.2 (2021-07-08)
 	+ Optimised state detection (more efficient)
 * v1.1 (2021-07-08)
   + Better error message and bug fixes
 * v1.0 (2021-07-07)
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
local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text)) end end

-----------------
--- VARIABLES ---
-----------------

local section = "PSP_Scripts"
local settings = {}

local window_flags =
    reaper.ImGui_WindowFlags_NoCollapse()

local is_finished = false
local rate_slider = 1.0
local state_tracker = 0

-----------------
--- FUNCTIONS ---
-----------------

local function ResetTable(item_table)
	if #item_table ~= nil then
		for k in pairs (item_table) do
    		item_table [k] = nil end end
end

local function SaveSelectedItems (item_table, rate_table)
	ResetTable(item_table)

	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		local take = reaper.GetActiveTake(item)
		item_table[i+1] = item
		rate_table[i+1] = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
	end
end

local function SetTakeRate(x)
	for i, item in ipairs(init_sel_items) do
		reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PLAYRATE", x * init_sel_take_rates[i] ) end
end

local function DoTablesMatch(a, b)
	local string_a = ""
	local string_b = ""

	for i, item in ipairs(init_sel_items) do
		if tostring(item) ~= nil then	
			string_a = string_a .. tostring(item) end end

	for i, item in ipairs(b) do
		if tostring(item) ~= nil then	
			string_b = string_b .. tostring(item) end end

	return string_a == string_b
end

reaper.Undo_BeginBlock()

------------
--- MAIN ---
------------

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions → Reapack → Browse Packages, and install ReaImGui first.", "Error", 0) return end
if (utils.GetUsingReaImGuiVersion() ~= utils.GetInstalledReaImGuiVersion()) then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version " .. utils.GetUsingReaImGuiVersion() .. " or later", "Error", 0) return end

settings.font_size = tonumber(reaper.GetExtState(section, "SD_font_size")) or 14

local ctx = reaper.ImGui_CreateContext('PSP Take Rate Adjuster', reaper.ImGui_ConfigFlags_DockingEnable())
local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
reaper.ImGui_AttachFont(ctx, font)

init_sel_items = {}
init_sel_take_rates = {}

temp_table = {}
temp_rate = {}

SaveSelectedItems(init_sel_items, init_sel_take_rates)

function frame()
  	local rv

  	if reaper.CountSelectedMediaItems(0) > 0 then
  		if reaper.GetProjectStateChangeCount(0) ~= state_tracker then
	  		SaveSelectedItems(temp_table, temp_rate) ; state_tracker = reaper.GetProjectStateChangeCount(0) end

		if (DoTablesMatch(init_sel_items, temp_table) == false) then
			SaveSelectedItems(init_sel_items, init_sel_take_rates)
			rate_slider = 1.0
		end

		if (reaper.ImGui_Button(ctx, 'Close')) or (reaper.ImGui_IsKeyPressed(ctx, 13)) or (reaper.ImGui_IsKeyPressed(ctx, 27)) then
			is_finished = true end

		rv, rate_slider = reaper.ImGui_DragDouble( ctx, 'rate slider', rate_slider, 0.01, 0, 10)

		SetTakeRate(rate_slider)
		reaper.UpdateArrange()

		if reaper.ImGui_IsKeyPressed(ctx, 32) then -- If spacebar is pressed
			reaper.Main_OnCommand(40044, 0) end	-- Transport: Play/stop
	else
		reaper.ImGui_Text(ctx, "Please select an item") end
end

function loop()
	reaper.ImGui_PushFont(ctx, font)
  	reaper.ImGui_SetNextWindowSize(ctx, 375, 81, reaper.ImGui_Cond_FirstUseEver())
  	local visible, open = reaper.ImGui_Begin(ctx, 'PSP Take Rate Adjuster', true, window_flags)

  	if is_finished then
  		open = false
  	end

  	if visible then
    	frame() ; reaper.ImGui_End(ctx) end

  	reaper.ImGui_PopFont(ctx)
  
  	if open then
    	reaper.defer(loop)
  	else
    	reaper.ImGui_DestroyContext(ctx)
    	reaper.Undo_EndBlock("Adjust take rate", 0)
  	end
end

reaper.defer(loop)