--[[
 * ReaScript Name: PSP_Config.lua
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.32
 * Version: 0.8
 * Provides:
 *  [nomain] PSP_Utils.lua
--]]

--[[
 * Changelog:
 * v0.8 (2021-07-16)
	+ Added parent item alias preset support
 * v0.7 (2021-07-15)
    + Added font scaling support
 * v0.6.3 (2021-07-14)
 	- Removed utilities
 * v0.6 (2021-07-14)
 	+ Now with font-scaling!
 * v0.5.1 (2021-07-08)
 	+ Better error message
 * v0.5 (2021-07-07)
 	+ Upgraded to ReaImGui v5
 * v0.4 (2021-06-21)
	+ General Update
 	+ Initial Release
 * v0.3 (2021-06-08)
 	+ Added config option (mute env behind automation items)
 * v0.1 (2021-06-07)
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
    settings.pia = {} -- parent alias items
local is_finished = false
local button_width = 100

local window_flags = 
    reaper.ImGui_WindowFlags_NoCollapse() |
    reaper.ImGui_WindowFlags_AlwaysAutoResize()

-----------------
--- FUNCTIONS ---
-----------------

local function SetExtStates()
--[[GENERAL]]
    -- Font
    reaper.SetExtState(section, "SD_font_size", settings.font_size, 1)
--[[SOUND DESIGN]]
    -- Take Marker Randomizer
	reaper.SetExtState(section, "SD_is_random", tostring(settings.is_random), 1)
	reaper.SetExtState(section, "SD_chop_end", tonumber(settings.chop_end), 1)
    -- Trim Automation Items
	reaper.SetExtState(section, "SD_mute_envelope", tostring(settings.mute_envelope), 1)
    -- Parent Item Aliases
    reaper.SetExtState(section, "SD-pia_has_fade_preset", tostring(settings.pia.has_fade_preset), 1)
    reaper.SetExtState(section, "SD-pia_fade_preset", tostring(settings.pia.fade_preset), 1)
    reaper.SetExtState(section, "SD-pia_has_name_preset", tostring(settings.pia.has_name_preset), 1)
    reaper.SetExtState(section, "SD-pia_name_preset", tostring(settings.pia.name_preset), 1)
end

local function GetExtStates()
--[[GENERAL]]
    -- Font
    settings.font_size = tonumber(reaper.GetExtState(section, "SD_font_size")) or 14
    settings.font_size = math.clamp(settings.font_size, 10, 36)
--[[SOUND DESIGN]]
    -- Take Marker Randomizer
    settings.is_random = toboolean(reaper.GetExtState(section, "SD_is_random")) or false
    settings.chop_end = reaper.GetExtState(section, "SD_chop_end") or 0
    -- Trim Automation Items
    settings.mute_envelope = toboolean(reaper.GetExtState(section, "SD_mute_envelope")) or false
    -- Parent Item Aliases
    settings.pia.has_fade_preset = toboolean(reaper.GetExtState(section, "SD-pia_has_fade_preset")) or false
    settings.pia.fade_preset = reaper.GetExtState(section, "SD-pia_fade_preset")
    settings.pia.has_name_preset = toboolean(reaper.GetExtState(section, "SD-pia_has_name_preset")) or false
    settings.pia.name_preset = reaper.GetExtState(section, "SD-pia_name_preset")
end

------------
--- MAIN ---
------------

if not reaper.APIExists('ImGui_GetVersion') then
    reaper.ShowMessageBox("ReaImGui is not installed. \n\nNavigate to Extensions → Reapack → Browse Packages, and install ReaImGui first.", "Error", 0) return end
if (utils.GetUsingReaImGuiVersion() ~= utils.GetInstalledReaImGuiVersion()) then
    reaper.ShowMessageBox("Please ensure that you are running ReaImGui version " .. utils.GetUsingReaImGuiVersion() .. " or later", "Error", 0) return end

GetExtStates()

local ctx = reaper.ImGui_CreateContext('PSP Config', reaper.ImGui_ConfigFlags_DockingEnable())
local font = reaper.ImGui_CreateFont('sans-serif', settings.font_size)
reaper.ImGui_AttachFont(ctx, font)

function frame()
  	local rv

    if reaper.ImGui_CollapsingHeader(ctx, 'General') then
        if reaper.ImGui_TreeNode(ctx, 'Font') then
            rv, settings.font_size = reaper.ImGui_InputInt(ctx, "Font Size", settings.font_size)
            if reaper.ImGui_IsItemHovered(ctx, flagsIn) then
                reaper.ImGui_SetTooltip( ctx, "Font scaling will be applied after scripts are reloaded") end
            settings.font_size = math.clamp(settings.font_size, 10, 36)
            reaper.ImGui_TreePop(ctx)
        end
    end

  	if reaper.ImGui_CollapsingHeader(ctx, 'Sound Design') then
   		if reaper.ImGui_TreeNode(ctx, 'Take Marker Randomizer') then
	    	rv, settings.is_random = reaper.ImGui_Checkbox(ctx, "Is Random", settings.is_random)
	    	rv, settings.chop_end = reaper.ImGui_InputText(ctx, "Chop End (sec)", settings.chop_end, reaper.ImGui_InputTextFlags_CharsDecimal())
	    	reaper.ImGui_TreePop(ctx)
	    end
	    if reaper.ImGui_TreeNode(ctx, 'Trim Automation Items') then
	    	rv, settings.mute_envelope = reaper.ImGui_Checkbox(ctx, "Mute envelope behind automation items", settings.mute_envelope)
	    	reaper.ImGui_TreePop(ctx)
	    end
        if reaper.ImGui_TreeNode(ctx, 'Parent Item Aliases') then
            -- auto fades
            rv, settings.pia.has_fade_preset = reaper.ImGui_Checkbox(ctx, "Has Fade Preset", settings.pia.has_fade_preset)
            if settings.pia.has_fade_preset then
                rv, settings.pia.fade_preset = reaper.ImGui_InputInt(ctx, "Fade Preset", settings.pia.fade_preset) end
            settings.pia.fade_preset = math.clamp(settings.pia.fade_preset, 1, 4)         
            -- auto name
            rv, settings.pia.has_name_preset = reaper.ImGui_Checkbox(ctx, "Has Name Preset", settings.pia.has_name_preset)
            if settings.pia.has_name_preset then
                rv, settings.pia.name_preset = reaper.ImGui_InputInt(ctx, "Name Preset", settings.pia.name_preset) end  
            settings.pia.name_preset = math.clamp(settings.pia.name_preset, 1, 4)  
            reaper.ImGui_TreePop(ctx)
        end
  	end

  	if reaper.ImGui_GetWindowWidth(ctx) < 300 then
  		button_width = reaper.ImGui_GetWindowWidth(ctx) / 3
  	else
  		button_width = 100 end

  	if reaper.ImGui_Button(ctx, "OK", button_width) then
  		SetExtStates() ; is_finished = true end

  	reaper.ImGui_SameLine( ctx )

  	if reaper.ImGui_Button(ctx, "Cancel", button_width) then
  		is_finished = true end

  	reaper.ImGui_SameLine( ctx )

  	if reaper.ImGui_Button(ctx, "Apply", button_width) then
  		SetExtStates() end
end

function loop()
  	reaper.ImGui_PushFont(ctx, font)
  	local visible, open = reaper.ImGui_Begin(ctx, 'PSP Config', true, window_flags)

  	if is_finished then
  		open = false end

  	if visible then
    	frame() ; reaper.ImGui_End(ctx) end

  	reaper.ImGui_PopFont(ctx)
  
  	if open then
    	reaper.defer(loop)
  	else
    	reaper.ImGui_DestroyContext(ctx) end
end

reaper.defer(loop)