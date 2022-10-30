dna         	 		= LibStub("AceAddon-3.0"):NewAddon("dna","AceConsole-3.0","AceEvent-3.0","AceTimer-3.0","AceComm-3.0","AceHook-3.0")
dna.lib_acegui	 		= LibStub("AceGUI-3.0")
--dna.LibSimcraftParser	= LibStub("LibSimcraftParser")

dna.D					= {}																		-- General data table to hold stuff
dna.ui					= {} 																		-- UI table
dna.ElvUI				= nil
local L      			= LibStub("AceLocale-3.0"):GetLocale("dna")
local addon				= ...

if ( ElvUI ) then
	local EP 	 = LibStub("LibElvUIPlugin-1.0")
	dna.ElvUI   = unpack(ElvUI);
	dna.D.ElvUI = dna.ElvUI:NewModule('dna')
	dna.ElvUI:RegisterModule(dna.D.ElvUI:GetName())
	dna.D.ElvUI.Initialize = function()
		LibStub("LibElvUIPlugin-1.0"):RegisterPlugin(addon, dna.D.ElvUI.AddOptionMenu)
	end
end
function dna:ProcessSlashCommand(commandargs)
	if (dna.IsBlank(commandargs)) then
		if ( dna.ui.fMain and dna.ui.fMain:IsShown() ) then
			dna.ui.fMain:Hide()
		else
			dna.ui.CreateMainFrame()
		end
	elseif (commandargs=="debug") then
		dna:CreateDebugFrame()
	elseif (commandargs=="help") then
		print( L["common/help"] )
	else
		dna.ui.SelectRotation(commandargs, false)
	end
end

function dna:OnInitialize()
    local tDefaults = {
        global = {
            treeMain = {
                {
                    value = "dna.CreateOptionsPanel()",
                    text = L["maintree/options"],
                    icon = "Interface\\Icons\\INV_Misc_Gear_01",
                },
                {
                    value = "dna.CreateListsPanel()",
                    text = L["maintree/lists"],
                    icon = "Interface\\Icons\\TRADE_ARCHAEOLOGY_HIGHBORNE_SCROLL",
                    children = {},
                },
                {
                    value = "dna.CreateRotationsPanel()",
                    text = L["maintree/rotations"],
                    icon = "Interface\\PaperDollInfoFrame\\UI-GearManager-Undo",
                    children = {},
                },
            },
        },
    }

	dna.DB = LibStub("AceDB-3.0"):New("dna_ace_db", tDefaults )
	dna.DB:RegisterDefaults( tDefaults )
end

