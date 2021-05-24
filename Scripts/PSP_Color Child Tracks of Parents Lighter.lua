--[[
 * ReaScript Name: PSP_Color Child Tracks of Parents Lighter.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2021-05-24)
 	+ Initial Release
--]]

local function LightTrackColor(track)
  color = reaper.GetMediaTrackInfo_Value( track, "I_CUSTOMCOLOR" )
  r, g, b = reaper.ColorFromNative(color)
  r = r+20
  g = g+40
  b = b+20
  if r > 255 then r = 255 end
  if g > 255 then g = 255 end
  if b > 255 then b = 255 end
  color = reaper.ColorToNative(r, g, b)
  return color
end

local function SaveSelectedTracks (init_table, track_count)
  for i = 0, track_count-1 do
    local entry = {}

    entry.track = reaper.GetSelectedTrack(0, i)
    entry.color = LightTrackColor(entry.track)

    table.insert(init_table, entry)
  end -- item count
end --SaveSelectedItems

track_count = reaper.CountSelectedTracks(0)

local function ResetTrackSelection(init_table)
  for i=0, reaper.CountTracks(0)-1 do
    track = reaper.GetTrack(0, i)
    reaper.SetTrackSelected(track , 0)
  end

  for _, track in ipairs(init_table) do
    reaper.SetTrackSelected(track.track, 1)
  end
end

local function Main(init_table)
  for _, track in ipairs(init_table) do
    reaper.SetOnlyTrackSelected( track.track )

    reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_SWS_SELCHILDREN2"), 0, 0 )

    for i=1, reaper.CountSelectedTracks(0)-1 do
      inner_track = reaper.GetSelectedTrack(0, i)
      reaper.SetTrackColor(inner_track, track.color)
    end
  end -- end track loop 
end -- Main

track_count = reaper.CountSelectedTracks(0)

if track_count > 0 then

  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  reaper.ClearConsole()

  init_table = {}
  SaveSelectedTracks(init_table, track_count)

  Main(init_table)

  ResetTrackSelection(init_table)

  reaper.Undo_EndBlock("Undo", - 1)
  reaper.PreventUIRefresh(-1)
end
