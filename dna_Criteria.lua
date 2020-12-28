local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--********************************************************************************************
-- Locals
--********************************************************************************************
local strsub, strsplit, strlower, strmatch, strtrim, strfind = string.sub, string.split, string.lower, string.match, string.trim, string.find
local format, tonumber, tostring = string.format, tonumber, tostring
local tsort, tinsert = table.sort, table.insert
local select, pairs, next, type = select, pairs, next, type
local error, assert = error, assert

-- WoW API
local _G = _G
local IsCurrentAction = IsCurrentAction
local IsSpellInRange = IsSpellInRange
local GetGlyphSocketInfo = GetGlyphSocketInfo
local GetNumGlyphSockets = GetNumGlyphSockets
local GetSpellInfo = GetSpellInfo
local GetSpellLink = GetSpellLink
local GetTime = GetTime
local UnitExists = UnitExists
local UnitGUID   = UnitGUID
local UnitHealth = UnitHealth

--********************************************************************************************
-- Creat root tree tables
--********************************************************************************************
local PLAYER_CRITERIA	=1
local PET_CRITERIA		=2
local UNIT_CRITERIA		=3
local ITEM_CRITERIA		=4
local SPELL_CRITERIA	=5
local CLASS_CRITERIA	=6
local TALENTS_CRITERIA	=7
local MISC_CRITERIA		=8
local GROUP_CRITERIA	=9
dna.D.criteria   		={}
dna.D.criteriatree		={}
dna.D.criteriatree[PLAYER_CRITERIA]={ value='return "d/player"', text=L["d/player"], icon="Interface\\Icons\\Achievement_Character_Human_Female", children = {} }
dna.D.criteriatree[PET_CRITERIA]={ value='return "d/pet"', text=L["d/pet"], icon="Interface\\Icons\\INV_Box_PetCarrier_01", children = {} }
dna.D.criteriatree[UNIT_CRITERIA]={ value='return "d/unit"', text=L["d/unit"],icon="Interface\\Worldmap\\SkullGear_64Grey", children = {} }
dna.D.criteriatree[ITEM_CRITERIA]={ value='return "d/item"', text=L["d/item"],icon="Interface\\PaperDollInfoFrame\\UI-GearManager-ItemIntoBag", children = {} }
dna.D.criteriatree[SPELL_CRITERIA]={ value='return "d/spell"', text=L["d/spell"],icon="Interface\\SPELLBOOK\\Spellbook-Icon", children = {} }
dna.D.criteriatree[CLASS_CRITERIA]={ value='return "d/class"', text=L["d/class"],icon="Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",iconCoords=CLASS_ICON_TCOORDS[ select(2,UnitClass("player")) ], children = {} }
dna.D.criteriatree[TALENTS_CRITERIA]={ value='return "d/talents"', text=L["d/talents"],icon="Interface\\BUTTONS\\UI-MicroButton-Talents-Up", children = {} }
dna.D.criteriatree[MISC_CRITERIA]={ value='return "d/misc"', text=L["d/misc"],icon="Interface\\TARGETINGFRAME\\PortraitQuestBadge", children = {}	}
dna.D.criteriatree[GROUP_CRITERIA]={ value='return "d/group"', text=L["d/group"],icon="Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon", children = {}	}
--********************************************************************************************
--UTILITY FUNCTIONS
--********************************************************************************************
dna.GetActionTable=function( actionName )
	local returnFrame    	= nil
	if ( dna.nSelectedRotationTableIndex and not dna.IsBlank(actionName) ) then
		local lAKey = dna:SearchTable(dna.D.RTMC[dna.D.OTM[dna.D.PClass].selectedrotationkey].children, "text", actionName)
		if ( lAKey ) then
			returnFrame = dna.D.RTMC[dna.D.OTM[dna.D.PClass].selectedrotationkey].children[lAKey]
		end
	end
	return returnFrame
end
dna.AppendActionDebug=function( strText )
	if not dna.ui.sgMain
		or not dna.ui.sgMain.tgMain.sgPanel.mlebInfo
		or not dna.ui.sgMain.tgMain.sgPanel.mlebInfo.frame:IsShown()
	then
        dna.strAPIFunctionsCalled = nil
        return  -- Save memory, there is no reason to set debug if the gui is not open
    end
    dna.strAPIFunctionsCalled = tostring(dna.strAPIFunctionsCalled).."\n"..format(" |cffF95C25[|r%.3f ms|cffF95C25]|r", dna.D.GetDebugTimerElapsed() )..tostring(strText)
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.fGetFrameInfo=function( frmTarget )


	local strFrameName = ''
	local strHotKey = nil
	local nSlot	= 0
	local strType = ''
	local varId = ''
	local strSubType = ''
	local strName = nil
	local strText = ''

	if (frmTarget and frmTarget.HotKey) then
		strFrameName = tostring(frmTarget:GetName())
		strHotKey = tostring(frmTarget.HotKey:GetText())
		nSlot = frmTarget._state_action or frmTarget.action or 0
		if ( nSlot ~= 0 ) then
			strType, varId, strSubType = GetActionInfo( nSlot )
			strText = GetActionText( nSlot )
		end

		if (strType and strType == 'spell' ) then
			strName = GetSpellInfo(varId)
		elseif (strType and strType == 'macro' ) then
			strName = strText
		elseif (strType and strType == 'item' ) then
			strName = GetItemInfo(varId)
		end
	end

	return {
		['name']=strName,
		['hotkey']=strHotKey,
		['slot']=nSlot,
		['strtype']=strType,
		['strsubtype']=strSubType,
		['id']=varId,
		['framename']=strFrameName
	}
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.fSetDebugInfo=function( nRotationTableIndex, nActionTableIndex )

	if not dna.ui.sgMain
		or not dna.ui.sgMain.tgMain.sgPanel.mlebInfo
		or not dna.ui.sgMain.tgMain.sgPanel.mlebInfo.frame:IsShown()
	then return end

	local tEngineAction = dna.D.RTMC[nRotationTableIndex].children[nActionTableIndex]
	if not tEngineAction then return end
	if nActionTableIndex ~= dna.ui.STL[3] then return end	-- Return if we are trying to set debug for a action not displayed

	-- Grab the mousover button to check its values
	local tMouseOver = dna.fGetFrameInfo( GetMouseFocus() )

	local strText =
	--dna.D.RTMC[nRotationTableIndex].text
	--..'['..tEngineAction.text.."]".."\n"
	'|cffF95C25MouseOver:|r Name='..tostring(tMouseOver.name)..',HotKey='..tostring(tMouseOver.hotkey).."\n"
	..'Id='..tostring(tMouseOver.id)..',strType='..tostring(tMouseOver.strtype)..',slot='..tMouseOver.slot
	..',FrameName='..tMouseOver.framename.."\n"
	..'|cffF95C25Highest Priority:|r '..tostring(dna.strPassingActionName)..' |cffF95C25Keybind:|r '..tostring(dna.strPassingActionKeyBind).."\n"
	..'|cffF95C25Syntax:|r '..(dna.D.RTMC[nRotationTableIndex].children[nActionTableIndex].strSyntax or L["action/_dna_syntax_status/pass"]).."\n"
	.."|cffF95C25Criteria:|r "..tostring(dna.bAPIResult).."\n"
	.."|cffF95C25Functions:|r\n"..dna.strAPIFunctionsCalled

	if ( not dna.bPauseDebugDisplay ) then
		dna.ui.sgMain.tgMain.sgPanel.mlebInfo:SetText( '' )
		dna.ui.sgMain.tgMain.sgPanel.mlebInfo:SetText( strText )
	end
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetHastedTime=function(unhastedTime)
	return unhastedTime / (1 + UnitSpellHaste("player") / 100)
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetItemId=function(item)
	if (dna.IsBlank(item)) then
		return nil
	end
	local _,_,itemID = strfind(item or '', "item:(%d+):")
	if (not dna.IsBlank(itemID)) then
		return itemID
	end
	local s1,s2,iS,s3 = strfind(item or "", "%[(.*)%]")
	_,_,itemID = strfind( select(2,GetItemInfo( iS or item )) or '', "item:(%d+):" )
	if (not dna.IsBlank(itemID)) then
		return itemID
	end
	return nil
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitItemInventoryId=function(unit, slot)
	dna.D.ResetDebugTimer()
	local lReturn=nil
    local itemID, nSlot = nil
    if ( dna.IsNumeric(slot) ) then
        nSlot = slot
    else
        nSlot = GetInventorySlotInfo(slot)
    end
    itemID = GetInventoryItemID(unit, nSlot)
    if ( itemID and not GetInventoryItemBroken(unit, nSlot) ) then
        lReturn = itemID
    end

	dna.AppendActionDebug( 'GetUnitItemInventoryId(unit='..tostring(unit)..',slot='..tostring(slot)..')='..tostring(lReturn) )
	return lReturn
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetItemName=function(item)
	return GetItemInfo( dna.GetItemId(item) or "") or item
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellID=function(spell)
	local sSpell = tostring(spell)
	if ( dna.D.SpellInfo[sSpell] and dna.D.SpellInfo[sSpell].spellid ) then
        return dna.D.SpellInfo[sSpell].spellid
    else
		local spellLink = GetSpellLink( sSpell or 0 )
		local spellID = strmatch(tostring(spellLink) or '', "spell:(%d+)");
		if ( spellID ) then return spellID end
		return nil
	end
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellName=function(spell)
	local sSpell = tostring(spell)
	if ( dna.D.SpellInfo[sSpell] and dna.D.SpellInfo[sSpell].spellname ) then
        return dna.D.SpellInfo[sSpell].spellname
    else
		return GetSpellInfo( dna.GetSpellID(sSpell) or 0 ) or spell or ''
	end
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerSpellCritChance=function(spellschool)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	local sSchool = spellschool or 6
	local minCrit = GetSpellCritChance(sSchool)
	local lCritChance
	for i=(sSchool+1), 7 do
		lCritChance = GetSpellCritChance(i)
		lReturn = min(minCrit, lCritChance)
	end
	dna.AppendActionDebug( 'GetPlayerSpellCritChance(spellschool='..tostring(spellschool)..')='..tostring(lReturn) )
	return lReturn
end