function dna:OnEnable()
	-- Initialize data
	dna.D.Prefix 		= 'dna'																			--Addon communications channel prefix


	dna.D.Specs 		= {}																			--Specializations
	dna.D.SpellInfo    = {}																				--Table to hold information about spells ex: ticktimes, traveltimes, base duration
	dna.D.PlayerCastHistory   = {}																				--Table to hold player casted spell names
	dna.D.PetCastHistory   = {}																				--Table to hold pet casted spell names

	-- dna.D.tExternalFrames = {}																		--Table of external frames to find keybindings
    dna.D.tAsciiKeyBits   = {}																			--Table of ascii key bits
	dna.D.ImportType      = nil																			--The type of import rotation or actionpack
	dna.D.ImportVersion   = nil																			--The version the import was created in
	dna.D.ImportName      = nil																			--Name of the import could be rotation / action pack
	dna.D.ImportIndex     = nil																			--The index of the action pack table insert
	-- dna.D.DamageTakenIndex  	= 1																		--The index of dna.D.P["DAMAGE_TAKEN"]
	-- dna.D.DamageTakenMaxHits  	= 100																--Maximum number of dna.D.P["DAMAGE_TAKEN"] hits to track
	dna.D.DebugTimerStart		= debugprofilestop()													--Initialize debug timer
	-- dna.D.nLastSpecSwitchTime	= 0

	dna.D.damageInLast5Seconds = 0
	dna.D.damageAmounts = {}
	dna.D.damageTimestamps = {}

	dna.D.UpdateMode   = 0																	--0=create new names for existing objects do not update
																										--1=update existing objects
																										--3=Abort updates if objects already exist + do not create if object does not exist
																										
	dna.D.GCDTime = 1.5
	dna.D.PClass = select(2, UnitClass("player") )

	--Save the tree keys for short syntax lookup, we may chose to add more menus to the main tree later on
	dna.D.OTK  = dna:SearchTable(dna.DB.global.treeMain, "value", "dna.CreateOptionsPanel()")			--Options Tree Key
	dna.D.OTM  = dna.DB.global.treeMain[dna.D.OTK]														--Options Tree main
    if not dna.D.OTM[dna.D.PClass] then dna.D.OTM[dna.D.PClass] = {} end 

	dna.D.LTK  = dna:SearchTable(dna.DB.global.treeMain, "value", "dna.CreateListsPanel()")				--Lists Tree Key
	dna.D.LTM  = dna.DB.global.treeMain[dna.D.LTK]														--Lists tree main
	dna.D.LTMC = dna.DB.global.treeMain[dna.D.LTK].children												--Lists tree main children

	dna.D.RTK  = dna:SearchTable(dna.DB.global.treeMain, "value", "dna.CreateRotationsPanel()")			--Rotations Tree Key
	dna.D.RTM  = dna.DB.global.treeMain[dna.D.RTK]														--Rotations tree main
	dna.D.RTMC = dna.DB.global.treeMain[dna.D.RTK].children												--Rotations tree main children

    -- Clear out NPC spells every reload so it doesnt get too big
    local nListKey = select(2, dna.AddList("NPC_INTERRUPTABLE", false, false))
    tremove(dna.D.LTMC, nListKey)
    nListKey = select(2, dna.AddList("NPC_OTHER", false, false))
    tremove(dna.D.LTMC, nListKey)

	dna.D.P={}		--Custom player tracked data for use in criteria

	dna.D.ResetDebugTimer=function()
		dna.D.DebugTimerStart = debugprofilestop()
	end
	dna.D.GetDebugTimerElapsed=function(minElapsed)
		local lReturn = ( debugprofilestop()-dna.D.DebugTimerStart )
		if ( lReturn > ( minElapsed or 0 ) ) then
			-- print(format(" E: %f ms:", elapsedTime)..tostring(suffix) )
		else
			lReturn = 0
		end
		return lReturn
	end
	dna.D.RunCode=function( code, lseprefix, pcalleprefix, ShowLSErrors, ShowPCErrors  )
		--lseprefix		= loadstring error print message prefix
		--lsegui		= loadstring error gui message
		--pcalleprefix 	= pcall error prefix
		local func, errorMessage = loadstring(code)
		if( not func ) then
			if ( ShowLSErrors ) then
				print( lseprefix..errorMessage )
				if ( dna.ui.fMain and dna.ui.fMain:IsShown() ) then dna.ui.fMain:SetStatusText( lseprefix..errorMessage ) end
			end
			return 1
		end
		success, errorMessage = pcall(func);								-- Call the function we loaded
		if( not success ) then
			if ( ShowPCErrors ) then print(pcalleprefix..errorMessage) end
			return 1
		end
		return 0
	end
	
	dna.D.Threads = {}
	dna.D.binds = {}
	dna.D.visibleNameplates = {}
	dna.D.DebuffExclusions = {							-- Ignore these debbuffs for debuff type checking
		[GetSpellInfo(15822)]   = true,					-- Dreamless Sleep
		[GetSpellInfo(24360)]   = true,					-- Greater Dreamless Sleep
		[GetSpellInfo(28504)]   = true,					-- Major Dreamless Sleep
		[GetSpellInfo(24306)]   = true,					-- Delusions of Jin'do
		[GetSpellInfo(46543)]   = true,					-- Ignite Mana
		[GetSpellInfo(16567)]   = true,					-- Tainted Mind
		[GetSpellInfo(39052)]   = true,					-- Sonic Burst
		[GetSpellInfo(30129)]   = true,					-- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		[GetSpellInfo(31651)]   = true,					-- Banshee Curse, Melee hit rating debuff
		[GetSpellInfo(124275)]  = true,					-- Light Stagger, cant be cured
	}

	dna.D.InitCriteriaClassTree()					   		-- Initialize the class criteria and default rotations
	if ( dna.IsBlank(dna.D.OTM[dna.D.PClass].selectedrotation) ) then
		self:SetRotationForCurrentSpec()					-- Select the rotation that matches the current specialization or talentgroup
	else
		dna.ui.SelectRotation(dna.D.OTM[dna.D.PClass].selectedrotation, false)	-- Select the last loaded rotation
	end

	-- dna.fSetTopLevelFrame=function(frmName)
		-- frmName:SetToplevel(true)
		-- frmName:SetFrameLevel(300)
		-- frmName:SetFrameLevel(300)
		-- frmName:SetFrameLevel(300)
	-- end
		
	-- Create debug frames
	for nIndex=0,5 do
		dna["frmPixel"..nIndex] = CreateFrame("Frame","dna.frmPixel"..nIndex,UIParent)
		dna["frmPixel"..nIndex]:ClearAllPoints()
		dna["frmPixel"..nIndex]:SetPoint("TOPLEFT",0,(0-nIndex))
		dna["frmPixel"..nIndex]:SetFrameStrata("TOOLTIP")
		dna["frmPixel"..nIndex]:SetWidth(1)
		dna["frmPixel"..nIndex]:SetHeight(1)
		dna["frmPixel"..nIndex]:SetToplevel(true)
		dna["frmPixel"..nIndex]:SetFrameLevel(128)
		dna["frmPixel"..nIndex]:Show()
		
		dna["txrPixel"..nIndex] = dna["frmPixel"..nIndex]:CreateTexture(dna["txrPixel"..nIndex], 'OVERLAY')
		dna["txrPixel"..nIndex]:ClearAllPoints()
		dna["txrPixel"..nIndex]:SetAllPoints(dna["frmPixel"..nIndex])
		dna["txrPixel"..nIndex]:SetColorTexture(0,0,0,1)
	end
	
	dna.frmRunning = CreateFrame("Frame","dna.frmRunning",UIParent);
	dna.frmRunning:ClearAllPoints();
    dna.frmRunning:SetPoint("CENTER", UIParent, "CENTER")
	dna.frmRunning:SetFrameStrata("TOOLTIP")
	dna.frmRunning:SetWidth(32);
	dna.frmRunning:SetHeight(32);
	dna.frmRunning:SetToplevel(true)
	dna.frmRunning:SetFrameLevel(128)
	dna.frmRunning:EnableMouse(false)
	dna.frmRunning:Show()
	dna.frmRunning:SetAlpha(1)
	
	dna.txrRunning = dna.frmRunning:CreateTexture('dna.txrRunning', 'OVERLAY')
	dna.txrRunning:ClearAllPoints()
	dna.txrRunning:SetAllPoints(dna.frmRunning)
	dna.txrRunning:SetWidth(32);
	dna.txrRunning:SetHeight(32);
	dna.txrRunning:SetTexture([[Interface\RAIDFRAME\ReadyCheck-Ready]])
	dna.nEnabled0Off1On = 0
    dna.txrRunning:SetAlpha(0)	-- Hide green checkmark
	
	-- Highest keybind text
    dna.fsHighestKeybind = dna.frmRunning:CreateFontString("dna.fsHighestKeybind", 'BACKGROUND')
	dna.fsHighestKeybind:ClearAllPoints()
    dna.fsHighestKeybind:SetPoint("CENTER", dna.frmRunning, "CENTER", 0, -40)
    dna.fsHighestKeybind:SetFont("Fonts\\FRIZQT__.TTF", 14)
    dna.fsHighestKeybind:SetSize(17, 17)
    dna.fsHighestKeybind:SetShadowOffset(2,-2)
    dna.fsHighestKeybind:SetTextColor(1, 1, 1, 1)

    -- Out of range texts
    dna.fsMeleeRange = dna.frmRunning:CreateFontString("dna.fsMeleeRange", 'BACKGROUND')
	dna.fsMeleeRange:ClearAllPoints()
    dna.fsMeleeRange:SetPoint("BOTTOMLEFT", dna.frmRunning, "BOTTOMLEFT", -16, 0);
    dna.fsMeleeRange:SetFont("Fonts\\FRIZQT__.TTF", 14)
    dna.fsMeleeRange:SetSize(17, 17)
    dna.fsMeleeRange:SetShadowOffset(2,-2)
    dna.fsMeleeRange:SetTextColor(1, 0, 0, 1)
    
    dna.fsRange = dna.frmRunning:CreateFontString("dna.fsRange", 'BACKGROUND')
	dna.fsRange:ClearAllPoints()
    dna.fsRange:SetPoint("BOTTOMLEFT", dna.frmRunning, "BOTTOMLEFT", -16, 16);
    dna.fsRange:SetFont("Fonts\\FRIZQT__.TTF", 14) 
    dna.fsRange:SetSize(17, 17)
    dna.fsRange:SetShadowOffset(2,-2)
    dna.fsRange:SetTextColor(1, 0, 0, 1)

	dna.fSetPixelColors=function()
		key1, key2 = GetBindingKey("dna Toggle")
		if (not key1) then
			for nIndex=0,5 do
				dna["frmPixel"..nIndex]:Hide()
			end
			return
		else
			for nIndex=0,5 do
				dna["frmPixel"..nIndex]:Show()
			end
		end
		
		-- Convert the strPassingActionKeyBind from the engine into a numeric ASCII code
		if dna.IsBlank(dna.strPassingActionKeyBind) then
			dna.nPassingActionASCII = 0
		else
			for nASCII=33,127 do
				if string.char(nASCII) == string.lower(dna.strPassingActionKeyBind) then
					dna.nPassingActionASCII = nASCII
					break
				end
			end
		end

		if dna.D.OTM[dna.D.PClass].bShowHighestKeybind then
			dna.fsHighestKeybind:SetText(dna.strPassingActionKeyBind)
		else
			dna.fsHighestKeybind:SetText("")
		end
		
		if dna.nPassingActionASCII ~= dna.D.nLastPassingActionASCII then
			dna.D.nLastPassingActionASCII = dna.nPassingActionASCII
		end

		-- Set Addon Black texture 0
		dna.txrPixel0:SetColorTexture(0, 0, 0, 1)
		
		-- Set Buffer texture 1
		dna.txrPixel1:SetColorTexture(0, 0, 0, 1)

		-- Set ASCII texture 2
		dna.txrPixel2:SetColorTexture((dna.nPassingActionASCII/255), 0, 0, 1)

		-- Set Buffer texture 3
		dna.txrPixel3:SetColorTexture(0, 0, 0, 1)
		
		-- Set texture 4
		if dna.nEnabled0Off1On == 1 then
			dna.txrPixel4:SetColorTexture(1, 1, 1, 1) -- enabled
		else
			dna.txrPixel4:SetColorTexture(0, 0, 0, 1) -- disabled
		end
		
		-- Set Buffer texture 5
		dna.txrPixel5:SetColorTexture(0, 0, 0, 1)
		
		-- The engine can fire before the frame is created so ensure frame is created
		if not dna.frmRunning then return end
		
		-- Show or hide the green checkmark enabled texture
		if dna.nEnabled0Off1On == 1 then
			dna.txrRunning:SetAlpha(1)	-- Show green checkmark
		else
			dna.txrRunning:SetAlpha(0)	-- Hide green checkmark
		end

		-- set the fsMeleeRange text
		local meleeRangeText = ""
		if ( dna.D.RTMC[dna.nSelectedRotationTableIndex]
			and dna.IsBlank(dna.D.RTMC[dna.nSelectedRotationTableIndex].meleespell) == false
			and UnitExists("target")
		) then
			-- User has input for spell to check
			local spellInRange = dna.GetSpellInRangeOfUnit( dna.D.RTMC[dna.nSelectedRotationTableIndex].meleespell, "target")
			local itemInRange = dna.GetItemInRangeOfUnit( dna.D.RTMC[dna.nSelectedRotationTableIndex].meleespell, "target")
			
			if ( spellInRange or itemInRange ) then
				meleeRangeText = ""
			else
				meleeRangeText = "M"
			end
		end
		dna.fsMeleeRange:SetText(meleeRangeText)
		
		-- set the fsRange text
		if ( dna.D.RTMC[dna.nSelectedRotationTableIndex]
			and dna.IsBlank(dna.D.RTMC[dna.nSelectedRotationTableIndex].rangespell) == false
			and dna.GetSpellInRangeOfUnit( dna.D.RTMC[dna.nSelectedRotationTableIndex].rangespell, "target") == false
			and UnitExists("target")
			) then
			dna.fsRange:SetText("R") -- OOR show a R for range
		else
			dna.fsRange:SetText("") -- In range for range spell hide the R
		end
	end

	-- loadstring all action criteria
	dna.fLoadCriteriaStrings = function()
		for nRotationKey, tRotation in pairs(dna.D.RTMC) do
            if tRotation.strClass == dna.D.PClass then
                for nActionKey, tAction in pairs(tRotation.children) do
                    local strCode = tAction.criteria
                    local script = nil
                    local strSyntaxError = nil
                    
                    if tAction.fCriteria == nil then
                        if (string.find( strCode or "", '--_dna_enable_lua' ) ) then
                            script, strSyntaxError = loadstring(strCode or "return false")
                        else
                            script, strSyntaxError = loadstring('return '..(strCode or "false"))
                        end

                        if script ~= nil then
                            tAction.fCriteria = script
                        else
                            tAction.fCriteria = nil
                            dna:dprint("fLoadCriteriaStrings Syntax error in:\n"..
								"|cffF95C25RotationName:|r"..tostring(tRotation.text).."\n"..
								"|cffF95C25ActionName:|r"..tostring(tAction.text).."\n"..
								"|cffF95C25Error:|r"..tostring(strSyntaxError))
                        end
                    end
                end
            end
		end
	end
	dna.fLoadCriteriaStrings()


	-- set the initial pixel stuff after all the functions have been loaded
	dna.nEnabled0Off1On = 0
	dna.fToggle = function(strKeyState)
		if tostring(strKeyState) == 'up' then
			if dna.nEnabled0Off1On == 1 then
				dna.nEnabled0Off1On = 0
			else
				dna.nEnabled0Off1On = 1
			end
		end
	end
	dna.bEngineReady = true

	-- function to toggle toggles on/off
	dna.bToggle = {}
	dna.ToggleNumber = function(nToggleNumber)
		dna.bToggle[nToggleNumber] = (not dna.bToggle[nToggleNumber])
	end

    -- LDB Menu setup
	if (LibStub and LibStub:GetLibrary('LibDataBroker-1.1', true)) then
		dna.D.LDB = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(L["common/dna"], {
			type = 'data source',
			text = L["common/dna"],
			icon = 'Interface\\AddOns\\dna\\Textures\\dna_icon32',
			OnClick = dna.ui.MenuOnClick,
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine(L["common/dna"])
				tooltip:AddLine(L["common/LDB/tt1"])
				tooltip:AddLine(L["common/LDB/tt2"])
				tooltip:AddLine(L["common/LDB/tt3"])
				tooltip:AddLine(L["common/LDB/tt4"])
			end,
		})
	end

	dna:RegisterChatCommand("dna", "ProcessSlashCommand")
	dna:RegisterComm(dna.D.Prefix)

	dna:RegisterEvent("PLAYER_ENTERING_WORLD", "PLAYER_ENTERING_WORLD")
	dna:RegisterEvent("UNIT_AURA", "UNIT_AURA")
	dna:RegisterEvent("UNIT_SPELLCAST_START", "UNIT_SPELLCAST_START")
	dna:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_START")
	dna:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_SUCCEEDED")
	dna:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED")
	dna:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "COMBAT_LOG_EVENT_UNFILTERED")
	dna:RegisterEvent("PLAYER_REGEN_ENABLED", "PLAYER_REGEN_ENABLED")
	dna:RegisterEvent("PLAYER_REGEN_DISABLED", "PLAYER_REGEN_DISABLED")
	dna:RegisterEvent("NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_ADDED");
	dna:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "NAME_PLATE_UNIT_REMOVED");
	
    self.tEngine = self:ScheduleRepeatingTimer("fEngineOnTimer", .1)
end
