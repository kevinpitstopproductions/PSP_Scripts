--[[
 * ReaScript Name: PSP_Create Parent Item Aliases from Selected Items.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.29
 * Version: 1.4.1
--]]

--[[
 * Changelog:
 * v1.4.1 (2021-07-16)
 	+ Bug Fix + Added preset support
 * v1.4 (2021-06-21)
	+ General Update
 * v1.3 (2021-06-07)
	+ Prevent running on items at depth 0
 * v1.1 (2021-05-28)
    + Bug Fix
 * v1.0 (2021-05-28)
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

console = true
local function Msg(value) if console then reaper.ShowConsoleMsg(tostring(value) .. "\n") end end

-----------------
--- VARIABLES ---
-----------------

section = "PSP_Scripts"
settings = {}

-----------------
--- FUNCTIONS ---
-----------------

function table.contains(table, element)
  	for _, value in pairs(table) do
    	if value == element then return true end end
  	return false
end

function GetOutermostParentTrack(track) -- Gets the most parent track
	local current_track = track
	while reaper.GetParentTrack(current_track) do
		current_track = reaper.GetParentTrack(current_track) end
	return current_track
end

local function SaveSelectedItems (init_table, item_count)
	for i = 0, item_count-1 do
		local entry = {}

		entry.item = reaper.GetSelectedMediaItem(0, i)
		entry.pos_start = reaper.GetMediaItemInfo_Value(entry.item, "D_POSITION")
    	entry.pos_end = entry.pos_start + reaper.GetMediaItemInfo_Value(entry.item, "D_LENGTH")

		table.insert(init_table, entry)
	end
end

local function DeleteItemsOnTrack(track)
	for i=reaper.CountTrackMediaItems(track)-1, 0, -1 do
		local item = reaper.GetTrackMediaItem(track, i)
		if item then reaper.DeleteTrackMediaItem(track, item) end
	end
end

local function CollapseBlankItemAliasesToParentTrack(init_table, track_list)
	reaper.SelectAllMediaItems( 0, 0 ) -- unselect all items

	for _, contents in ipairs(init_table) do
		local track_depth = reaper.GetTrackDepth(reaper.GetMediaItemTrack(contents.item))
		if track_depth ~= 0 then
			local track = GetOutermostParentTrack(reaper.GetMediaItemTrack(contents.item)) -- Get the outermost parent

		  	if #track_list == 0 then
		  		DeleteItemsOnTrack(track)
		  		table.insert(track_list, track)
		  	end 

		  	for _, _ in ipairs(track_list) do
		  		if not table.contains(track_list, track) then
		  			DeleteItemsOnTrack(track)
		  			table.insert(track_list, track)
		  		end
		  	end

		  	local item = reaper.AddMediaItemToTrack(track)
		  	reaper.SetMediaItemPosition(item, contents.pos_start, 1)
		  	reaper.SetMediaItemLength(item, (contents.pos_end - contents.pos_start), 1)
		else
			reaper.MB("Can't select items in parent track", "Error", 0) return end
	end
end

function MergeOverlappingItems(track) 
	local item_mark_as_delete = {}	
	local B_item_start = 0
	local B_item_end = 0
	local merge_items = 0
	local first_item_start = 0
	local first = true
	local item_mark_as_delete_length = 0
	local group_id = 1
	local A_group = 0
	local B_group = 0
	local deletion_index = 0
	local in_group = false
	
	local media_item_on_track = reaper.CountTrackMediaItems(track)

	if media_item_on_track > 0 then
	
		-- INITIALIZE loop through items on track
		for i = 0, media_item_on_track-1  do

		-- GET ITEMS
		A_item = reaper.GetTrackMediaItem(track, i) -- Get selected item i
		A_take = reaper.GetActiveTake(A_item)

		if A_take == nil then -- If the item is a "text" item

			A_item_start = reaper.GetMediaItemInfo_Value(A_item, "D_POSITION")
			A_item_length = reaper.GetMediaItemInfo_Value(A_item, "D_LENGTH")
			A_item_end = A_item_start + A_item_length

			if first == true then --If first item in the loop
				first = false
			end
			
			if first == false and A_item_start < B_item_end then -- Compare the name, the start-end, and the color of the current item and the previous one

				item_mark_as_delete_length = item_mark_as_delete_length + 1
				deletion_index = deletion_index + 1
				item_mark_as_delete[deletion_index] = A_item
				
				if B_item_end > A_item_end then -- If item is included inside the previous one
					A_item_end = B_item_end -- then consider that the end of the actual item is the end of previous one
				end

				if i == media_item_on_track-1 then -- If item is the last of the loop
					first_item_length = A_item_end - first_item_start
					reaper.SetMediaItemInfo_Value(first_item, "D_LENGTH", first_item_length)
				end

			else -- if in a new group
					
				if i > 0 and first == false then -- If it's not the first item

					first_item_length = B_item_end - first_item_start

					if i == media_item_on_track-1 then -- If actual item is the last of the loop
						first_item_length = B_item_end - first_item_start
					end

					reaper.SetMediaItemInfo_Value(first_item, "D_LENGTH", first_item_length)
					group_id = group_id + 1
				end

				first = true
				first_item = A_item
				first_item_start = A_item_start
			end

			-- "Previous item" infos for A/B comparaison
			B_item = A_item
			B_item_start = A_item_start
			B_item_length = A_item_length
			B_item_end = A_item_end
			B_group = group_id

			end -- end if a text item

		end -- end loop through selected items

		for j = 1, item_mark_as_delete_length do -- Loop throught item marked as "to be deleted"
			reaper.DeleteTrackMediaItem(track, item_mark_as_delete[j]) --track is always A
		end			
	end -- if select item
end -- MergeOverlap

------------
--- MAIN ---
------------

local count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 0 then
	reaper.PreventUIRefresh(1)
	reaper.Undo_BeginBlock()
	reaper.ClearConsole()

	local init_sel_items =  {}
	local track_list = {}

	SaveSelectedItems(init_sel_items, count_sel_items)
	CollapseBlankItemAliasesToParentTrack(init_sel_items, track_list)

	for _, track in ipairs(track_list) do
		MergeOverlappingItems(track)
		for i=0, reaper.CountTrackMediaItems(track)-1 do
			local item = reaper.GetTrackMediaItem(track, i)

			reaper.SetMediaItemSelected(item, true)
			reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0.01)
			reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0.01)
			if not reaper.GetActiveTake(item) then reaper.AddTakeToMediaItem( item ) end

			local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", 0)

			reaper.ULT_SetMediaItemNote(item, track_name .. "_" .. string.format("%02d", i+1)) -- set notes
			reaper.GetSetMediaItemTakeInfo_String(
			reaper.GetActiveTake(item), "P_NAME", track_name .. "_" .. string.format("%02d", i+1), 1)
		end

