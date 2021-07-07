--[[
 * ReaScript Name: PSP_Vegas Mode.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 0.2
--]]

--[[
 * Changelog:
 * v0.1 (2021-06-21)
  + Beta Release
 * v0.2 (2021-07-07)
  + Ground-breaking improvements
--]]

--- DEBUG ---

local console = true

local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

--- VARIABLES --- 

local counter = 1
local is_finished = false
local is_stored = false
local is_tracks_stored = false
local item_table = {}
local track_table = {}
local time = 1
local color_counter = 0
local col = reaper.ColorToNative(0, 0, 0)|0x1000000

--- FUNCTIONS ---

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

--- MAIN ---

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions→Reapack→Browse Packages, and install ReaImGui first.", "Error", 0) return end

local imgui_version, reaimgui_version = reaper.ImGui_GetVersion()

if reaimgui_version:sub(0, 3) ~= "0.5" then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version 0.5-beta", "Error", 0) return end

local ctx = reaper.ImGui_CreateContext('My script', 0)
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = reaper.ImGui_CreateFont('sans-serif', size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
  local rv

	if reaper.ImGui_Button(ctx, "Close & Restore") then
		is_finished = true end

	time = time + 0.04

	counter = counter + 1

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

			reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", reaper.ImGui_ColorConvertHSVtoRGB( time, 1, 0.6, 1.0 ))

			if counter % 20 == 0 then
				rand = math.random(2)-1
				reaper.SetMediaItemInfo_Value(item, "B_MUTE", rand)
			end
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
		end
	end

	reaper.UpdateArrange()
end

function loop()
  reaper.ImGui_PushFont(ctx, font)
  reaper.ImGui_SetNextWindowSize(ctx, 300, 60, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'PSP Config', true)

  if visible then
    frame()
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  
  if is_finished then
  	open = false end

  if open then
    reaper.defer(loop)
  else
	for i=0, #item_table-1 do
		reaper.SetMediaItemInfo_Value(item_table[i+1].item, "I_CUSTOMCOLOR", item_table[i+1].color)
		reaper.SetMediaItemInfo_Value(item_table[i+1].item, "B_MUTE", item_table[i+1].mute)
	end
	for t=0, #track_table-1 do
		reaper.SetMediaTrackInfo_Value(track_table[t+1].track, "D_VOL", track_table[t+1].vol)
		reaper.SetMediaTrackInfo_Value(track_table[t+1].track, "B_MUTE", track_table[t+1].mute)
		reaper.SetMediaTrackInfo_Value(track_table[t+1].track, "I_SOLO", track_table[t+1].solo)
	end
	reaper.UpdateArrange()
    reaper.ImGui_DestroyContext(ctx)
  end
end
reaper.defer(loop)