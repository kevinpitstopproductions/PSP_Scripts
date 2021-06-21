--[[
 * ReaScript Name: PSP_Vegas Mode.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 0.1
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-21)
  + Beta Release
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES --- 

local counter = 0
local track_counter = 0
local is_increasing = true
local is_finished = false
local is_stored = false
local is_tracks_stored = false
local item_table = {}
local track_table = {}
local time_scale = 1
local time = 1

--- FUNCTIONS ---

function lerp(pos1, pos2, perc)
    return (1-perc)*pos1 + perc*pos2 -- Linear Interpolation
end

reaper.defer(function()
  ctx = reaper.ImGui_CreateContext('My script', 300, 60)
  viewport = reaper.ImGui_GetMainViewport(ctx)
  loop()
end)

local function SaveSelectedItems (init_table, item_count)
	for i = 0, item_count-1 do
		local entry = {}

		entry.item = reaper.GetMediaItem(0, i)
		entry.color = reaper.GetMediaItemInfo_Value(entry.item, "I_CUSTOMCOLOR")

		table.insert(init_table, entry)
	end -- loop through selected items
end -- SaveSelectedItems

local function SaveTrackInfo (init_table, track_count)
	for i = 0, track_count-1 do
		local entry = {}

		entry.track = reaper.GetTrack(0, i)
		entry.vol = reaper.GetMediaTrackInfo_Value(entry.track, "D_VOL")
		entry.mute = reaper.GetMediaTrackInfo_Value(entry.track, "B_MUTE")
		entry.solo = reaper.GetMediaTrackInfo_Value(entry.track, "I_SOLO")

		table.insert(init_table, entry)
	end -- loop through selected items
end -- SaveTrackInfo

--- MAIN ---

function loop()
	local rv

	if reaper.ImGui_IsCloseRequested(ctx) or is_finished then
		for i=0, #item_table-1 do
			reaper.SetMediaItemInfo_Value(item_table[i+1].item, "I_CUSTOMCOLOR", item_table[i+1].color)
		end
		for t=0, #track_table-1 do
			reaper.SetMediaTrackInfo_Value(track_table[t+1].track, "D_VOL", track_table[t+1].vol)
			reaper.SetMediaTrackInfo_Value(track_table[t+1].track, "B_MUTE", track_table[t+1].mute)
			reaper.SetMediaTrackInfo_Value(track_table[t+1].track, "I_SOLO", track_table[t+1].solo)
		end
		reaper.UpdateArrange()
		reaper.ImGui_DestroyContext(ctx)
		return
	end

	reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
	reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
	reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

	--- GUI START

	if reaper.ImGui_Button(ctx, "Cancel") then
		is_finished = true;
	end

	--- GUI END
	
	reaper.ImGui_End(ctx)

	if counter <= 0 then is_increasing = true end
	if counter >= 255 then is_increasing = false end

	if is_increasing then
		counter = counter + time_scale
		if counter >= 255 then
			counter = 255
		end
	else
		counter = counter - time_scale
		if counter <= 0 then
			counter = 0
		end
	end

	time = time + 0.05

	if time > 1 then to=0 end

	local item_count = reaper.CountMediaItems(0)
	if item_count > 0 then
		for i=0, item_count-1 do
			if not is_stored then
				SaveSelectedItems(item_table, item_count)
				is_stored = true
			end

			item = reaper.GetMediaItem(0, i)
			take = reaper.GetActiveTake(item)
			col = reaper.ColorToNative(counter, 0, 0)|0x1000000
			reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", col)
		end
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

			if counter % 15 == 0 then
				random_mute = math.random(2)-1
				reaper.SetMediaTrackInfo_Value(track, "B_MUTE", random_mute)
				random_solo = math.random(2)-1
				reaper.SetMediaTrackInfo_Value(track, "I_SOLO", random_solo)
			end
		end
	end

	reaper.UpdateArrange()
	reaper.defer(loop)
end