-- auto fade
		local has_fade_preset = toboolean(reaper.GetExtState(section, "SD-pia_has_fade_preset")) or false
		if has_fade_preset then
			local fade_preset = reaper.GetExtState(section, "SD-pia_fade_preset") or 0
			if reaper.file_exists( scripts_directory .. "/" .. "PSP_Item Fader.lua") then
				reaper.SetExtState(section, "runitemfadergui", "false", true) -- turn gui off
				dofile(scripts_directory .. "PSP_Item Fader.lua") -- load shared utilities
				itemaliasext.ItemFader(fade_preset) -- run function
				reaper.SetExtState(section, "runitemfadergui", "true", true) -- turn gui back on
			end
		end
-- auto name
		local has_name_preset = toboolean(reaper.GetExtState(section, "SD-pia_has_name_preset")) or false
		if has_name_preset then
			local name_preset = reaper.GetExtState(section, "SD-pia_name_preset") or 0
			if reaper.file_exists( scripts_directory .. "/" .. "PSP_Item Namer.lua") then
				reaper.SetExtState(section, "runitemnamergui", "false", true) -- turn gui off
				dofile(scripts_directory .. "PSP_Item Namer.lua") -- load shared utilities
				itemaliasext.ItemNamer(name_preset) -- run function
				reaper.SetExtState(section, "runitemnamergui", "true", true) -- turn gui back on
			end
			for i=0, reaper.CountSelectedMediaItems(0)-1 do
				local item = reaper.GetSelectedMediaItem(0, i)
				local _, notes = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item), "P_NAME", "", false )
				reaper.GetSetMediaItemInfo_String(item, "P_NOTES", notes, true)
			end
		end
	end

	reaper.Undo_EndBlock("Create Parent Items", - 1)
	reaper.PreventUIRefresh(-1)
end