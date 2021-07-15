--[[
 * ReaScript Name: PSP_Utils.lua
 * NoIndex: true
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.31
 * Version: 0.2.2
--]]

--[[
 * Changelog:
 * v0.2.2 (2021-07-14)
  + Test
--]]

-------------
--- DEBUG ---
-------------

local console = true
local function Msg(text) if console then reaper.ShowConsoleMsg(tostring(text) .. '\n') end end

-----------------
--- VARIABLES ---
----------------- 

utils = {} -- utils "class"
local using_reaimguiversion = 0.5

-----------------
--- FUNCTIONS ---
-----------------

-- std library extensions

function toboolean(text)
    if text == "true" then return true
    else return false end
end

-- custom functions

function utils.PrintStatement()
	reaper.ShowConsoleMsg("hello world!")
end

function utils.GetUsingReaImGuiVersion()
	return using_reaimguiversion
end

function utils.GetInstalledReaImGuiVersion()
	local _, installed_reaimguiversion = reaper.ImGui_GetVersion()
	return tonumber(installed_reaimguiversion:sub(0, 3))
end