--********************************************************************************************
--PLAYER CRITERIA
--********************************************************************************************
if true then
dna.GetPlayerCombatTime=function()
	dna.D.ResetDebugTimer()
	local lReturn = 0
	if ( dna.D.P.EnteredCombatTime and dna.D.P.EnteredCombatTime > 0) then
		lReturn = (GetTime() - dna.D.P.EnteredCombatTime)
	end
	dna.AppendActionDebug( 'GetPlayerCombatTime()='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/player/GetPlayerCombatTime"]={
	a=2,
	a1l=L["d/common/co/l"],a1dv="<",a1tt=L["d/common/co/tt"],
	a2l=L["d/common/seconds/l"],a2dv="60",a2tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetPlayerCombatTime()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerCombatTime")', text=L["d/player/GetPlayerCombatTime"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerEffectiveAttackPower=function()
	local base, posBuff, negBuff = UnitAttackPower("player");
	local effective = base + posBuff + negBuff;
	return effective
end
dna.D.criteria["d/player/GetPlayerEffectiveAttackPower"]={
	a=2,
	a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
	a2l=L["d/common/count/l"],a2dv="6000",a2tt=L["d/common/count/tt"],
	f=function () return format('dna.GetPlayerEffectiveAttackPower()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerEffectiveAttackPower")', text=L["d/player/GetPlayerEffectiveAttackPower"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerGCD=function()
	dna.D.ResetDebugTimer()
	local GCD = dna.GetSpellCooldown(61304)
	dna.AppendActionDebug( 'GetPlayerGCD()='..tostring(GCD) )
	return GCD
end
dna.D.criteria["d/player/GetPlayerGCD"]={
	a=2,
	a1l=L["d/common/co/l"],a1dv="<",a1tt=L["d/common/co/tt"],
	a2l=L["d/common/seconds/l"],a2dv="60",a2tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetPlayerGCD()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerGCD")', text=L["d/player/GetPlayerGCD"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerHasAutoAttackOn=function()
	local nAutoAttackSlotId = nil
	for i = 1,72 do
		if ( IsAttackAction(i) ) then
			nAutoAttackSlotId = i
		end
	end

	if nAutoAttackSlotId then
		if not IsCurrentAction(nAutoAttackSlotId) then
			return false
		else
			return true
		end
	else
		return nil
	end
end
dna.D.criteria["d/player/GetPlayerHasAutoAttackOn"]={
	a=0,
	f=function () return format('dna.GetPlayerHasAutoAttackOn()==true') end
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerHasAutoAttackOn")', text=L["d/player/GetPlayerHasAutoAttackOn"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerHasGlyphSpellActive=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = false
	if spell then
		for i=1,GetNumGlyphSockets() do
			local lGSID = tostring( select(4, GetGlyphSocketInfo(i)) )
			local lGSN = dna.GetSpellName(lGSID)
			if ( spell==lGSID or spell==lGSN or dna.GetSpellID(spell)==lGSID ) then
				lReturn = true
			end
		end
	end
	dna.AppendActionDebug( 'GetPlayerHasGlyphSpellActive(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/player/GetPlayerHasGlyphSpellActive"]={
	a=1,
	a1l=L["d/common/gs/l"],a1dv='',a1tt=L["d/common/gs/tt"],
	f=function () return format('dna.GetPlayerHasGlyphSpellActive(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerHasGlyphSpellActive")', text=L["d/player/GetPlayerHasGlyphSpellActive"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerIsAutoCastingSpell=function(spell)
	local lSID = dna.GetSpellName(spell)
	local lReturn = false

	if ( lSID ) then
		local autocastAllowed
		autocastAllowed, lReturn = GetSpellAutocast(lSID)
	end

	dna.AppendActionDebug( 'GetPlayerIsAutoCastingSpell(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/player/GetPlayerIsAutoCastingSpell"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetPlayerIsAutoCastingSpell(%q)', dna.ui["ebArg1"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerIsAutoCastingSpell")', text=L["d/player/GetPlayerIsAutoCastingSpell"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerIsSolo=function(checklfgstatus)
	dna.D.ResetDebugTimer()
	local lPlayerIsSolo = true
	local members = GetNumGroupMembers()
	if ( members > 0 ) then lPlayerIsSolo = false end
	if ( checklfgstatus and lPlayerIsSolo ) then
		if ( GetLFGQueueStats(LE_LFG_CATEGORY_LFD)
			or GetLFGQueueStats(LE_LFG_CATEGORY_LFR)
			or GetLFGQueueStats(LE_LFG_CATEGORY_RF)
			or GetLFGQueueStats(LE_LFG_CATEGORY_SCENARIO)
			) then
			lPlayerIsSolo = false
		end
	end
	dna.AppendActionDebug( 'GetPlayerIsSolo(checklfgstatus='..tostring(checklfgstatus)..')='..tostring(lPlayerIsSolo) )
	return lPlayerIsSolo
end
dna.D.criteria["d/player/GetPlayerIsSolo"]={
	a=1,
	a1l=L["d/common/truefalse/l"],a1dv="false",a1tt=L["d/common/truefalse/tt"],
	f=function () return format('dna.GetPlayerIsSolo(%s)', dna.ui["ebArg1"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerIsSolo")', text=L["d/player/GetPlayerIsSolo"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPlayerKnowsSpell=function(spell)
	dna.D.ResetDebugTimer()
	local ldnaSpellID = dna.GetSpellID(spell)
	if ( not dna.IsBlank( ldnaSpellID ) ) then
		lReturn = IsPlayerSpell( ldnaSpellID )
	end
	dna.AppendActionDebug( 'GetPlayerKnowsSpell(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/player/GetPlayerKnowsSpell"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetPlayerKnowsSpell(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[PLAYER_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/player/GetPlayerKnowsSpell")', text=L["d/player/GetPlayerKnowsSpell"] } )

end


--********************************************************************************************
--PET CRITERIA
--********************************************************************************************
dna.GetPetSpellKnown=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local lSID=dna.GetSpellID(spell)
	if ( lSID ) then
		lReturn = IsSpellKnown(lSID, true)
	end
	dna.AppendActionDebug( 'GetPetSpellKnown(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/pet/GetPetSpellKnown"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv='',a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetPetSpellKnown(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[PET_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/pet/GetPetSpellKnown")', text=L["d/pet/GetPetSpellKnown"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetPetSpellAutocasting=function(spell)
	dna.D.ResetDebugTimer()
	local bReturn = false
	local nSpellId=dna.GetSpellID(spell)
	if ( nSpellId ) then
		bAutoCastable, bAutoState = GetSpellAutocast(nSpellId)
		if bAutoCastable then
			bReturn = bAutoState
		end
	end
	dna.AppendActionDebug( 'GetPetSpellAutocasting(spell='..tostring(spell)..')='..tostring(bReturn) )
	return bReturn
end
dna.D.criteria["d/pet/GetPetSpellAutocasting"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv='',a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetPetSpellAutocasting(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[PET_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/pet/GetPetSpellAutocasting")', text=L["d/pet/GetPetSpellAutocasting"] } )

--********************************************************************************************
--UNIT CRITERIA
--********************************************************************************************
dna.GetUnitCastingInterruptibleSpell=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = false
	-- https://wow.gamepedia.com/API_UnitCastingInfo
	local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)

	if (not name) then
		-- https://wow.gamepedia.com/API_UnitChannelInfo
		name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
	end
	if ( name ) then
		if ( notInterruptible == nil or notInterruptible == false ) then
			lReturn = true
		end
	end
	dna.AppendActionDebug( 'GetUnitCastingInterruptibleSpell(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitCastingInterruptibleSpell"]={
	a=1,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitCastingInterruptibleSpell(%q)', dna.ui["ebArg1"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitCastingInterruptibleSpell")', text=L["d/unit/GetUnitCastingInterruptibleSpell"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitAffectingCombat=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = false
    
    lReturn =  UnitAffectingCombat(unit)

	dna.AppendActionDebug( 'GetUnitAffectingCombat(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitAffectingCombat"]={
	a=1,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitAffectingCombat(%q)', dna.ui["ebArg1"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitAffectingCombat")', text=L["d/unit/GetUnitAffectingCombat"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitCastingDuration=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = -1
	local unitCasting, _, _, _, startTime, _, _, _, CantInterrupt = UnitCastingInfo(unit)
	if (not unitCasting) then
		unitCasting, _, _, _, startTime, _, _, CantInterrupt = UnitChannelInfo(unit)
	end
	if ( unitCasting ) then
		lReturn =  GetTime() - (startTime/1000)
	end

	dna.AppendActionDebug( 'GetUnitCastingDuration(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitCastingDuration"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv=".30",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetUnitCastingDuration(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitCastingDuration")', text=L["d/unit/GetUnitCastingDuration"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitCastingSpell=function(unit, spell)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local unitCasting, _, _, _, startTime = UnitCastingInfo(unit)
	if (not unitCasting) then
		unitCasting, _, _, _, startTime = UnitChannelInfo(unit)
	end
	if (unitCasting) then
		hasbeencasting =  GetTime() - (startTime/1000)
		if ( dna.GetSpellName( spell ) ==  unitCasting ) then
			lReturn = true
		end
	end
	dna.AppendActionDebug( 'GetUnitCastingSpell(unit='..tostring(unit)..',spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitCastingSpell"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/sp/l"],a2dv=L["d/common/sp/dv"],a2tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetUnitCastingSpell(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitCastingSpell")', text=L["d/unit/GetUnitCastingSpell"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitCastingSpellInList=function(unit, list)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local unitCasting, startTime; unitCasting, _, _, _, startTime = UnitCastingInfo(unit)

	if (not unitCasting) then
		unitCasting, _, _, _, startTime = UnitChannelInfo(unit)
	end
	if (unitCasting) then
		local nListKey = dna:SearchTable(dna.D.LTMC, "value", 'dna.CreateListPanel([=['..list..']=])')
        if dna.D.LTMC[nListKey].entries[unitCasting] == true then
		-- for k, v in pairs(dna.D.LTMC[TreeLevel2].treeList) do
			-- local _,_,spellID = strfind(v.value, '"(.*)","s"')
			-- if ( dna.GetSpellName( spellID ) ==  unitCasting ) then
            lReturn = true
			-- end
		end
	end
	dna.AppendActionDebug( 'GetUnitCastingSpellInList(unit='..tostring(unit)..',list='..tostring(list)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitCastingSpellInList"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/list/l"],a2dv=L["d/common/list/dv"],a2tt=L["d/common/list/tt"],
	f=function () return format('dna.GetUnitCastingSpellInList(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitCastingSpellInList")', text=L["d/unit/GetUnitCastingSpellInList"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitCastPercent=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	local nTotalCastTime = 0
	local unitCasting, _, _, _, nStartTime, nEndTime = UnitCastingInfo(unit)
	if (not unitCasting) then
		unitCasting, _, _, _, nStartTime, nEndTime = UnitChannelInfo(unit)
	end
	-- dna:dprint(tostring(unitCasting).."-"..tostring(nStartTime).."-"..tostring(nEndTime))
	if ( unitCasting and nEndTime and nEndTime > 0) then
		nTotalCastTime = nEndTime - nStartTime
		nCastedTime = (GetTime()*1000) - nStartTime
		lReturn = ( nCastedTime / nTotalCastTime ) * 100
	else
		lReturn = 0
	end
	dna.AppendActionDebug( 'GetUnitCastPercent(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitCastPercent"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/pe/l"],a3dv="50",a3tt=L["d/common/pe/tt"],
	f=function () return format('dna.GetUnitCastPercent(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitCastPercent")', text=L["d/unit/GetUnitCastPercent"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitCastTimeleft=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	local unitCasting, _, _, _, startTime, endTime = UnitCastingInfo(unit)

	if (not unitCasting) then
		unitCasting, _, _, _, startTime, endTime = UnitChannelInfo(unit)
	end
	if ( unitCasting and endTime and endTime > 0) then
		lReturn = (endTime/1000) - GetTime()
	else
		lReturn = 0
	end
	dna.AppendActionDebug( 'GetUnitCastTimeleft(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitCastTimeleft"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetUnitCastTimeleft(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitCastTimeleft")', text=L["d/unit/GetUnitCastTimeleft"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitDebuffTimeleftInList=function(unit,aura,filter)
	dna.D.ResetDebugTimer()
	local TreeLevel2=dna:SearchTable(dna.D.LTMC, "value", 'dna.CreateListPanel([=['..list..']=])')
	for k, v in pairs(dna.D.LTMC[TreeLevel2].treeList) do
		local _,_,lListSpellID = strfind(v.value, '"(.*)","s"')
		if ( not dna.IsBlank(lListSpellID) ) then
				local name, _, _, _, _, _, expirationTime = dna:GetUnitDebuff(unit, dna.GetSpellName(lListSpellID), filter)
				if (name) then
					return dna.NilToNumeric(expirationTime)
				end
		end
	end
	dna.AppendActionDebug( 'GetUnitDebuffTimeleftInList(unit='..tostring(unit)..',list='..tostring(list)..',filter='..tostring(filter)..')='..tostring(lReturn) )
	return 0
end
dna.D.criteria["d/unit/GetUnitDebuffTimeleftInList"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/list/l"],a2dv=L["d/common/list/dv"],a2tt=L["d/common/list/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HARMFUL",a3tt=L["d/common/aurafilter/tt"],
	f=function () return format('dna.GetUnitDebuffTimeleftInList(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitDebuffTimeleftInList")', text=L["d/unit/GetUnitDebuffTimeleftInList"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitExists=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = false
	if ( unit and UnitExists(unit) ) then
		lReturn = true
	end
	dna.AppendActionDebug( 'GetUnitExists(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitExists"]={
	a=1,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitExists(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitExists")', text=L["d/unit/GetUnitExists"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitGUIDIsGroupMember=function(unitGUID)
	local group, num = nil, 0
	local unitID
	local lLowestHealthPercent = 100
	local lLowestUnitID = "player"

	if ( UnitGUID("player") == unitGUID ) then
-- print("unitGUID=playerGUID")
		return true
	end
	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	end
	for i = 1, num do
		unitID = group..i;
-- print("checking if "..unitGUID.."=="..UnitGUID(unitID))
		if ( UnitGUID(unitID) == unitGUID ) then
			return true
		end
	end
	return false
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasBuffID=function(unit,aura,filter)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local lName = dna:GetUnitBuff(unit, dna.GetSpellName(aura), filter)
	if lName then
		lReturn = true
	end

	dna.AppendActionDebug( 'GetUnitHasBuffID(unit='..tostring(unit)..",aura="..tostring(aura)..",filter="..tostring(filter)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHasBuffID"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HELPFUL",a3tt=L["d/common/aurafilter/tt"],
	f=function () return format('dna.GetUnitHasBuffID(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasBuffID")', text=L["d/unit/GetUnitHasBuffID"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasBuffIDStacks=function(unit,aura,filter)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric(select(4,dna:GetUnitBuff(unit, dna.GetSpellName(aura), filter)))

	dna.AppendActionDebug( 'GetUnitHasBuffNameStacks(unit='..tostring(unit)..',buff='..tostring(buff)..',filter='..tostring(filter)..')='..tostring(lReturn) )
	return dna.NilToNumeric(lReturn)
end
dna.D.criteria["d/unit/GetUnitHasBuffIDStacks"]={
	a=5,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HELPFUL",a3tt=L["d/common/aurafilter/tt"],
	a4l=L["d/common/co/l"],a4dv=">=",a4tt=L["d/common/co/tt"],
	a5l=L["d/common/stacks/l"],a5dv="2",a5tt=L["d/common/stacks/tt"],
	f=function () return format('dna.GetUnitHasBuffIDStacks(%q,%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg5"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasBuffIDStacks")', text=L["d/unit/GetUnitHasBuffIDStacks"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasBuffName=function(unit,aura,filter)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local lName = dna:GetUnitAura(unit, dna.GetSpellName(aura), filter)
	if lName then
		lReturn = true
	end

	dna.AppendActionDebug( 'GetUnitHasBuffName(unit='..tostring(unit)..",aura="..tostring(aura)..",filter="..tostring(filter)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHasBuffName"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HELPFUL",a3tt=L["d/common/aurafilter/tt"],
	f=function () return format('dna.GetUnitHasBuffName(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasBuffName")', text=L["d/unit/GetUnitHasBuffName"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasBuffNameInList=function(unit, list)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local TreeLevel2=dna:SearchTable(dna.D.LTMC, "value", 'dna.CreateListPanel([=['..list..']=])')
	for k,v in pairs(dna.D.LTMC[TreeLevel2].treeList) do
		local _,_,spellID = strfind(v.value, '"(.*)","s"')
		if ( spellID and dna.GetUnitHasBuffName( unit, spellID ) ) then
			return true
		end
	end
	return false
end
dna.D.criteria["d/unit/GetUnitHasBuffNameInList"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/list/l"],a2dv=L["d/common/list/dv"],a2tt=L["d/common/list/tt"],
	f=function () return format('dna.GetUnitHasBuffNameInList(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasBuffNameInList")', text=L["d/unit/GetUnitHasBuffNameInList"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasBuffNameStacks=function(unit, aura, filter)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric(select(4,dna:GetUnitAura(unit, dna.GetSpellName(aura), filter)))

	dna.AppendActionDebug( 'GetUnitHasBuffNameStacks(unit='..tostring(unit)..',buff='..tostring(buff)..',filter='..tostring(filter)..')='..tostring(lReturn) )
	return dna.NilToNumeric(lReturn)
end
dna.D.criteria["d/unit/GetUnitHasBuffNameStacks"]={
	a=5,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HELPFUL",a3tt=L["d/common/aurafilter/tt"],
	a4l=L["d/common/co/l"],a4dv=">=",a4tt=L["d/common/co/tt"],
	a5l=L["d/common/stacks/l"],a5dv="2",a5tt=L["d/common/stacks/tt"],
	f=function () return format('dna.GetUnitHasBuffNameStacks(%q,%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg5"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasBuffNameStacks")', text=L["d/unit/GetUnitHasBuffNameStacks"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasBuffNameTimeleft=function(unit, aura, filter)
	dna.D.ResetDebugTimer()
	local l_return = 0
	local l_expire_time = select(6, dna:GetUnitAura(unit, dna.GetSpellName(aura), filter))
	if l_expire_time then
		l_return = ( l_expire_time - GetTime() )
	end
	if l_return < 0 then l_return = 0 end
	dna.AppendActionDebug( 'GetUnitHasBuffNameTimeleft(unit='..tostring(unit)..',aura='..tostring(aura)..',filter='..tostring(filter)..')='..tostring(l_return) )
	return dna.NilToNumeric(l_return)
end
dna.D.criteria["d/unit/GetUnitHasBuffNameTimeleft"]={
	a=5,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HELPFUL",a3tt=L["d/common/aurafilter/tt"],
	a4l=L["d/common/co/l"],a4dv=">=",a4tt=L["d/common/co/tt"],
	a5l=L["d/common/seconds/l"],a5dv="2.5",a5tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetUnitHasBuffNameTimeleft(%q,%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg5"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasBuffNameTimeleft")', text=L["d/unit/GetUnitHasBuffNameTimeleft"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasDebuffID=function(unit, debuffid, filter)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local lName = dna:GetUnitDebuff(unit, dna.GetSpellName(debuffid), filter)
	if lName then
		lReturn = true
	end
	
	dna.AppendActionDebug( 'GetUnitHasDebuffID(unit='..tostring(unit)..",debuffid="..tostring(debuffid)..",filter="..tostring(filter)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHasDebuffID"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/debuffid/l"],a2dv=L["d/common/debuffid/dv"],a2tt=L["d/common/debuffid/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HARMFUL",a3tt=L["d/common/aurafilter/tt"],
	f=function () return format('dna.GetUnitHasDebuffID(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasDebuffID")', text=L["d/unit/GetUnitHasDebuffID"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasDebuffName=function(unit, aura, filter)
	dna.D.ResetDebugTimer()
	local lReturn = false

	local lName = dna:GetUnitAura(unit, dna.GetSpellName(aura), filter)
	if lName then
		lReturn = true
	end

	dna.AppendActionDebug( 'GetUnitHasDebuffName(unit='..tostring(unit)..",aura="..tostring(aura)..",filter="..tostring(filter)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHasDebuffName"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HARMFUL",a3tt=L["d/common/aurafilter/tt"],
	f=function () return format('dna.GetUnitHasDebuffName(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasDebuffName")', text=L["d/unit/GetUnitHasDebuffName"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasDebuffNameInList=function(unit, list)
	local TreeLevel2=dna:SearchTable(dna.D.LTMC, "value", 'dna.CreateListPanel([=['..list..']=])')
	for k, v in pairs(dna.D.LTMC[TreeLevel2].treeList) do
		local _,_,spellID = strfind(v.value, '"(.*)","s"')
		if ( dna.GetUnitHasDebuffName( unit, spellID, '' ) ) then
			return true
		end
	end
	return false
end
dna.D.criteria["d/unit/GetUnitHasDebuffNameInList"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/list/l"],a2dv=L["d/common/list/dv"],a2tt=L["d/common/list/tt"],
	f=function () return format('dna.GetUnitHasDebuffNameInList(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasDebuffNameInList")', text=L["d/unit/GetUnitHasDebuffNameInList"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasDebuffNameStacks=function(unit,aura,filter)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	local lStacks = select(3, dna:GetUnitDebuff(unit, dna.GetSpellName(aura), filter))
	lReturn = lStacks or 0

	dna.AppendActionDebug( 'GetUnitHasDebuffNameStacks(unit='..tostring(unit)..',aura='..tostring(aura)..',filter='..tostring(filter)..')='..tostring(lReturn) )
	return dna.NilToNumeric(lReturn)
end
dna.D.criteria["d/unit/GetUnitHasDebuffNameStacks"]={
	a=5,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HELPFUL",a3tt=L["d/common/aurafilter/tt"],
	a4l=L["d/common/co/l"],a4dv=">=",a4tt=L["d/common/co/tt"],
	a5l=L["d/common/stacks/l"],a5dv="2",a5tt=L["d/common/stacks/tt"],
	f=function () return format('dna.GetUnitHasDebuffNameStacks(%q,%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg5"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasDebuffNameStacks")', text=L["d/unit/GetUnitHasDebuffNameStacks"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasDebuffNameTimeleft=function(unit, aura, filter)
	dna.D.ResetDebugTimer()
	local l_return = 0
	-- https://wow.gamepedia.com/API_UnitAura  expirationTime = 6
	local l_expire_time = select(6, dna:GetUnitDebuff(unit, dna.GetSpellName(aura), filter))
	if l_expire_time then
		l_return = ( l_expire_time - GetTime() )
	end
	if l_return < 0 then l_return = 0 end

	dna.AppendActionDebug( 'GetUnitHasDebuffNameTimeleft(unit='..tostring(unit)..',aura='..tostring(aura)..',filter='..tostring(filter)..')='..tostring(l_return) )
	return dna.NilToNumeric(l_return)
end
dna.D.criteria["d/unit/GetUnitHasDebuffNameTimeleft"]={
	a=5,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/aura/l"],a2dv=L["d/common/aura/dv"],a2tt=L["d/common/aura/tt"],
	a3l=L["d/common/aurafilter/l"],a3dv="HARMFUL",a3tt=L["d/common/aurafilter/tt"],
	a4l=L["d/common/co/l"],a4dv=">=",a4tt=L["d/common/co/tt"],
	a5l=L["d/common/seconds/l"],a5dv="2.5",a5tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetUnitHasDebuffNameTimeleft(%q,%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg5"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasDebuffNameTimeleft")', text=L["d/unit/GetUnitHasDebuffNameTimeleft"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasDebuffType=function(unit, dtype)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local id = 1
	while( true ) do
		local name, _, _, debuffType = UnitAura(unit, id, "HARMFUL")
		
		if( not name ) then break end
		if string.upper(debuffType) == string.upper(dtype) and not dna.D.DebuffExclusions[name] then
			lReturn =  true
			break
		end
		id = id + 1
	end
	dna.AppendActionDebug( 'GetUnitHasDebuffType(unit='..tostring(unit)..",dtype="..tostring(dtype)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHasDebuffType"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/debufftype/l"],a2dv=L["d/common/debufftype/dv"],a2tt=L["d/common/debufftype/tt"],
	f=function () return format('dna.GetUnitHasDebuffType(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasDebuffType")', text=L["d/unit/GetUnitHasDebuffType"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.D.criteria["d/unit/GetUnitHasMyBuffName"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/buff/l"],a2dv=L["d/common/buff/dv"],a2tt=L["d/common/buff/tt"],
	f=function () return format('dna.GetUnitHasBuffName(%q,%q,"PLAYER")', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasMyBuffName")', text=L["d/unit/GetUnitHasMyBuffName"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.D.criteria["d/unit/GetUnitHasMyDebuffID"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/debuffid/l"],a2dv=L["d/common/debuffid/dv"],a2tt=L["d/common/debuffid/tt"],
	f=function () return format('dna.GetUnitHasDebuffID(%q,%q,"player")', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasMyDebuffID")', text=L["d/unit/GetUnitHasMyDebuffID"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.D.criteria["d/unit/GetUnitHasMyDebuffName"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/debuff/l"],a2dv=L["d/common/debuff/dv"],a2tt=L["d/common/debuff/tt"],
	f=function () return format('dna.GetUnitHasDebuffName(%q,%q,"PLAYER")', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasMyDebuffName")', text=L["d/unit/GetUnitHasMyDebuffName"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.D.criteria["d/unit/GetUnitHasMyDebuffNameStacks"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/debuff/l"],a2dv=L["d/common/debuff/dv"],a2tt=L["d/common/debuff/tt"],
	a3l=L["d/common/co/l"],a3dv=">=",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/stacks/l"],a4dv="2",a4tt=L["d/common/stacks/tt"],
	f=function () return format('dna.GetUnitHasDebuffNameStacks(%q,%q,"PLAYER")%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasMyDebuffNameStacks")', text=L["d/unit/GetUnitHasMyDebuffNameStacks"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.D.criteria["d/unit/GetUnitHasMyDebuffNameTimeleft"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/debuff/l"],a2dv=L["d/common/debuff/dv"],a2tt=L["d/common/debuff/tt"],
	a3l=L["d/common/co/l"],a3dv=">=",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/seconds/l"],a4dv="2",a4tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetUnitHasDebuffNameTimeleft(%q,%q,"PLAYER")%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasMyDebuffNameTimeleft")', text=L["d/unit/GetUnitHasMyDebuffNameTimeleft"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHasMySpellTicksRemaining=function(unit, spell, baseticktime)
	dna.D.ResetDebugTimer()
	local lspellID	= dna.GetSpellID(spell)
	local lunitGUID = nil
	local lReturn	= 0
	if ( unit and UnitExists(unit) ) then
		lunitGUID = UnitGUID(unit)
	end
	if ( not baseticktime ) then
		if ( dna.D.SpellInfo[spell] and dna.D.SpellInfo[spell].baseticktime ) then
			baseticktime = dna.D.SpellInfo[spell].baseticktime
		else
			baseticktime = 2
		end
	end
	if ( lspellID and lunitGUID and dna.D.P.TS[lspellID..':'..lunitGUID] ) then
 		local lHastedTickTime = dna.GetSpellTickTimeOnUnit(lspellID, baseticktime, unit)
		if ( dna.D.P.TS[lspellID..':'..lunitGUID].atype == dna.D.AuraTypes["DEBUFF"] ) then
			lReturn = math.ceil( dna.GetUnitHasDebuffNameTimeleft(unit,lspellID,"PLAYER") / (lHastedTickTime or 2) )
		elseif ( dna.D.P.TS[lspellID..':'..lunitGUID].atype == dna.D.AuraTypes["BUFF"] ) then
			lReturn = math.ceil( dna.GetUnitHasBuffNameTimeleft(unit,lspellID,"PLAYER") / (lHastedTickTime or 2) )
		end
	end
	dna.AppendActionDebug( 'GetUnitHasMySpellTicksRemaining(unit='..tostring(unit)..",spell="..tostring(spell)..",baseticktime="..tostring(baseticktime)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHasMySpellTicksRemaining"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/sp/l"],a2dv=L["d/common/sp/dv"],a2tt=L["d/common/sp/tt"],
	a3l=L["d/common/ticktime/l"],a3dv="2",a3tt=L["d/common/ticktime/tt"],
	f=function () return format('dna.GetUnitHasMySpellTicksRemaining(%q,%q,%s)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHasMySpellTicksRemaining")', text=L["d/unit/GetUnitHasMySpellTicksRemaining"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHealth=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric( UnitHealth(unit) ) or -1
	dna.AppendActionDebug( 'GetUnitHealth(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHealth"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv="<",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/he/l"],a3dv="15000",a3tt=L["d/common/he/tt"],
	f=function () return format('dna.GetUnitHealth(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHealth")', text=L["d/unit/GetUnitHealth"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHealthLost=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	if ( unit and UnitExists(unit) ) then
		lReturn = ( UnitHealthMax(unit) - UnitHealth(unit) ) or 0
	end
	dna.AppendActionDebug( 'GetUnitHealthLost(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHealthLost"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv="<",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/he/l"],a3dv="15000",a3tt=L["d/common/he/tt"],
	f=function () return format('dna.GetUnitHealthLost(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHealthLost")', text=L["d/unit/GetUnitHealthLost"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitHealthPercent=function(unit)
	dna.D.ResetDebugTimer()

	local lReturn			= -1
	local lUnitHealthMax	= dna.NilToNumeric(UnitHealthMax(unit))
	local lUnitHealth		= dna.NilToNumeric(UnitHealth(unit))

	if (lUnitHealthMax > 0) then
		lReturn = (lUnitHealth/lUnitHealthMax)*100
	end

	dna.AppendActionDebug( 'GetUnitHealthPercent(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitHealthPercent"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv="<",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/pe/l"],a3dv="75",a3tt=L["d/common/pe/tt"],
	f=function () return format('dna.GetUnitHealthPercent(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitHealthPercent")', text=L["d/unit/GetUnitHealthPercent"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitIsFriend=function(unit, otherunit)
	dna.D.ResetDebugTimer()
	local lReturn = False
	lReturn = UnitIsFriend(unit,otherunit)
	dna.AppendActionDebug( 'GetUnitIsFriend(unit='..tostring(unit)..',otherunit='..tostring(otherunit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitIsFriend"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
    a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitIsFriend(%q, %q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitIsFriend")', text=L["d/unit/GetUnitIsFriend"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitIsEnemy=function(unit, otherunit)
	dna.D.ResetDebugTimer()
	local lReturn = False
	lReturn = UnitIsEnemy(unit,otherunit)
	dna.AppendActionDebug( 'GetUnitIsEnemy(unit='..tostring(unit)..',otherunit='..tostring(otherunit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitIsEnemy"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
    a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitIsEnemy(%q, %q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitIsEnemy")', text=L["d/unit/GetUnitIsEnemy"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitIsMoving=function(unit)
	return (GetUnitSpeed(unit) > 0)
end
dna.D.criteria["d/unit/GetUnitIsMoving"]={
	a=1,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitIsMoving(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitIsMoving")', text=L["d/unit/GetUnitIsMoving"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitIsPlayerControlled=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = False
	lReturn = UnitPlayerControlled(unit)
	dna.AppendActionDebug( 'GetUnitIsPlayerControlled(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitIsPlayerControlled"]={
	a=1,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	f=function () return format('dna.GetUnitIsPlayerControlled(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitIsPlayerControlled")', text=L["d/unit/GetUnitIsPlayerControlled"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.D.criteria["d/unit/GetUnitIsUnit"]={
	a=2,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/un/l"],a2dv="focus",a2tt=L["d/common/un/tt"],
	f=function () return format('UnitIsUnit(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitIsUnit")', text=L["d/unit/GetUnitIsUnit"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitLevel=function(unit)
	dna.D.ResetDebugTimer()
	local lReturn = -1
	if ( unit ) then
		lReturn = UnitLevel(unit)
	end
	dna.AppendActionDebug( 'GetUnitLevel(unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitLevel"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/number/l"],a3dv="102",a3tt=L["d/common/number/tt"],
	f=function () return format('dna.GetUnitLevel(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitLevel")', text=L["d/unit/GetUnitLevel"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitNeedsHeal=function( unit, percent, debuffabsorblist )
	dna.D.ResetDebugTimer()
	local lReturn = false
    
    if ( UnitIsFriend( 'player', unit) ) then
        -- 2 way to turn true, list specified or health percent lower than percent
        if ( not dna.IsBlank(debuffabsorblist) ) then
            if ( dna.GetUnitHasDebuffNameInList( unit,debuffabsorblist ) ) then
                lReturn = true
            end
        end
        if ( dna.GetUnitHealthPercent(unit) <= percent ) then
            lReturn = true
        end
    end

	dna.AppendActionDebug( 'GetUnitNeedsHeal(unit='..tostring(unit)..',percent='..tostring(percent)..',debuffabsorblist='..tostring(debuffabsorblist)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitNeedsHeal"]={
	a=3,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/pe/l"],a2dv="75",a2tt=L["d/common/pe/tt"],
	a3l=L["d/common/list/l"],a3dv=L["d/common/list/dv"],a3tt=L["d/common/list/tt"],
	f=function () return format('dna.GetUnitNeedsHeal(%q,%s,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitNeedsHeal")', text=L["d/unit/GetUnitNeedsHeal"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitNumberItemsEquippedInList=function(unit, list)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	if ( unit and list ) then
		local TreeLevel2=dna:SearchTable(dna.D.LTMC, "value", 'dna.CreateListPanel([=['..list..']=])')
		if (  dna.D.LTMC[TreeLevel2] ) then
			for slot = 1, EQUIPPED_LAST do
				local lWearingItemID = dna.GetUnitItemInventoryId(unit, slot)
				if ( not dna.IsBlank(lWearingItemID) ) then
					for k,v in pairs(dna.D.LTMC[TreeLevel2].treeList) do
						local _,_,itemID = strfind(v.value, '"(.*)","i"')
						if ( itemID and itemID == tostring(lWearingItemID) ) then
							lReturn = lReturn + 1
						end
					end
				end
			end
		end
	end
	dna.AppendActionDebug( 'GetUnitNumberItemsEquippedInList(unit='..tostring(unit)..',list='..tostring(list)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitNumberItemsEquippedInList"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="4",a3tt=L["d/common/count/tt"],
	a4l=L["d/common/list/l"],a4dv=L["d/common/list/dv"],a4tt=L["d/common/list/tt"],
	f=function () return format('dna.GetUnitNumberItemsEquippedInList(%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitNumberItemsEquippedInList")', text=L["d/unit/GetUnitNumberItemsEquippedInList"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitPower=function(unit, powertype, bool)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric(UnitPower(unit, powertype, bool))
	dna.AppendActionDebug( 'GetUnitPower(unit='..tostring(unit)..",powertype="..tostring(powertype)..",bool="..tostring(bool)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitPower"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/power/l"],a2dv="SPELL_POWER_MANA",a2tt=L["d/common/power/tt"],
	a3l=L["d/common/co/l"],a3dv="<",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/count/l"],a4dv="0",a4tt=L["d/common/count/tt"],
	f=function () return format('dna.GetUnitPower(%q,%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitPower")', text=L["d/unit/GetUnitPower"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitPowerDeficit=function(unit, powertype, bool)
	dna.D.ResetDebugTimer()
	local l_return = -1
	local l_current_power = dna.NilToNumeric(UnitPower(unit, powertype, bool))
	local l_max_power = dna.NilToNumeric(UnitPowerMax(unit, powertype, bool))
	local l_return = l_max_power - l_current_power

	dna.AppendActionDebug( 'GetUnitPowerDeficit(unit='..tostring(unit)..",powertype="..tostring(powertype)..",bool="..tostring(bool)..')='..tostring(l_return) )
	return l_return
end
dna.D.criteria["d/unit/GetUnitPowerDeficit"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/power/l"],a2dv="SPELL_POWER_MANA",a2tt=L["d/common/power/tt"],
	a3l=L["d/common/co/l"],a3dv="<",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/count/l"],a4dv="0",a4tt=L["d/common/count/tt"],
	f=function () return format('dna.GetUnitPowerDeficit(%q,%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitPowerDeficit")', text=L["d/unit/GetUnitPowerDeficit"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitPowerMax=function(unit, powertype, bool)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric(UnitPowerMax(unit, powertype, bool))
	dna.AppendActionDebug( 'GetUnitPowerMax(unit='..tostring(unit)..",powertype="..tostring(powertype)..",bool="..tostring(bool)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitPowerMax"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/power/l"],a2dv="SPELL_POWER_MANA",a2tt=L["d/common/power/tt"],
	a3l=L["d/common/co/l"],a3dv="<",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/count/l"],a4dv="0",a4tt=L["d/common/count/tt"],
	f=function () return format('dna.GetUnitPowerMax(%q,%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitPowerMax")', text=L["d/unit/GetUnitPowerMax"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitPowerPercent=function(unit, powertype, bool)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	local lPower = dna.NilToNumeric(UnitPower(unit, powertype, bool))
	local lPowerMax = dna.NilToNumeric(UnitPowerMax(unit, powertype))
	if ( lPower > 0 and lPowerMax > 0 ) then
		lReturn = (lPower/lPowerMax)*100
	end
	dna.AppendActionDebug( 'GetUnitPowerPercent(unit='..tostring(unit)..",powertype="..tostring(powertype)..",bool="..tostring(bool)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/unit/GetUnitPowerPercent"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="target",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/power/l"],a2dv="SPELL_POWER_MANA",a2tt=L["d/common/power/tt"],
	a3l=L["d/common/co/l"],a3dv="<",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/pe/l"],a4dv="75",a4tt=L["d/common/pe/tt"],
	f=function () return format('dna.GetUnitPowerPercent(%q,%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitPowerPercent")', text=L["d/unit/GetUnitPowerPercent"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetUnitThreatSituation=function(unit, otherunit)
	return UnitThreatSituation(unit, otherunit) or -1
end
dna.D.criteria["d/unit/GetUnitThreatSituation"]={
	a=4,
	a1l=L["d/common/un/l"],a1dv="player",a1tt=L["d/common/un/tt"],
	a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	a3l=L["d/common/co/l"],a3dv="==",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/threatstatus/l"],a4dv=L["d/common/threatstatus/dv"],a4tt=L["d/common/threatstatus/tt"],
	f=function () return format('dna.GetUnitThreatSituation(%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText()) end,
}
tinsert( dna.D.criteriatree[UNIT_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/unit/GetUnitThreatSituation")', text=L["d/unit/GetUnitThreatSituation"] } )
--********************************************************************************************
--ITEM CRITERIA
--********************************************************************************************
if true then
dna.GetItemCooldown=function(item)
	dna.D.ResetDebugTimer()
	local lReturn = 999
	local lItemId = dna.GetItemId( item )

	if ( not dna.IsBlank(lItemId) ) then
		local startICD, inICD, nEnable = GetItemCooldown( dna.GetItemId( item ) )

		lReturn = (dna.NilToNumeric(startICD) + dna.NilToNumeric(inICD) - GetTime())

		if lReturn < 0 then lReturn = 0 end

		if nEnable == 0 then lReturn = 999 end	-- Set cooldown to high if item enabled==0 (e.g. Potion used in combat)

	end
	dna.AppendActionDebug( 'GetItemCooldown(item='..tostring(item)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/item/GetItemCooldown"]={
	a=3,
	a1l=L["d/common/item/l"],a1dv="",a1tt=L["d/common/item/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetItemCooldown(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetItemCooldown")', text=L["d/item/GetItemCooldown"] } )
----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------- 
dna.GetItemCooldownLessThanGCD=function(item)
	local GCD = dna.GetSpellCooldown(61304)
	local ICD = dna.GetItemCooldown(item)
	if ICD <= (GCD+1) then
		return true
	else
		return false
	end
end
dna.D.criteria["d/item/GetItemCooldownLessThanGCD"]={
	a=1,
	a1l=L["d/common/item/l"],a1dv="",a1tt=L["d/common/item/tt"],
	f=function () return format('dna.GetItemCooldownLessThanGCD(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetItemCooldownLessThanGCD")', text=L["d/item/GetItemCooldownLessThanGCD"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetItemCount=function(item)
	dna.D.ResetDebugTimer()
	local lReturn = 0
    
	lReturn = GetItemCount( item )
	dna.AppendActionDebug( 'GetItemCount(item='..tostring(item)..')='..tostring(lReturn) )
    
	return lReturn
end
dna.D.criteria["d/item/GetItemCount"]={
	a=3,
	a1l=L["d/common/item/l"],a1dv="",a1tt=L["d/common/item/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="3",a3tt=L["d/common/count/tt"],
	f=function () return format('dna.GetItemCount(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetItemCount")', text=L["d/item/GetItemCount"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetItemInRangeOfUnit=function(item, unit)
	return IsItemInRange(item, unit)
end
dna.D.criteria["d/item/GetItemInRangeOfUnit"]={
	a=2,
	a1l=L["d/common/item/l"],a1dv="",a1tt=L["d/common/item/tt"],
	a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	f=function () return format('dna.GetItemInRangeOfUnit(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetItemInRangeOfUnit")', text=L["d/item/GetItemInRangeOfUnit"] } )
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetItemIsEquipped=function(item)
	dna.D.ResetDebugTimer()
	local lReturn = false

	lReturn = IsEquippedItem(item)

	dna.AppendActionDebug( 'GetItemIsEquipped(item='..tostring(item)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/item/GetItemIsEquipped"]={
	a=1,
	a1l=L["d/common/item/l"],a1dv="",a1tt=L["d/common/item/tt"],
	f=function () return format('dna.GetItemIsEquipped(%q)', dna.ui["ebArg1"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetItemIsEquipped")', text=L["d/item/GetItemIsEquipped"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSlotCooldown=function(slot)
	dna.D.ResetDebugTimer()
	local lReturn = 999

	local startICD, inICD, nEnable = GetInventoryItemCooldown( "player",  GetInventorySlotInfo(slot) )

	lReturn = (dna.NilToNumeric(startICD) + dna.NilToNumeric(inICD) - GetTime())
	if lReturn < 0 then lReturn = 0 end
	if nEnable == 0 then lReturn = 999 end	-- Set cooldown to high if item enabled==0 (e.g. Potion used in combat)

	dna.AppendActionDebug( 'GetSlotCooldown(slot='..tostring(slot)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/item/GetSlotCooldown"]={
	a=3,
	a1l=L["d/common/slotname/l"],a1dv="",a1tt=L["d/common/slotname/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetSlotCooldown(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetSlotCooldown")', text=L["d/item/GetSlotCooldown"] } )
----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------- 
dna.GetSlotCooldownLessThanGCD=function(slot)
	local GCD = dna.GetSpellCooldown(61304)
	local ICD = dna.GetSlotCooldown(slot)
	if ICD <= (GCD+1) then
		return true
	else
		return false
	end
end
dna.D.criteria["d/item/GetSlotCooldownLessThanGCD"]={
	a=1,
	a1l=L["d/common/slotname/l"],a1dv="",a1tt=L["d/common/slotname/tt"],
	f=function () return format('dna.GetSlotCooldownLessThanGCD(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[ITEM_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/item/GetSlotCooldownLessThanGCD")', text=L["d/item/GetSlotCooldownLessThanGCD"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--********************************************************************************************
--SPELL CRITERIA
--********************************************************************************************

-- dna.GetSpellAppliedAttackPower=function(spell, unit)
	-- local lspellID = dna.GetSpellID(spell)
	-- local lunitGUID = UnitGUID(unit)
	-- if ( lspellID and lunitGUID and dna.D.P.TS[lspellID..':'..lunitGUID] ) then
		-- return dna.D.P.TS[lspellID..':'..lunitGUID].smap
	-- else
		-- return 0
	-- end
-- end
-- dna.D.criteria["d/spell/GetSpellAppliedAttackPower"]={
	-- a=2,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	-- f=function () return format('dna.GetSpellAppliedAttackPower(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
-- }
-- tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAppliedAttackPower")', text=L["d/spell/GetSpellAppliedAttackPower"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- dna.GetSpellAppliedBonusDamage=function(spell, spellTreeID, unit)
	-- dna.D.ResetDebugTimer()
	-- local lspellID = dna.GetSpellID(spell)
	-- local lunitGUID = UnitGUID(unit)
	-- local lReturn = 0
	-- if ( lspellID and lunitGUID and spellTreeID and dna.D.P.TS[lspellID..':'..lunitGUID] ) then
		-- lReturn = dna.D.P.TS[lspellID..':'..lunitGUID].smbd[tostring(spellTreeID)]
	-- end
	-- dna.AppendActionDebug( 'GetSpellAppliedBonusDamage(spell='..tostring(spell)..',spellTreeID='..tostring(spellTreeID)..',unit='..tostring(unit)..')='..tostring(lReturn) )
	-- return lReturn
-- end
-- dna.D.criteria["d/spell/GetSpellAppliedBonusDamage"]={
	-- a=3,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/spellschool/l"],a2dv="6",a2tt=L["d/common/spellschool/tt"],
	-- a3l=L["d/common/un/l"],a3dv="target",a3tt=L["d/common/un/tt"],
	-- f=function () return format('dna.GetSpellAppliedBonusDamage(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
-- }
-- tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAppliedBonusDamage")', text=L["d/spell/GetSpellAppliedBonusDamage"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- dna.GetSpellAppliedBonusDPS=function(spell, spellTreeID, baseticktime, unit)
	-- dna.D.ResetDebugTimer()
	-- local lReturn = 0
 	-- local lCritChance  = dna.GetSpellAppliedCritPercent(spell, spellTreeID, unit) or 0
	-- local lBonusDamage = dna.GetSpellAppliedBonusDamage(spell, spellTreeID, unit) or 0
	-- local lTickTime    = dna.GetSpellTickTimeOnUnit(spell, baseticktime, unit) or 0
	--Spell power base and spell power coeffecient are not dynamic so there is no need to include them in this bonus DPS calculation
	-- if ( lTickTime > 0 ) then
		-- lReturn = ( lBonusDamage * (1 + 1 * lCritChance / 100) / lTickTime )
	-- end
	-- dna.AppendActionDebug( 'GetSpellAppliedBonusDPS(spell='..tostring(spell)..',spellTreeID='..tostring(spellTreeID)..',baseticktime='..tostring(baseticktime)..',unit='..tostring(unit)..')='..tostring(lReturn) )
	-- return lReturn
-- end
-- dna.D.criteria["d/spell/GetSpellAppliedBonusDPS"]={
	-- a=4,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/spellschool/l"],a2dv="6",a2tt=L["d/common/spellschool/tt"],
	-- a3l=L["d/common/ticktime/l"],a3dv="2",a3tt=L["d/common/ticktime/tt"],
	-- a4l=L["d/common/un/l"],a4dv="target",a4tt=L["d/common/un/tt"],
	-- f=function () return format('dna.GetSpellAppliedBonusDPS(%q,%s,%s,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText() ) end,
-- }
-- tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAppliedBonusDPS")', text=L["d/spell/GetSpellAppliedBonusDPS"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- dna.GetSpellCastedComboPoints=function(spell, unit)
	-- dna.D.ResetDebugTimer()
	-- local lReturn = 0
	-- local lspellID = dna.GetSpellID(spell)
	-- local lunitGUID = UnitGUID(unit)
	-- if ( lspellID and lunitGUID and dna.D.P.TS[lspellID..':'..lunitGUID] ) then
		-- lReturn =  dna.D.P.TS[lspellID..':'..lunitGUID]._casted_combo_points
	-- end
	-- dna.AppendActionDebug( 'GetSpellCastedComboPoints(spell='..tostring(spell)..',unit='..tostring(unit)..')='..tostring(lReturn) )
	-- return lReturn
-- end
-- dna.D.criteria["d/spell/GetSpellCastedComboPoints"]={
	-- a=2,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	-- f=function () return format('dna.GetSpellCastedComboPoints(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
-- }
-- tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellCastedComboPoints")', text=L["d/spell/GetSpellCastedComboPoints"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellAppliedCritPercent=function(spell, spellTreeID, unit)
	dna.D.ResetDebugTimer()
	local lReturn = 0
	local lspellID = dna.GetSpellID(spell)
	local lunitGUID = UnitGUID(unit)
	if ( lspellID and lunitGUID and spellTreeID and dna.D.P.TS[lspellID..':'..lunitGUID] ) then
		lReturn = dna.D.P.TS[lspellID..':'..lunitGUID].smcc[tostring(spellTreeID)]
	end
	dna.AppendActionDebug( 'GetSpellAppliedCritPercent(spell='..tostring(spell)..',spellTreeID='..tostring(spellTreeID)..',unit='..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellAppliedCritPercent"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/spellschool/l"],a2dv="6",a2tt=L["d/common/spellschool/tt"],
	a3l=L["d/common/un/l"],a3dv="target",a3tt=L["d/common/un/tt"],
	f=function () return format('dna.GetSpellAppliedCritPercent(%q,%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAppliedCritPercent")', text=L["d/spell/GetSpellAppliedCritPercent"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellAppliedDuration=function(spell, unit, caster)--FIX
	dna.D.ResetDebugTimer()
	local lReturn 	 	 = 0
	local ldnaSpellName = dna.GetSpellName(spell)
	local lName, _, _, lStacks, _, lDuration, lExpirationTime, lCaster, _, _, lSpellID

	for i = 1, 40 do
		lName, _, _, lStacks, _, lDuration, lExpirationTime, lCaster, _, _, lSpellID = UnitDebuff(unit, i)
		if ( lDuration == nil ) then
			lName, _, _, lStacks, _, lDuration, lExpirationTime, lCaster, _, _, lSpellID = UnitBuff(unit, i)
		end
		lDuration = dna.NilToNumeric(lDuration)
		if ( lDuration < 0 ) then lDuration = 0 end
		if ( dna.IsBlank(lName) ) then break end -- No more auras to check, break out of loop

		if ( not dna.IsBlank(caster) and not dna.IsBlank(lCaster) ) then
			if ( strlower(tostring(caster)) == strlower(lCaster) and lName == ldnaSpellName ) then
				lReturn = lDuration
				break
			end
		elseif ( dna.IsBlank(caster) and lName == ldnaSpellName ) then
			lReturn = lDuration
			break
		end
	end

	dna.AppendActionDebug( 'GetSpellAppliedDuration(spell='..tostring(spell)..',unit='..tostring(unit)..',caster='..tostring(caster)..')='..tostring(lReturn) )
	return dna.NilToNumeric(lReturn)
end
dna.D.criteria["d/spell/GetSpellAppliedDuration"]={
	a=5,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	a3l=L["d/common/casterunit/l"],a3dv="",a3tt=L["d/common/casterunit/tt"],
	a4l=L["d/common/co/l"],a4dv=">",a4tt=L["d/common/co/tt"],
	a5l=L["d/common/seconds/l"],a5dv="15",a5tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetSpellAppliedDuration(%q,%q,%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg5"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAppliedDuration")', text=L["d/spell/GetSpellAppliedDuration"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- dna.GetSpellAppliedHastePercent=function(spell, unit)
	-- dna.D.ResetDebugTimer()
	-- local lspellID = dna.GetSpellID(spell)
	-- local lunitGUID = UnitGUID(unit)
	-- local lReturn = 0
	-- if ( lspellID and lunitGUID and dna.D.P.TS[lspellID..':'..lunitGUID] ) then
		-- lReturn = dna.D.P.TS[lspellID..':'..lunitGUID].smsh or 0		--smsh=spell modifier spell haste
	-- end
	-- dna.AppendActionDebug( 'GetSpellAppliedHastePercent(spell='..tostring(spell)..',unit='..tostring(unit)..')='..tostring(lReturn) )
	-- return lReturn
-- end
-- dna.D.criteria["d/spell/GetSpellAppliedHastePercent"]={
	-- a=2,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	-- f=function () return format('dna.GetSpellAppliedHastePercent(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
-- }
-- tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAppliedHastePercent")', text=L["d/spell/GetSpellAppliedHastePercent"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- dna.GetSpellCurrentBonusDPS=function(spell, spellTreeID, baseticktime)
 	-- local lCritChance  	= GetSpellCritChance(spellTreeID) or 0
	-- local lBonusDamage 	= GetSpellBonusDamage(spellTreeID) or 0
	-- local lHaste 		= ( 1 + ( UnitSpellHaste("player") / 100 ) )
	-- local lTickTime    	= ( baseticktime / lHaste ) or 0

	--Spell power base and spell power coeffecient are not dynamic so there is no need to include them in this bonus DPS calculation
	-- if ( lTickTime > 0 ) then
		-- return ( lBonusDamage * (1 + 1 * lCritChance / 100) / lTickTime )
	-- else
		-- return 0
	-- end
-- end
-- dna.D.criteria["d/spell/GetSpellCurrentBonusDPS"]={
	-- a=3,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/spellschool/l"],a2dv="6",a2tt=L["d/common/spellschool/tt"],
	-- a3l=L["d/common/ticktime/l"],a3dv="2",a3tt=L["d/common/ticktime/tt"],
	-- f=function () return format('dna.GetSpellCurrentBonusDPS(%q,%s,%s)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
-- }
-- tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellCurrentBonusDPS")', text=L["d/spell/GetSpellCurrentBonusDPS"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellCastTime=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric( select(4, GetSpellInfo( dna.GetSpellID( spell ) ) ) ) / 1000
	if ( lReturn < 0 ) then lReturn = 0 end -- Serpent sting returned -100000000 cast time so need this protection
	dna.AppendActionDebug( 'GetSpellCastTime(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellCastTime"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetSpellCastTime(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellCastTime")', text=L["d/spell/GetSpellCastTime"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellCharges=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = dna.NilToNumeric( GetSpellCharges( dna.GetSpellID(spell) ) )
	dna.AppendActionDebug( 'GetSpellCharges(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellCharges"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv="==",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/charges/l"],a3dv="2",a3tt=L["d/common/charges/tt"],
	f=function () return format('dna.GetSpellCharges(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellCharges")', text=L["d/spell/GetSpellCharges"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellChargeFractional=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = 0
    local nRemaining = 0
    local charges, maxCharges, startTime, duration = GetSpellCharges( spell or 61304);
    if (charges == nil) then -- charges is nil if the spell has no charges
        startTime, duration = GetSpellCooldown(spell or 61304 );
    elseif (charges == maxCharges) then
        startTime, duration = 0, 0;
    end

    startTime = startTime or 0;
    duration = duration or 0;
    local time = GetTime();
--LEAK caused by any math on startTime + duration, cant figure out how to stop it
    nRemaining = startTime + duration - time;
    if nRemaining < 0 then
        nRemaining = 0
    end

	if duration > 0 then
		lReturn = ((duration-nRemaining)/duration) + charges
	else
		lReturn = charges
	end
	
	dna.AppendActionDebug( 'GetSpellChargeFractional(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellChargeFractional"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv="==",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/charges/l"],a3dv="2",a3tt=L["d/common/charges/tt"],
	f=function () return format('dna.GetSpellChargeFractional(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellChargeFractional")', text=L["d/spell/GetSpellChargeFractional"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellChargesMax=function(spell)
	dna.D.ResetDebugTimer()
	local _, lMaxCharges = GetSpellCharges( dna.GetSpellID(spell) )
	local lReturn = dna.NilToNumeric( lMaxCharges )
	dna.AppendActionDebug( 'GetSpellChargesMax(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellChargesMax"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv="==",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/charges/l"],a3dv="2",a3tt=L["d/common/charges/tt"],
	f=function () return format('dna.GetSpellChargesMax(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellChargesMax")', text=L["d/spell/GetSpellChargesMax"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellCooldown=function(spell)
	dna.D.ResetDebugTimer()
    local nRemaining = 0
    local charges, maxCharges, startTime, duration = GetSpellCharges( spell or 61304);
    if (charges == nil) then -- charges is nil if the spell has no charges
        startTime, duration = GetSpellCooldown(spell or 61304 );
    elseif (charges == maxCharges) then
        startTime, duration = 0, 0;
    end

    startTime = startTime or 0;
    duration = duration or 0;
    local time = GetTime();
--LEAK caused by any math on startTime + duration, cant figure out how to stop it
    nRemaining = startTime + duration - time;
    if nRemaining < 0 then
        nRemaining = 0
    end

	dna.AppendActionDebug( 'GetSpellCooldown(spell='..tostring(spell)..')='..tostring(nRemaining) )
	return nRemaining
end
dna.D.criteria["d/spell/GetSpellCooldown"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetSpellCooldown(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellCooldown")', text=L["d/spell/GetSpellCooldown"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellCooldownLessThanGCD=function(spell)
	dna.D.ResetDebugTimer()
    local lReturn = false

    local nEndTime = 0
    local nCharges, nMaxCharges, nStartTime, nDuration = GetSpellCharges( spell or 61304 )
    if (nCharges == nil) then -- charges is nil if the spell has no charges
        nStartTime, nDuration = GetSpellCooldown( spell or 61304 )
    elseif (nCharges == nMaxCharges) then
        nStartTime, nDuration = 0, 0
    end
	if ( nStartTime and nStartTime > 0 ) then
		nEndTime = nStartTime + nDuration
	end

    local nGCDStart, nGCDDuration = GetSpellCooldown( 61304 )
    nGCDEndTime = nGCDStart + nGCDDuration

	if nEndTime <= (nGCDEndTime + .5) then
		lReturn = true
    end
    --[[
    startTime = startTime or 0;
    duration = duration or 0;
    local time = GetTime();
--LEAK caused by any math on startTime + duration, cant figure out how to stop it
    nRemaining = startTime + duration - time;

    61304

	local SCD = dna.GetSpellCooldown(spell)

	if SCD <= (GCD+1) then
		lReturn = true
	else
		lReturn = false
	end
    --]]
	dna.AppendActionDebug( 'GetSpellCooldownLessThanGCD(spell='..tostring(spell)..'GCD='..tostring(nGCDEndTime)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellCooldownLessThanGCD"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetSpellCooldownLessThanGCD(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellCooldownLessThanGCD")', text=L["d/spell/GetSpellCooldownLessThanGCD"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellDamage=function(spell) -- Returns tooltipinitialdamagehit, tooltiptickamount, tooltipticktime, isdot
	local tooltipinitialdamagehit	= 0
	local tooltiptickamount 		= 0
	local tooltipticktime 			= 0
	local lIsDot					= false
	if ( dna.D.SpellInfo[spell] and dna.NilToNumeric(dna.D.SpellInfo[spell].tooltipinitialdamagehit,0) > 0 ) then -- check the dna spellDB first for spell damage
		tooltipinitialdamagehit = dna.D.SpellInfo[spell].tooltipinitialdamagehit or 0
		tooltiptickamount		= dna.D.SpellInfo[spell].tooltiptickamount or 0
		tooltipticktime 		= dna.D.SpellInfo[spell].tooltipticktime or 0
	else
		local lSpellID 					= dna.GetSpellID( spell )
		if ( lSpellID ) then
			local lDes = GetSpellDescription(lSpellID)
			dnaTooltip:SetOwner(UIParent, "ANCHOR_NONE")
			dnaTooltip:SetSpellByID(lSpellID)
			local lParsedLine = nil
			local lSpellFound = false
			for _ttline = 1, dnaTooltip:NumLines() do
				if ( _G["dnaTooltipTextLeft".._ttline] ) then lParsedLine = ""..(_G["dnaTooltipTextLeft".._ttline]:GetText() or ""); end
				if ( _G["dnaTooltipTextRight".._ttline] ) then lParsedLine = lParsedLine..(_G["dnaTooltipTextRight".._ttline]:GetText() or ""); end
				if ( not dna.IsBlank( lParsedLine ) ) then
-- print('GetSpellDamage lParsedLine['..lSpellID..']='..lParsedLine)
					lIsDot			= string.find( lParsedLine, 'every%s[%d%.,]+%ssec' )
					tooltipticktime	= string.match( lParsedLine, 'every%s([%d%.,]+)%ssec' )
					if ( lIsDot ) then


					else
						tooltipinitialdamagehit	= string.match( lParsedLine, 'Deal%s([%d%.,]+)%s[%w_]+%sdamage' )
					end
				end
			end

			tooltipinitialdamagehit = dna.NilToNumeric(string.gsub( tooltipinitialdamagehit or '', ',', '' ), 0)	-- remove commas and return a numeric value
			tooltiptickamount 		= dna.NilToNumeric(string.gsub( tooltiptickamount or '', ',', '' ), 0)
			tooltipticktime 		= dna.NilToNumeric(string.gsub( tooltipticktime or '', ',', '' ), 0)

-- print( "  tooltipinitialdamagehit="..tostring(tooltipinitialdamagehit) )
-- print( "  tooltiptickamount="..tostring(tooltiptickamount) )
-- print( "  tooltipticktime="..tostring(tooltipticktime) )


			dnaTooltip:Hide()
		end
	end
	return tooltipinitialdamagehit, tooltiptickamount, tooltipticktime
end
dna.D.criteria["d/spell/GetSpellDamage"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="3",a3tt=L["d/common/count/tt"],
	f=function () return format('dna.GetSpellDamage(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellDamage")', text=L["d/spell/GetSpellDamage"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellHaste=function()
	dna.D.ResetDebugTimer()
	local lReturn = (1 - (UnitSpellHaste("player") / 100) )
	dna.AppendActionDebug( 'GetSpellHaste()='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellHaste"]={
	a=0,
	f=function () return format('dna.GetSpellHaste()==true') end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellHaste")', text=L["d/spell/GetSpellHaste"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellInRangeOfUnit=function(spell, unit)
	dna.D.ResetDebugTimer()
	local lReturn = false
    local strSpellName = dna.GetSpellName(spell)
	if ( UnitExists(unit) and strSpellName ) then
		lReturn = (IsSpellInRange( strSpellName, unit)==1)
	end
	dna.AppendActionDebug( 'GetSpellInRangeOfUnit(spell='..tostring(spell)..",unit="..tostring(unit)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellInRangeOfUnit"]={
	a=2,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	f=function () return format('dna.GetSpellInRangeOfUnit(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellInRangeOfUnit")', text=L["d/spell/GetSpellInRangeOfUnit"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellIsUsable=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = false
	local lNotEnoughPower = false
	if ( spell ) then
		lReturn, lNotEnoughPower = IsUsableSpell( spell )
		if ( lNotEnoughPower ) then
			lReturn = false	--lNotEnoughPower was true
		end
	end
	dna.AppendActionDebug( 'GetSpellIsUsable(spell='..tostring(spell)..')='..tostring(lReturn)..',lNotEnoughPower='..tostring(lNotEnoughPower) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellIsUsable"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetSpellIsUsable(%q)', dna.ui["ebArg1"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellIsUsable")', text=L["d/spell/GetSpellIsUsable"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellLastCasted=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = false
    local strLastCastedSpell = dna.GetSpellName( dna.D.lastcastedspellid )
	if ( dna.GetSpellName( dna.D.lastcastedspellid ) == dna.GetSpellName( spell ) ) then
		lReturn = true
	end
	dna.AppendActionDebug( 'GetSpellLastCasted(spell='..tostring(spell)..')='..tostring(lReturn)..' lastcasted='..tostring( strLastCastedSpell ) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellLastCasted"]={
	a=1,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	f=function () return format('dna.GetSpellLastCasted(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellLastCasted")', text=L["d/spell/GetSpellLastCasted"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellLastCastedElapsed=function(spell)
	dna.D.ResetDebugTimer()
	local lReturn = 999999
	local sSpellID = dna.GetSpellID(spell)
	if ( sSpellID and dna.D.SpellInfo[sSpellID] and dna.D.SpellInfo[sSpellID].lastcastedtime ) then
		lReturn = ( GetTime()-dna.D.SpellInfo[sSpellID].lastcastedtime )
	end
	dna.AppendActionDebug( 'GetSpellLastCastedElapsed(spell='..tostring(spell)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/spell/GetSpellLastCastedElapsed"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetSpellLastCastedElapsed(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellLastCastedElapsed")', text=L["d/spell/GetSpellLastCastedElapsed"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellRechargeTimeRemaining=function( spell )
	local _,_,cdStart, cdDuration = GetSpellCharges( dna.GetSpellID(spell) )
	if ( cdStart and cdDuration and cdStart<GetTime() ) then
		local lEndTime = cdStart + cdDuration
		return ( lEndTime - GetTime() )
	else
		return 0
	end
end
dna.D.criteria["d/spell/GetSpellRechargeTimeRemaining"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	f=function () return format('dna.GetSpellRechargeTimeRemaining(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellRechargeTimeRemaining")', text=L["d/spell/GetSpellRechargeTimeRemaining"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellAddTicksOnUnit=function(spell, unit, baseduration, baseticktime)
	local lspellID = dna.GetSpellID(spell)
	local lunitGUID = UnitGUID(unit)
	if ( not baseticktime ) then if ( dna.D.SpellInfo[spell] and dna.D.SpellInfo[spell].baseticktime ) then baseticktime = dna.D.SpellInfo[spell].baseticktime; else baseticktime = 2; end end
	if ( lspellID and lunitGUID and dna.D.P.TS[lspellID..':'..lunitGUID] and dna.D.P.TS[lspellID..':'..lunitGUID].smsh ) then
		local lHaste = (1 + dna.D.P.TS[lspellID..':'..lunitGUID].smsh )
-- print(" baseduration="..baseduration)
-- print(" baseticktime="..baseticktime)
-- print(" dna.D.P.TS[lspellID..':'..lunitGUID].smsh="..dna.D.P.TS[lspellID..':'..lunitGUID].smsh)
-- print(" lHaste="..lHaste)
		return math.ceil( baseduration / ( baseticktime / lHaste ) )
	else
		return 0
	end
end
dna.D.criteria["d/spell/GetSpellAddTicksOnUnit"]={
	a=4,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/un/l"],a2dv="target",a2tt=L["d/common/un/tt"],
	a3l=L["d/common/baseduration/l"],a3dv="90",a3tt=L["d/common/baseduration/tt"],
	a4l=L["d/common/ticktime/l"],a4dv="15",a4tt=L["d/common/ticktime/tt"],
	f=function () return format('dna.GetSpellAddTicksOnUnit(%q,%q,%s,%s)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/GetSpellAddTicksOnUnit")', text=L["d/spell/GetSpellAddTicksOnUnit"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.SetSpellInfo=function( numSpellId, attribute, value)

	--local sSpellID = dna.LibSimcraftParser.SetSpellInfo(dna.D.SpellInfo, nil, numSpellId)
    local strSpellId = tostring(numSpellId)

	if ( dna.D.SpellInfo[strSpellId] ) then
		dna.D.SpellInfo[strSpellId][attribute] = value
	else
        dna.D.SpellInfo[strSpellId] = {}
        dna.D.SpellInfo[strSpellId][attribute] = value
	end
    

    -- Always return true so this function can be used in criteria
	return true
end
dna.D.criteria["d/spell/SetSpellInfo"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/attribute/l"],a2dv='',a2tt=L["d/common/attribute/tt"],
	a3l=L["d/common/value/l"],a3dv='',a3tt=L["d/common/value/tt"],
	f=function () return format('dna.SetSpellInfo(%q,%q,%s)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[SPELL_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/spell/SetSpellInfo")', text=L["d/spell/SetSpellInfo"] } )

--********************************************************************************************
--CLASS CRITERIA
--********************************************************************************************
dna.D.InitCriteriaClassTree=function()
	dna.D.class = {}
	--COMMON CLASS CRITERIA--------------------------------------------------------------------------------------------------
		dna.GetWeaponEnchant=function(slot, spell)
			spell = dna.GetSpellName( spell )
			local hasMainHandEnchant, _, _, hasOffHandEnchant, _, _, hasThrownEnchant, _, _ = GetWeaponEnchantInfo()
			if ( slot and strlower(slot) == 'mainhand' ) then
				slot = 16
				if ( not hasMainHandEnchant) then return false end
			elseif ( slot and strlower(slot) == 'offhand' ) then
				slot = 17
				if ( not hasOffHandEnchant) then return false end
			elseif ( slot and strlower(slot) == 'thrown' ) then
				slot = 18
				if ( not hasThrownEnchant) then return false end
			end
			dnaTooltip:SetOwner(UIParent, "ANCHOR_NONE")
			dnaTooltip:SetInventoryItem("player", slot)
			local _parsedline = nil
			local lSpellFound = false
			for _ttline = 1, dnaTooltip:NumLines() do
				if ( _G["dnaTooltipTextLeft".._ttline] ) then _parsedline = ""..(_G["dnaTooltipTextLeft".._ttline]:GetText() or ""); end
				if ( _G["dnaTooltipTextRight".._ttline] ) then _parsedline = _parsedline..(_G["dnaTooltipTextRight".._ttline]:GetText() or ""); end
				if ( not dna.IsBlank( _parsedline ) and strfind(_parsedline, spell) ) then lSpellFound = true; break end
			end
			dnaTooltip:Hide()
			return lSpellFound
		end
		dna.D.criteria["d/class/common/GetEnergy"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv="<",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/energy/l"],a2dv="5",a2tt=L["d/common/energy/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_ENERGY)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		dna.D.criteria["d/class/common/GetEnergyTimeToMax"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv="<",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/seconds/l"],a2dv="5",a2tt=L["d/common/seconds/tt"],
			f=function () return format('dna.D.P["SPELL_POWER_ENERGY"].ttm%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		dna.D.criteria["d/class/common/GetEnergyRegenRate"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">=",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/count/l"],a2dv="15",a2tt=L["d/common/count/tt"],
			f=function () return format('dna.D.P["SPELL_POWER_ENERGY"].pgr%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		dna.D.criteria["d/class/common/GetWeaponEnchant"]={--Get weapon enchant
			a=2,
			a1l=L["d/common/ws/l"],a1dv="mainhand",a1tt=L["d/common/ws/tt"],
			a2l=L["d/common/sp/l"],a2dv=32910,a2tt=L["d/common/sp/tt"],
			f=function () return format('dna.GetWeaponEnchant(%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
	if (dna.D.PClass == "DEATHKNIGHT") then---------------------------------------------------------------------------------
		if ( not dna.D.class.dk ) then dna.D.class.dk = {} end
		--------------------------------------------------------------------------------------
		dna.GetDeathStrikeHealPercent=function()
			dna.D.ResetDebugTimer()
			local lAmount = 7 * (1 + .2 * dna.GetUnitHasBuffNameStacks("player", 50421) )
			dna.AppendActionDebug( 'GetDeathStrikeHealPercent()='..tostring(lAmount) )
			return lAmount
		end
		dna.D.criteria["d/class/deathknight/GetDeathStrikeHealPercent"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/count/l"],a2dv="0",a2tt=L["d/common/count/tt"],
			f=function () return format('dna.GetDeathStrikeHealPercent()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/deathknight/GetDeathStrikeHealPercent")', text=L["d/class/deathknight/GetDeathStrikeHealPercent"] } )
		--------------------------------------------------------------------------------------
		dna.GetGhoulExists=function()
			dna.D.ResetDebugTimer()
			local haveGhoul, name, startTime, duration, icon = GetTotemInfo(1)
			dna.AppendActionDebug( 'GetGhoulExists()='..tostring(haveGhoul) )
			return haveGhoul
		end
		dna.D.criteria["d/class/deathknight/GetGhoulExists"]={
			a=0,
			f=function () return 'dna.GetGhoulExists()' end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/deathknight/GetGhoulExists")', text=L["d/class/deathknight/GetGhoulExists"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/deathknight/GetRunicPower"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv="<=",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/deathknight/rp"],a2dv="76",a2tt=L["d/class/deathknight/rptt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_RUNIC_POWER)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/deathknight/GetRunicPower")', text=L["d/class/deathknight/GetRunicPower"] } )
		--------------------------------------------------------------------------------------
		dna.GetTotalRuneCount=function()
            dna.D.ResetDebugTimer()
			local lTotal = 0
			for i = 1, 6 do
				local _,_, runeReady = GetRuneCooldown(i)
				if ( runeReady ) then
					lTotal  = lTotal + 1
				end
			end
            dna.AppendActionDebug( 'GetTotalRuneCount()='..tostring(lTotal) )
			return lTotal
		end
		dna.D.criteria["d/class/deathknight/GetTotalRuneCount"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">=",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/deathknight/dr"],a2dv="1",a2tt=L["d/class/deathknight/drtt"],
			f=function () return format('dna.GetTotalRuneCount()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/deathknight/GetTotalRuneCount")', text=L["d/class/deathknight/GetTotalRuneCount"] } )
		--------------------------------------------------------------------------------------
		dna.GetTotalDepletedRunes=function()
			dna.D.ResetDebugTimer()
			local lReturn = 0
			local _,_,rune1Ready = GetRuneCooldown(1)
			local _,_,rune2Ready = GetRuneCooldown(2)

			if ( not rune1Ready and not rune2Ready ) then lReturn = lReturn + 1 end
			_,_,rune1Ready = GetRuneCooldown(3)
			_,_,rune2Ready = GetRuneCooldown(4)
			if ( not rune1Ready and not rune2Ready ) then lReturn = lReturn + 1 end
			_,_,rune1Ready = GetRuneCooldown(5)
			_,_,rune2Ready = GetRuneCooldown(6)
			if ( not rune1Ready and not rune2Ready ) then lReturn = lReturn + 1 end

			dna.AppendActionDebug( 'GetTotalDepletedRunes()='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/deathknight/GetTotalDepletedRunes"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">=",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/deathknight/depleated"],a2dv="1",a2tt=L["d/class/deathknight/depleatedtt"],
			f=function () return format('dna.GetTotalDepletedRunes()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/deathknight/GetTotalDepletedRunes")', text=L["d/class/deathknight/GetTotalDepletedRunes"] } )
    ----------------------------------------------------
    -- DRUID
    ----------------------------------------------------
	elseif (dna.D.PClass == "DRUID") then
		if ( not dna.D.class.druid ) then dna.D.class.druid = {} end
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetComboPoints")', text=L["d/class/common/GetComboPoints"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergy")', text=L["d/class/common/GetEnergy"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergyRegenRate")', text=L["d/class/common/GetEnergyRegenRate"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergyTimeToMax")', text=L["d/class/common/GetEnergyTimeToMax"] } )
		--------------------------------------------------------------------------------------

    ----------------------------------------------------
    -- HUNTER
    ----------------------------------------------------
	elseif (dna.D.PClass == "HUNTER") then
		dna.D.criteria["d/class/hunter/GetFocus"]={--Focus
			a=2,
			a1l=L["d/common/co/l"],a1dv="<",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/focus/l"],a2dv="50",a2tt=L["d/common/focus/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_FOCUS)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/hunter/GetFocus")', text=L["d/class/hunter/GetFocus"] } )
		--------------------------------------------------------------------------------------
		dna.GetFocusDeficit=function(direction)
			dna.D.ResetDebugTimer()
			local lReturn = (UnitPowerMax("player",SPELL_POWER_FOCUS) - UnitPower("player",SPELL_POWER_FOCUS))
			dna.AppendActionDebug( 'GetFocusDeficit()='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/hunter/GetFocusDeficit"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">=",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/focus/l"],a2dv="30",a2tt=L["d/common/focus/tt"],
			f=function () return format('dna.GetFocusDeficit()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/hunter/GetFocusDeficit")', text=L["d/class/hunter/GetFocusDeficit"] } )
	elseif (dna.D.PClass == "MAGE") then---------------------------------------------------------------------------------

	elseif (dna.D.PClass == "MONK") then---------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergy")', text=L["d/class/common/GetEnergy"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergyTimeToMax")', text=L["d/class/common/GetEnergyTimeToMax"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/monk/GetChi"]={--Chi
			a=2,
			a1l=L["d/common/co/l"],a1dv="<",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/monk/GetChi/l"],a2dv="3",a2tt=L["d/class/monk/GetChi/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_CHI)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/monk/GetChi")', text=L["d/class/monk/GetChi"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/monk/GetStaggerPercent"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/monk/staggerpercent/l"],a2dv=L["d/class/monk/staggerpercent/dv"],a2tt=L["d/class/monk/staggerpercent/tt"],
			f=function () return format('dna.D.P["STAGGER"].percent%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/monk/GetStaggerPercent")', text=L["d/class/monk/GetStaggerPercent"] } )
		dna.D.criteria["d/class/monk/GetStaggerTotal"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/monk/stagger/l"],a2dv=L["d/class/monk/stagger/dv"],a2tt=L["d/class/monk/stagger/tt"],
			f=function () return format('dna.D.P["STAGGER"].total%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/monk/GetStaggerTotal")', text=L["d/class/monk/GetStaggerTotal"] } )
	elseif (dna.D.PClass == "PALADIN") then---------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------
		dna.GetTimeToGainHolyPower=function()
			dna.D.ResetDebugTimer()
			local lShortestTime = dna.GetSpellCooldown(35395)
			local lSpecialization = GetSpecialization()
			if ( dna.GetSpellCooldown(20271) < lShortestTime ) then --judgement
				lShortestTime = dna.GetSpellCooldown(20271)
			end

			if ( lSpecialization == 2 ) then --protection
				if ( dna.GetTalentEnabled(171648) and dna.GetSpellCooldown(119072) < lShortestTime ) then --sanctified wrath, holy wrath
					lShortestTime = dna.GetSpellCooldown(119072)
				end
			elseif (lSpecialization == 3 ) then --retribution
				if ( dna.GetSpellCooldown(122032) < lShortestTime ) then --exorcism
					lShortestTime = dna.GetSpellCooldown(119072)
				end
				if ( dna.GetSpellCooldownLessThanGCD(24275) and dna.GetSpellIsUsable(24275) and dna.GetSpellCooldown(24275) < lShortestTime ) then --hammer of wrath
					lShortestTime = dna.GetSpellCooldown(24275)
				end
			elseif (lSpecialization == 1 ) then --holy
				if ( dna.GetSpellCooldown(20473) < lShortestTime ) then --holy shock
					lShortestTime = dna.GetSpellCooldown(20473)
				end
			end

			if ( dna.GetPlayerGCD() > lShortestTime ) then
				lShortestTime = dna.GetPlayerGCD()
			end

			dna.AppendActionDebug( 'GetTimeToGainHolyPower()='..tostring(lShortestTime) )
			return lShortestTime
		end
		dna.D.criteria["d/class/paladin/GetTimeToGainHolyPower"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv="<=",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/seconds/l"],a2dv="2",a2tt=L["d/common/seconds/tt"],
			f=function () return format('dna.GetTimeToGainHolyPower()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/paladin/GetTimeToGainHolyPower")', text=L["d/class/paladin/GetTimeToGainHolyPower"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/paladin/GetHolyPower"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv="==",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/count/l"],a2dv="3",a2tt=L["d/common/count/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_HOLY_POWER)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/paladin/GetHolyPower")', text=L["d/class/paladin/GetHolyPower"] } )
	elseif (dna.D.PClass == "PRIEST") then---------------------------------------------------------------------------------
		dna.D.criteria["d/class/priest/GetShadowOrbs"]={--Shadow Orbs
			a=2,
			a1l=L["d/common/co/l"],a1dv="==",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/count/l"],a2dv="3",a2tt=L["d/common/count/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_SHADOW_ORBS)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/priest/GetShadowOrbs")', text=L["d/class/priest/GetShadowOrbs"] } )
	elseif (dna.D.PClass == "ROGUE") then---------------------------------------------------------------------------------
		dna.GetComboPoints=function()
			dna.D.ResetDebugTimer()
			local comboPoints = UnitPower('player', 4);
			local lReturn = dna.NilToNumeric(comboPoints)
			
			dna.AppendActionDebug( 'GetComboPoints()='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/rogue/GetComboPoints"]={--Combo points
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/combopoints/l"],a2dv="4",a2tt=L["d/common/combopoints/tt"],
			f=function () return format('dna.GetComboPoints()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/rogue/GetComboPoints")', text=L["d/class/rogue/GetComboPoints"] } )
		--------------------------------------------------------------------------------------
		dna.GetComboPointDeficit=function()
			dna.D.ResetDebugTimer()
			
			local comboPoints = UnitPower('player', 4);
			local comboPointsMax = UnitPowerMax('player', 4);
			local comboPointsDeficit = comboPointsMax - comboPoints;
			local lReturn = dna.NilToNumeric(comboPointsDeficit)
			
			dna.AppendActionDebug( 'GetComboPointDeficit()='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/rogue/GetComboPointDeficit"]={--Combo points
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/combopoints/l"],a2dv="4",a2tt=L["d/common/combopoints/tt"],
			f=function () return format('dna.GetComboPointDeficit()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/rogue/GetComboPointDeficit")', text=L["d/class/rogue/GetComboPointDeficit"] } )
		--------------------------------------------------------------------------------------

		
		
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergy")', text=L["d/class/common/GetEnergy"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetEnergyTimeToMax")', text=L["d/class/common/GetEnergyTimeToMax"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetWeaponEnchant")', text=L["d/class/common/GetWeaponEnchant"] } )
	elseif (dna.D.PClass == "SHAMAN") then---------------------------------------------------------------------------------
		if ( not dna.D.class.shaman ) then dna.D.class.shaman = {} end
		dna.D.class.shaman.totem_data = {}--totem data
		dna.D.class.shaman.totem_data[1] = {}--Fire
		dna.D.class.shaman.totem_data[2] = {}--Earth
		dna.D.class.shaman.totem_data[3] = {}--Water
		dna.D.class.shaman.totem_data[4] = {}--Air
		--------------------------------------------------------------------------------------
		dna.GetTotemSlotActive=function(slot)
			dna.D.ResetDebugTimer()
			local lReturn = GetTotemInfo(slot)
			dna.AppendActionDebug( 'GetTotemSlotActive(slot='..tostring(slot)..')='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/shaman/GetTotemSlotActive"]={
			a=1,
			a1l=L["d/class/shaman/totemslot/l"],a1dv='1',a1tt=L["d/class/shaman/totemslot/tt"],
			f=function () return format('dna.GetTotemSlotActive(%s)', dna.ui["ebArg1"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/shaman/GetTotemSlotActive")', text=L["d/class/shaman/GetTotemSlotActive"] } )
		--------------------------------------------------------------------------------------
		dna.GetTotemSpellActive=function(spell)
			dna.D.ResetDebugTimer()
			local lReturn = false
			local lSpell = dna.GetSpellName(spell);
			for i = 1, 4 do
				local _,totemName,_,_ = GetTotemInfo(i);
				if ( totemName and lSpell and totemName == lSpell ) then lReturn = true end
			end
			dna.AppendActionDebug( 'GetTotemSpellActive(spell='..tostring(lSpell)..')='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/shaman/GetTotemSpellActive"]={--Get totem spell active
			a=1,
			a1l=L["d/class/shaman/totemspell/l"],a1dv='',a1tt=L["d/class/shaman/totemspell/tt"],
			f=function () return format('dna.GetTotemSpellActive(%q)', dna.ui["ebArg1"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/shaman/GetTotemSpellActive")', text=L["d/class/shaman/GetTotemSpellActive"] } )
		--------------------------------------------------------------------------------------
		dna.GetTotemSlotTimeLeft=function(slot)
			dna.D.ResetDebugTimer()
			local lReturn = 0
			local haveTotem, totemName, startTime, duration = GetTotemInfo(slot)
			if ( haveTotem ) then
				lReturn = ((startTime + duration) - GetTime())
			end
			dna.AppendActionDebug( 'GetTotemSlotTimeLeft(slot='..tostring(slot)..')='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/shaman/GetTotemSlotTimeLeft"]={--Get totem time left
			a=3,
			a1l=L["d/class/shaman/totemslot/l"],a1dv="1",a1tt=L["d/class/shaman/totemslot/tt"],
			a2l=L["d/common/co/l"],a2dv="<=",a2tt=L["d/common/co/tt"],
			a3l=L["d/common/seconds/l"],a3dv="2",a3tt=L["d/common/seconds/tt"],
			f=function () return format('dna.GetTotemSlotTimeLeft(%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/shaman/GetTotemSlotTimeLeft")', text=L["d/class/shaman/GetTotemSlotTimeLeft"] } )
		--------------------------------------------------------------------------------------
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/common/GetWeaponEnchant")', text=L["d/class/common/GetWeaponEnchant"] } )
	elseif (dna.D.PClass == "WARLOCK") then---------------------------------------------------------------------------------
		dna.D.criteria["d/class/warlock/GetBurningEmbers"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/warlock/burningembers/l"],a2dv='2',a2tt=L["d/class/warlock/burningembers/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_BURNING_EMBERS)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/warlock/GetBurningEmbers")', text=L["d/class/warlock/GetBurningEmbers"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/warlock/GetBurningEmbersSegs"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/warlock/burningemberss/l"],a2dv='2',a2tt=L["d/class/warlock/burningemberss/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_BURNING_EMBERS, true)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/warlock/GetBurningEmbersSegs")', text=L["d/class/warlock/GetBurningEmbersSegs"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/warlock/GetDemonicFury"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/warlock/df/l"],a2dv='2',a2tt=L["d/class/warlock/df/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_DEMONIC_FURY)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/warlock/GetDemonicFury")', text=L["d/class/warlock/GetDemonicFury"] } )
		--------------------------------------------------------------------------------------
		dna.GetSecondsInMetamorphosis=function()
			dna.D.ResetDebugTimer()
			local lReturn = 0
			if ( dna.D.P["METAMORPHOSIS"].appliedtimestamp > 0 ) then
				lReturn = (GetTime() - dna.D.P["METAMORPHOSIS"].appliedtimestamp)
			end
			dna.AppendActionDebug( 'GetSecondsInMetamorphosis()='..tostring(lReturn) )
			return lReturn
		end
		dna.D.criteria["d/class/warlock/GetSecondsInMetamorphosis"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/common/seconds/l"],a2dv="3",a2tt=L["d/common/seconds/tt"],
			f=function () return format('dna.GetSecondsInMetamorphosis()%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/warlock/GetSecondsInMetamorphosis")', text=L["d/class/warlock/GetSecondsInMetamorphosis"] } )
		--------------------------------------------------------------------------------------
		dna.D.criteria["d/class/warlock/GetSoulShards"]={
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/warlock/soulshards/l"],a2dv='2',a2tt=L["d/class/warlock/soulshards/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_SOUL_SHARDS)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/warlock/GetSoulShards")', text=L["d/class/warlock/GetSoulShards"] } )
	elseif (dna.D.PClass == "WARRIOR") then---------------------------------------------------------------------------------
		dna.D.criteria["d/class/warrior/GetRage"]={--Rage
			a=2,
			a1l=L["d/common/co/l"],a1dv=">",a1tt=L["d/common/co/tt"],
			a2l=L["d/class/warrior/rage/l"],a2dv="110",a2tt=L["d/class/warrior/rage/tt"],
			f=function () return format('dna.GetUnitPower("player",SPELL_POWER_RAGE)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText()) end,
		}
		tinsert( dna.D.criteriatree[CLASS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/class/warrior/GetRage")', text=L["d/class/warrior/GetRage"] } )
	end
end

--********************************************************************************************
--TALENTS CRITERIA
--********************************************************************************************
dna.GetTalentEnabled=function(talent)
	dna.D.ResetDebugTimer()
	lReturn = false

	local lSpellName = GetSpellInfo(talent)
	local lCurrentSpecGroup = GetActiveSpecGroup()
	if ( lSpellName and lCurrentSpecGroup ) then
		for lTier = 1, MAX_TALENT_TIERS do
			for lColumn = 1, 3 do
				talentID, name, iconTexture, selected, available = GetTalentInfo(lTier, lColumn, lCurrentSpecGroup )
				if (name == lSpellName and selected) then
					lReturn = true
					break
				end
			end
		end
	end
	dna.AppendActionDebug( 'GetTalentEnabled(talent='..tostring(talent)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/talents/GetTalentEnabled"]={
	a=1,
	a1l=L["d/common/ta"],a1dv=L["d/common/tadv"],a1tt=L["d/common/tatt"],
	f=function () return format('dna.GetTalentEnabled(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[TALENTS_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/talents/GetTalentEnabled")', text=L["d/talents/GetTalentEnabled"] } )
--********************************************************************************************
--MISC CRITERIA
--********************************************************************************************
dna.GetActionCriteriaState=function(actionName)
	dna.D.ResetDebugTimer()
	local lReturn = false

	local actionFrame = dna.GetActionTable(actionName)
	if ( actionFrame and actionFrame._nemo_criteria_passed == true ) then
		lReturn = true
	end

	dna.AppendActionDebug( 'GetActionCriteriaState(action='..tostring(actionName)..')='..tostring(lReturn) )
	return lReturn
end
dna.D.criteria["d/misc/GetActionCriteriaState"]={
	a=1,
	a1l=L["d/misc/an/l"],a1dv='',a1tt=L["d/misc/an/tt"],
	f=function () return format('dna.GetActionCriteriaState(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[MISC_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/misc/GetActionCriteriaState")', text=L["d/misc/GetActionCriteriaState"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetActionDisabled=function(action)
	if ( dna.D.OTM[dna.D.PClass].selectedrotationkey and not dna.IsBlank(action) ) then
		local lAKey = dna:SearchTable(dna.D.RTMC[dna.D.OTM[dna.D.PClass].selectedrotationkey].children, "text", action)
		if ( lAKey and dna.D.RTMC[dna.D.OTM[dna.D.PClass].selectedrotationkey].children[lAKey].dis == true ) then
			return true
		end
	end
	return false
end
dna.D.criteria["d/misc/GetActionDisabled"]={
	a=1,
	a1l=L["d/misc/an/l"],a1dv='',a1tt=L["d/misc/an/tt"],
	f=function () return format('dna.GetActionDisabled(%q)', dna.ui["ebArg1"]:GetText()) end,
}
tinsert( dna.D.criteriatree[MISC_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/misc/GetActionDisabled")', text=L["d/misc/GetActionDisabled"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetToggleEnabled=function( nToggleNumber, nXOffset, nYOffset, nSize, strSpell, strSpellWatch )
	dna.D.ResetDebugTimer()
	local bReturn = false

	if (not dna.IsBlank(strSpell)) then
		local name, rank, strIcon, castingTime, minRange, maxRange, spellID = GetSpellInfo(strSpell)

		if not dna.frmToggle then dna.frmToggle = {} end
		if not dna.txtToggle then dna.txtToggle = {} end

		if not dna.frmToggle[nToggleNumber] and nXOffset ~= nil then
			dna.frmToggle[nToggleNumber] = CreateFrame("Frame","frmToggle["..tostring(nToggleNumber).."]",UIParent);
			dna.frmToggle[nToggleNumber]:ClearAllPoints();
			dna.frmToggle[nToggleNumber]:SetFrameStrata("TOOLTIP")
			dna.frmToggle[nToggleNumber]:SetToplevel(true)
			dna.frmToggle[nToggleNumber]:SetFrameLevel(128)
			dna.frmToggle[nToggleNumber]:EnableMouse(false)
			dna.frmToggle[nToggleNumber]:Show()
			dna.frmToggle[nToggleNumber]:SetAlpha(1)
		end

		dna.frmToggle[nToggleNumber]:SetPoint("CENTER", UIParent, "CENTER", nXOffset, nYOffset)
		dna.frmToggle[nToggleNumber]:SetWidth(nSize);
		dna.frmToggle[nToggleNumber]:SetHeight(nSize);

		if not dna.txtToggle[nToggleNumber] then
			dna.txtToggle[nToggleNumber] = dna.frmToggle[nToggleNumber]:CreateTexture('dna.txtToggle['..tostring(nToggleNumber)..']', 'OVERLAY')
			dna.txtToggle[nToggleNumber]:ClearAllPoints()
			dna.txtToggle[nToggleNumber]:SetAllPoints(dna.frmToggle[nToggleNumber])
		end

		if strIcon then
			dna.txtToggle[nToggleNumber]:SetTexture( strIcon )
		end

		if ( dna.bToggle[nToggleNumber] == true ) then
			dna.txtToggle[nToggleNumber]:SetAlpha(1)
			bReturn = true
		else
			dna.txtToggle[nToggleNumber]:SetAlpha(0)
		end

		dna.AppendActionDebug( 'GetToggleEnabled(nToggleNumber='..tostring(nToggleNumber)..
								',nXOffset='..tostring(nXOffset)..
								',nYOffset='..tostring(nYOffset)..
								',nSize='..tostring(nSize)..
								',strSpell='..tostring(strSpell)..
								',strSpellWatch='..tostring(strSpellWatch)..
								')='..tostring(bReturn) )
		-- dna:dprint( "strSpellWatch="..tostring(strSpellWatch))
		if not dna.IsBlank( strSpellWatch ) then
			local nSpellWatchCD = dna.GetSpellCooldown(strSpellWatch)
			local _, nSpellWatchDuration = GetSpellCooldown(strSpellWatch or 61304 )
			
			local nTimeInCD = ( nSpellWatchDuration - nSpellWatchCD )
			-- You have to wait 2 seconds before turning a toggle back on
			if nTimeInCD < 2 and nSpellWatchCD > 2 then
				dna.bToggle[nToggleNumber] = false
				dna.txtToggle[nToggleNumber]:SetAlpha(0)
			end
		end

	else
		if ( dna.bToggle[nToggleNumber] == true ) then
			bReturn = true
		end
		dna.AppendActionDebug( 'GetToggleEnabled(nToggleNumber='..tostring(nToggleNumber)..')='..tostring(bReturn) )
	end

	return bReturn
end
dna.D.criteria["d/misc/GetToggleEnabled"]={
	a=6,
	a1l=L["d/common/togglenumber/l"],a1dv="1",a1tt=L["d/common/togglenumber/tt"],
	a2l=L["d/common/xoffset/l"],a2dv="-64",a2tt=L["d/common/xoffset/tt"],
	a3l=L["d/common/yoffset/l"],a3dv="0",a3tt=L["d/common/yoffset/tt"],
	a4l=L["d/common/iconsize/l"],a4dv="32",a4tt=L["d/common/iconsize/tt"],
	a5l=L["d/common/sp/l"],a5dv=L["d/common/sp/dv"],a5tt=L["d/common/sp/tt"],
	a6l=L["d/common/spcdwatch/l"],a6dv=L["d/common/spcdwatch/dv"],a6tt=L["d/common/spcdwatch/tt"],
	f=function () return format('dna.GetToggleEnabled(%s,%s,%s,%s,%q,%q)',
		dna.ui["ebArg1"]:GetText(),
		dna.ui["ebArg2"]:GetText(),
		dna.ui["ebArg3"]:GetText(),
		dna.ui["ebArg4"]:GetText(),
		dna.ui["ebArg5"]:GetText(),
		dna.ui["ebArg6"]:GetText()
		)
	end,
}
tinsert( dna.D.criteriatree[MISC_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/misc/GetToggleEnabled")', text=L["d/misc/GetToggleEnabled"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
function dna.SetActionValue(_, dnaActionFrame, ValueName, Value )
	if ( dnaActionFrame and ValueName) then
		dnaActionFrame[ValueName] = Value
	end
	return true
end
dna.D.criteria["d/misc/SetActionValue"]={
	a=2,
	a1l=L["d/common/valuename/l"],a1dv="_spellid",a1tt=L["d/common/valuename/tt"],
	a2l=L["d/common/value/l"],a2dv="5",a2tt=L["d/common/value/tt"],
	-- This function call has to be with a colon to pass self parameter
	f=function () return format('dna:SetActionValue(select(1,...),%q,%q)', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[MISC_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/misc/SetActionValue")', text=L["d/misc/SetActionValue"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
function dna.SetWeakAuraInfo(_,dnaActionFrame,keyBind,spellName)
	dna.D.ResetDebugTimer()

	if ( dnaActionFrame ) then
		dnaActionFrame["_spellid"] = spellName
	end
	
	if string.len(keyBind) == 1 then
		dna.CurrentActionKeyBind = keyBind
	end

	dna.AppendActionDebug( 'SetWeakAuraInfo(keyBind='..tostring(keyBind)..',spellName='..tostring(spellName)..')=true')

	return true
end
dna.D.criteria["d/misc/SetWeakAuraInfo"]={
	a=2,
	a1l=L["d/misc/keybind/l"],a1dv=L["d/misc/keybind/dv"],a1tt=L["d/misc/keybind/tt"],
	a2l=L["common/spellname/l"],a2dv=L["common/spellname/dv"],a2tt=L["common/spellname/tt"],
	f=function () return format('dna:SetWeakAuraInfo(select(1,...),%q,%q)'.."\n", dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[MISC_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/misc/SetWeakAuraInfo")', text=L["d/misc/SetWeakAuraInfo"] } )

--********************************************************************************************
--GROUP CRITERIA
--********************************************************************************************
dna.GetHealableLowestHealthPercent=function(spell)
	local group, num
	local unitID
	local lLowestHealthPercent = 100
	local lLowestUnitID = "player"
	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	else
		return dna.GetUnitHealthPercent("player"), "player"
	end
	for i = 1, num do
		unitID = group..i;
		local lUnitHealthPercent = dna.GetUnitHealthPercent(unitID)
		if ( lUnitHealthPercent < lLowestHealthPercent and dna.GetSpellInRangeOfUnit(spell,unitID) ) then
			lLowestHealthPercent = lUnitHealthPercent
			lLowestUnitID = unitID
		end
	end
	return lLowestHealthPercent, lLowestUnitID
end
dna.D.criteria["d/group/GetHealableLowestHealthPercent"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv="<",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/pe/l"],a3dv="60",a3tt=L["d/common/pe/tt"],
	f=function () return format('dna.GetHealableLowestHealthPercent(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetHealableLowestHealthPercent")', text=L["d/group/GetHealableLowestHealthPercent"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetNumberOfGroupMembersWithCurableDebuffType=function(dtype)
	local group, num
	local numberofgroupmembers = 0
	local unitID
	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	elseif ( dna.GetUnitHasCurableDebuffType("player", dtype) ) then
		return 1
	end
	if ( group ) then
		for i = 1, num do
			unitID = group..i;
			if ( dna.GetUnitHasCurableDebuffType(unitID, dtype) ) then
				numberofgroupmembers = numberofgroupmembers + 1
			end
		end
	end
	return numberofgroupmembers
end
dna.D.criteria["d/group/GetNumberOfGroupMembersWithCurableDebuffType"]={
	a=3,
	a1l=L["d/common/debufftype/l"],a1dv=L["d/common/debufftype/dv"],a1tt=L["d/common/debufftype/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="3",a3tt=L["d/common/count/tt"],
	f=function () return format('dna.GetNumberOfGroupMembersWithCurableDebuffType(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetNumberOfGroupMembersWithCurableDebuffType")', text=L["d/group/GetNumberOfGroupMembersWithCurableDebuffType"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetNumHurtPlayers=function( minpercent, distIndex )
	dna.D.ResetDebugTimer()
	local lHurtCount = 0
	local group, num
	local unitID

	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	elseif ( (100 - dna.GetUnitHealthPercent("player")) > 0 ) then
		return 1
	end
	if ( group ) then
		for i = 1, num do
			unitID = group..i;
			local lUHealthPercentLost = 100 - dna.GetUnitHealthPercent(unitID)
			local bInRange = CheckInteractDistance(unitID, distIndex)
			if ( bInRange and minpercent and minpercent >= 0 and lUHealthPercentLost > minpercent ) then
				lHurtCount = lHurtCount + 1
			end
		end
	end
    dna.AppendActionDebug( 'GetNumHurtPlayers(minpercent='..tostring(minpercent)..',distIndex='..tostring(distIndex)..')='..tostring(lHurtCount) )
	return lHurtCount
end
dna.D.criteria["d/group/GetNumHurtPlayers"]={
	a=4,
	a1l=L["d/common/pe/l"],a1dv="10",a1tt=L["d/common/pe/tt"],
	a2l=L["d/common/di/l"],a2dv="3",a2tt=L["d/common/di/tt"],
	a3l=L["d/common/co/l"],a3dv=">",a3tt=L["d/common/co/tt"],
	a4l=L["d/common/count/l"],a4dv="5",a4tt=L["d/common/count/tt"],
	f=function () return format('dna.GetNumHurtPlayers(%s,%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText(), dna.ui["ebArg4"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetNumHurtPlayers")', text=L["d/group/GetNumHurtPlayers"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetTotalHealthLoss=function( maxlossperunit )
	local group, num
	local unitID
	local lTotalHealthLost = 0

	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	else
		return dna.GetUnitHealthLost("player")
	end
	if ( group ) then
		for i = 1, num do
			unitID = group..i;
			local lUHealthLost = dna.GetUnitHealthLost(unitID)
			if ( maxlossperunit and maxlossperunit > 0 and lUHealthLost > maxlossperunit ) then lUHealthLost = maxlossperunit end -- Cap the total health loss so you do not go over what you are capable of healing
			if ( lUHealthLost > 0 ) then
				lTotalHealthLost = lTotalHealthLost + lUHealthLost
			end
		end
	end
	return lTotalHealthLost
end
dna.D.criteria["d/group/GetTotalHealthLoss"]={
	a=3,
	a1l=L["d/common/he/l"],a1dv="40000",a1tt=L["d/common/he/tt"],
	a2l=L["d/common/co/l"],a2dv=">",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/he/l"],a3dv="120000",a3tt=L["d/common/he/tt"],
	f=function () return format('dna.GetTotalHealthLoss(%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetTotalHealthLoss")', text=L["d/group/GetTotalHealthLoss"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetTotalHealthLossWithMyBuffName=function(spell, maxlossperunit)
	dna.D.ResetDebugTimer()
	local group, num
	local unitID
	local lTotalHealthLost = 0

	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	elseif ( dna.GetUnitHasBuffName("player", spell, "PLAYER") ) then
		lTotalHealthLost = dna.GetUnitHealthLost("player")
	end
	if ( group ) then
		for i = 1, num do
			unitID = group..i;
			local lUHealthLost = dna.GetUnitHealthLost(unitID)
			if ( maxlossperunit and maxlossperunit > 0 and lUHealthLost > maxlossperunit ) then lUHealthLost = maxlossperunit end -- Cap the total health loss so you do not go over what you are capable of healing
			if ( lUHealthLost > 0 and dna.GetUnitHasBuffName(unitID, spell, "PLAYER") ) then
				lTotalHealthLost = lTotalHealthLost + lUHealthLost
			end
		end
	end
	dna.AppendActionDebug( 'GetTotalHealthLossWithMyBuffName(spell='..tostring(spell)..',maxlossperunit='..tostring(maxlossperunit)..')='..tostring(lTotalHealthLost) )
	return lTotalHealthLost
end
dna.D.criteria["d/group/GetTotalHealthLossWithMyBuffName"]={
	a=4,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv="<",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/he/l"],a3dv="1200300",a3tt=L["d/common/he/tt"],
	a4l=L["d/common/he/l"],a4dv="30000",a4tt=L["d/common/he/tt"],
	f=function () return format('dna.GetTotalHealthLossWithMyBuffName(%q,%s)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg4"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetTotalHealthLossWithMyBuffName")', text=L["d/group/GetTotalHealthLossWithMyBuffName"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- dna.GetSpellOldestRaidBuffNameDuration=function(spell)
	-- local lOldest = 0

	-- local lSpellID = dna.GetSpellID( spell )
	-- for k,v in pairs (dna.D.P.TS) do
		-- local lTrackedSpellID = string.match( k , '^(%d+):' )
		-- local lDuration = ( GetTime()-v.lat ) --last applied time
		-- if ( lSpellID == lTrackedSpellID and lDuration > lOldest ) then
			-- lOldest = lDuration
		-- end
	-- end
	-- return lOldest
-- end
-- dna.D.criteria["d/group/GetSpellOldestRaidBuffNameDuration"]={
	-- a=3,
	-- a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	-- a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	-- a3l=L["d/common/seconds/l"],a3dv="2.5",a3tt=L["d/common/seconds/tt"],
	-- f=function () return format('dna.GetSpellOldestRaidBuffNameDuration(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText()) end,
-- }
-- tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetSpellOldestRaidBuffNameDuration")', text=L["d/group/GetSpellOldestRaidBuffNameDuration"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellNumberOfGroupMembersApplied=function(spell)
	local group, num
	local numberofgroupmembers = 0
	local unitID
	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	elseif ( dna.GetUnitHasBuffName("player", spell, "PLAYER") ) then
		return 1
	end
	if ( group ) then
		for i = 1, num do
			unitID = group..i;
			if ( dna.GetUnitHasBuffName(unitID, spell, "PLAYER") ) then
				numberofgroupmembers = numberofgroupmembers + 1
			end
		end
	end
	return numberofgroupmembers
end
dna.D.criteria["d/group/GetSpellNumberOfGroupMembersApplied"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="3",a3tt=L["d/common/count/tt"],
	f=function () return format('dna.GetSpellNumberOfGroupMembersApplied(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetSpellNumberOfGroupMembersApplied")', text=L["d/group/GetSpellNumberOfGroupMembersApplied"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetNumberOfGroupMembersMissingBuff=function(spell)
	dna.D.ResetDebugTimer()
	local group, num
	local count = 0
	local unitID
	if IsInRaid() then
		group, num = "raid", GetNumGroupMembers()
	elseif IsInGroup() then
		group, num = "party", GetNumSubgroupMembers()
	elseif ( not dna.GetUnitHasBuffName("player", spell, "player") ) then
		return 1
	end
	if ( group ) then
		for i = 1, num do
			unitID = group..i;
			if ( not dna.GetUnitHasBuffName(unitID, spell, "player") ) then
				count = count + 1
			end
		end
		if ( group == "party" ) then
			if ( not dna.GetUnitHasBuffName("player", spell, "player") ) then
				count = count + 1
			end
		end
	end
	dna.AppendActionDebug( 'GetNumberOfGroupMembersMissingBuff(spell='..tostring(spell)..')='..tostring(count) )
	return count
end
dna.D.criteria["d/group/GetNumberOfGroupMembersMissingBuff"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="1",a3tt=L["d/common/count/tt"],
	f=function () return format('dna.GetNumberOfGroupMembersMissingBuff(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetNumberOfGroupMembersMissingBuff")', text=L["d/group/GetNumberOfGroupMembersMissingBuff"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
dna.GetSpellNumberOfUnitsApplied=function(spell)
	dna.D.ResetDebugTimer()
	local lspellID = dna.GetSpellID(spell)
	local lCount=0
	for k,v in pairs(dna.D.P.TS) do
		if ( strfind(k, lspellID) ) then
			lCount = lCount + 1
		end
	end
    dna.AppendActionDebug( 'GetSpellNumberOfUnitsApplied(spell='..tostring(spell)..')='..tostring(lCount) )
	return lCount
end
dna.D.criteria["d/group/GetSpellNumberOfUnitsApplied"]={
	a=3,
	a1l=L["d/common/sp/l"],a1dv=L["d/common/sp/dv"],a1tt=L["d/common/sp/tt"],
	a2l=L["d/common/co/l"],a2dv=">=",a2tt=L["d/common/co/tt"],
	a3l=L["d/common/count/l"],a3dv="3",a3tt=L["d/common/count/tt"],
	f=function () return format('dna.GetSpellNumberOfUnitsApplied(%q)%s%s', dna.ui["ebArg1"]:GetText(), dna.ui["ebArg2"]:GetText(), dna.ui["ebArg3"]:GetText() ) end,
}
tinsert( dna.D.criteriatree[GROUP_CRITERIA].children, { value='dna.CreateCriteriaPanel("d/group/GetSpellNumberOfUnitsApplied")', text=L["d/group/GetSpellNumberOfUnitsApplied"] } )
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
