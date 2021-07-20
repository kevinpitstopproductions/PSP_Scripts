--[[
 * ReaScript Name: PSP_Vegas Mode.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.32
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-07-20)
 	+ Full release, fully working, includes control sliders
 * v0.2.2 (2021-07-14)
 	+ Added font scaling
 * v0.2.1 (2021-07-08)
    + Better error message
 * v0.2 (2021-07-07)
  + Ground-breaking improvements
 * v0.1 (2021-06-21)
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

local section = "PSP_Scripts"
local settings = {}

local window_flags =
    reaper.ImGui_WindowFlags_NoCollapse()

local is_finished = false
local is_stored = false
local is_tracks_stored = false
local item_table = {}
local track_table = {}
local time = 0
local speed = 1
local do_item_changes = false

local r, g, b = 1, 1, 1
local h, s, v, a = 1, 1, 1, 1

-----------------
--- FUNCTIONS ---
-----------------

local function SaveSelectedItems (init_table, item_count)
	for i = 0, item_count-1 do
		local entry = {}

		entry.item = reaper.GetMediaItem(0, i)
		entry.color = reaper.GetMediaItemInfo_Value(entry.item, "I_CUSTOMCOLOR")
		entry.mute = reaper.GetMediaItemInfo_Value(entry.item, "B_MUTE")

		table.insert(init_table, entry)
	end
end

local function SaveTrackInfo (init_table, track_count)
	for i = 0, track_count-1 do
		local entry = {}

		entry.track = reaper.GetTrack(0, i)
		entry.vol = reaper.GetMediaTrackInfo_Value(entry.track, "D_VOL")
		entry.mute = reaper.GetMediaTrackInfo_Value(entry.track, "B_MUTE")
		entry.solo = reaper.GetMediaTrackInfo_Value(entry.track, "I_SOLO")

		table.insert(init_table, entry)
	end
end



------------
--- MAIN ---
------------

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions → Reapack → Browse Packages, and install ReaImGui first.", "Error", 0) return end
if (utils.GetUsingReaImGuiVersion() ~= utils.GetInstalledReaImGuiVersion()) then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version " .. utils.GetUsingReaImGuiVersion() .. " or later", "Error", 0) return end

settings.font_size = tonumber(reaper.GetExtState(section, "SD_font_size")) or 14

reaper.Undo_BeginBlock()

local ctx = reaper.ImGui_CreateContext('My script', 0)
local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
  	local rv

	if reaper.ImGui_Button(ctx, "Close & Restore") then
		is_finished = true end

	time = time + reaper.ImGui_GetDeltaTime(ctx) * speed

    if time > 1 then
    	time = 0
    	do_item_changes = true
    end

    h = time --_, h = reaper.ImGui_DragDouble(ctx, "H", h, 0.01, 0, 1)

    _, s = reaper.ImGui_DragDouble(ctx, "Saturation", s, 0.01, 0, 1)
    _, v = reaper.ImGui_DragDouble(ctx, "Value", v, 0.01, 0, 1)
    _, a = reaper.ImGui_DragDouble(ctx, "Alpha", a, 0.01, 0, 1)
    _, speed = reaper.ImGui_DragDouble(ctx, "Speed", speed, 0.01, 0, 10)

    reaper.ImGui_Text(ctx, "Use at your own risk. Do use Reaper while this script is active.")

    rv, r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v, a)

    r = math.ceil(math.map(r, 0, 1, 0, 255))
    g = math.ceil(math.map(g, 0, 1, 0, 255))
    b = math.ceil(math.map(b, 0, 1, 0, 255))

    local color = reaper.ColorToNative( r, g, b )|0x1000000

	local item_count = reaper.CountMediaItems(0)
	if item_count > 0 then
		for i=0, item_count-1 do
			if not is_stored then
				SaveSelectedItems(item_table, item_count)
				is_stored = true
			end

			local item = reaper.GetMediaItem(0, i)
			local take = reaper.GetActiveTake(item)

			reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)

			if do_item_changes then
				rand = math.random(2)-1
				reaper.SetMediaItemInfo_Value(item, "B_MUTE", rand)
			end
		end
		do_item_changes = false
	end

	local track_count = reaper.CountTracks(0)
	if track_count > 0 then
		for t=0, track_count-1 do
			if not is_tracks_stored then
				SaveTrackInfo(track_table, track_count)
				is_tracks_stored = true
			end
			local track = reaper.GetTrack(0, t)

			local out = math.sin(2*math.pi * time + (2*math.pi / track_count) * t)
			
			reaper.SetMediaTrackInfo_Value(track, "D_VOL", math.exp(out) - 0.33)
		end
	end

	reaper.UpdateArrange()
end

function loop()
  	reaper.ImGui_PushFont(ctx, font)
  	reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
  	local visible, open = reaper.ImGui_Begin(ctx, 'Vegas Mode!🥰', true, window_flags)

  	if visible then
    	frame() ; reaper.ImGui_End(ctx) end
  	reaper.ImGui_PopFont(ctx)
  
  	if is_finished then
  		open = false end

 	if open then
    	reaper.defer(loop)
  	else -- reset items to original state
  		reaper.Undo_EndBlock("vegas mode chaos", 0)
		for i=1, #item_table do
			reaper.SetMediaItemInfo_Value(item_table[i].item, "I_CUSTOMCOLOR", item_table[i].color)
			reaper.SetMediaItemInfo_Value(item_table[i].item, "B_MUTE", item_table[i].mute)
		end
		for t=1, #track_table do
			reaper.SetMediaTrackInfo_Value(track_table[t].track, "D_VOL", track_table[t].vol)
		end
		reaper.UpdateArrange()
    	reaper.ImGui_DestroyContext(ctx)
  	end
end

reaper.defer(loop)