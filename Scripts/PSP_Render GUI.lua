--[[
 * ReaScript Name: PSP_Render GUI.lua
 * @noindex
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.32
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-07-07)
	+ Initial Release
--]]

-- reaper.ImGui_TableSetBgColor( ctx, target, color_rgba, column_nIn )

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

local item_table = {}
local colors = {}
	colors.black = 0x000000C8
	colors.white = 0xFFFFFFC8

local has_changed = 0

-----------------
--- FUNCTIONS ---
-----------------

function rgbToHex(rgb)
	local hexadecimal = '0X'
	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'
		elseif(string.len(hex) == 1)then
			hex = '0' .. hex 
		end

		hexadecimal = hexadecimal .. hex
	end

	return hexadecimal
end

local function SaveParentItemsToTable(item_table)
	for t=0, reaper.CountTracks(0)-1 do
		if reaper.GetTrackDepth(reaper.GetTrack(0, t)) == 0 then
			local track = reaper.GetTrack(0, t)
			for i=0, reaper.CountTrackMediaItems(track)-1 do
				local entry = {}

				entry.id = reaper.GetTrackMediaItem(track, i)
				entry.name = reaper.GetTakeName(reaper.GetActiveTake(entry.id))
				entry.track = reaper.GetMediaItem_Track(entry.id)
				_, entry.track_name = reaper.GetTrackName(track)
				entry.sel = reaper.GetMediaItemInfo_Value(entry.id, "B_UISEL")
				entry.start = reaper.GetMediaItemInfo_Value(entry.id, "D_POSITION")

				local temp_color = reaper.ImGui_ColorConvertNative(reaper.GetDisplayedMediaItemColor(entry.id))
				local r, g, b = reaper.ColorFromNative(temp_color)
				local temp_table = {b, g, r, 255}

				local temp_hex = rgbToHex(temp_table)

				entry.color = temp_hex
				entry.color_brightness = (r+g+b)/3

				table.insert(item_table, entry)
			end
		end
	end
end

local function todo()
	reaper.PreventUIRefresh(1)
	reaper.Undo_BeginBlock()

	local path = reaper.GetProjectPath("")
	for i=0, reaper.CountSelectedMediaItems(0)-1 do
    	local item = reaper.GetSelectedMediaItem(0, i)
    	local _, item_name = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
    	local file_address = path .. "\\" .. item_name .. ".wav"
    	file_address = string.gsub(file_address, "\\", "\\\\") -- correct formatting issues
    	os.remove(file_address)
	end

	reaper.Main_OnCommand(42230, 0)

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

local ctx = reaper.ImGui_CreateContext('PSP Item Navigator', reaper.ImGui_ConfigFlags_DockingEnable())
local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
	local rv

	if reaper.GetProjectStateChangeCount(0) ~= has_changed then
		has_changed = reaper.GetProjectStateChangeCount(0)
		table.clear(item_table)
		SaveParentItemsToTable(item_table)
	end

	if reaper.ImGui_Button(ctx, "Quick Render") then
		todo() end

	if reaper.ImGui_BeginTable(ctx, "Items", 3, reaper.ImGui_TableFlags_Resizable() | reaper.ImGui_TableFlags_NoSavedSettings() | reaper.ImGui_TableFlags_SizingFixedFit()) then
		reaper.ImGui_TableNextRow(ctx)
		reaper.ImGui_TableNextColumn(ctx)
		reaper.ImGui_Text(ctx, "IDX")
		reaper.ImGui_TableNextColumn(ctx)
		reaper.ImGui_Text(ctx, "TRACK")
		reaper.ImGui_TableNextColumn(ctx)
		reaper.ImGui_Text(ctx, "ITEM NAME")
		reaper.ImGui_TableNextRow(ctx)

		for i, item in ipairs(item_table) do
			reaper.ImGui_TableNextRow(ctx)
			reaper.ImGui_TableNextColumn(ctx)
			reaper.ImGui_Text(ctx, i)
			reaper.ImGui_TableNextColumn(ctx)
			reaper.ImGui_TableSetBgColor( ctx,  reaper.ImGui_TableBgTarget_CellBg(), item.color)

			-- change text color based on bg brightness
			local temp_col = colors.black
			if item.color_brightness < 127 then
				temp_col = colors.white end
			reaper.ImGui_TextColored(ctx, temp_col, item.track_name)
			reaper.ImGui_TableNextColumn(ctx)
			rv, item_table[i].sel = reaper.ImGui_Selectable(ctx, item.name, item.sel, reaper.ImGui_SelectableFlags_SpanAllColumns())

			-- if selection changes, update reaper selection
			if rv then 
				reaper.SetMediaItemInfo_Value(item.id, "B_UISEL", booltonum(item.sel))
				has_changed = reaper.GetProjectStateChangeCount(0)
				reaper.UpdateArrange()
			end

			-- right click navigate
			if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) then
				reaper.SetEditCurPos( item.start, true, false )
			end
		end
		reaper.ImGui_EndTable(ctx)
	end
end

function loop()
	reaper.ImGui_PushFont(ctx, font)
	reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
	reaper.ImGui_SetNextWindowDockID(ctx, -1, reaper.ImGui_Cond_Once())

	local visible, open = reaper.ImGui_Begin(ctx, 'PSP Item Navigator', true, window_flags)
	
	if visible then
		frame() ; reaper.ImGui_End(ctx) end

	reaper.ImGui_PopFont(ctx)
	
	if open then
		reaper.defer(loop)
	else
		reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)