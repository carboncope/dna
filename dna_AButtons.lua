local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")
local LM		= LibStub('Masque', true)

--*****************************************************
--Locals
--*****************************************************
-- Lua APIs
local strsub, strsplit, strlower, strmatch, strtrim, strfind = string.sub, string.split, string.lower, string.match, string.trim, string.find
local format, tonumber, tostring = string.format, tonumber, tostring
local tsort, tinsert = table.sort, table.insert
local select, pairs, next, type = select, pairs, next, type
local error, assert = error, assert

-- WoW APIs
local _G = _G
local IsSpellInRange = IsSpellInRange
local GetSpellInfo = GetSpellInfo
local UnitExists = UnitExists
local GetSpellLink = GetSpellLink
local GetTime = GetTime

--********************************************************************************************
-- dna Secure Action Buttons tables
--********************************************************************************************
dna.AButtons					= {} 				--Action Buttons
dna.AButtons.Frames			= {}				--The Action Button Frames
dna.AButtons.ExternalButtons	= {}				--Saved table of external buttons
--dna.AButtons.SlotToSABFrame	= {}				--Convert action slots to external frames that we care about
dna.AButtons.RFrames			= {}				--The Rotation Button Frames used for binding a key to a rotation
dna.AButtons.bInitComplete 	= false				--The boolean to tell the engine the buttons need to be reinitialized
dna.AButtons.bInInit			= false				--The boolean to throttle calls to initialize
dna.AButtons.LastInit      	= GetTime()			--Last Initialization time stamp






