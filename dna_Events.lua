local self 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--********************************************************************************************
-- Locals
--********************************************************************************************
local strsub, strsplit, strlower, strmatch, strtrim, strfind = string.sub, string.split, string.lower, string.match, string.trim, string.find
local format, tonumber, tostring = string.format, tonumber, tostring

function dna:OnCommReceived(prefix, message, distribution, sender)
    print('dna Comm Received')
	if ( not StaticPopup_Visible( "dna_YESNOPOPUP" ) ) then
		local ldnaPopup = dna.ui.CreateYesNoPopupDialog(string.format(L["rotation/received/l"], sender))
		StaticPopupDialogs["dna_YESNOPOPUP"].OnAccept = function ()
			dna.D.UpdateMode = 0													--Create new rotation, do not update existing
			--dna.ui.RotationImport( message, true )
			dna.fRotationImport( message )
		end
	end
end

local UnitAura = UnitAura
-- Unit Aura function that return info about the first Aura matching the spellName or spellID given on the unit.
function dna:GetUnitAura(unit, spell, filter)
	if filter and not filter:upper():find("FUL") then
		filter = filter.."|HELPFUL" -- Auto append HELPFUL by default
	end

	local id = 1
	while( true ) do
		local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, id, filter)
		
		if( not name ) then return end
		if spell == spellId or spell == name then
			return UnitAura(unit, id, filter)
		end
		id = id + 1
	end
end

function dna:GetUnitBuff(unit, spell, filter)
  filter = filter and filter.."|HELPFUL" or "HELPFUL"
  return dna:GetUnitAura(unit, spell, filter)
end

function dna:GetUnitDebuff(unit, spell, filter)
  filter = filter and filter.."|HARMFUL" or "HARMFUL"
  return dna:GetUnitAura(unit, spell, filter)
end

function dna:UNIT_AURA(_,strUnitID)
	if ( strUnitID == "player" ) then
		if ( dna.D.PClass == "MONK") then --MONK stagger calculations
			-- local staggerLight = GetSpellInfo(124275)
			-- local staggerModerate = GetSpellInfo(124274)
			-- local staggerHeavy = GetSpellInfo(124273)

			-- local _,_,_,_,_,_,expirationTime,_,_,_,_,_,_,_,staggerActive = dna:GetUnitDebuff("player", GetSpellInfo(124275)) -- staggerLight
			
			--name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = dna:GetUnitDebuff("player", GetSpellInfo(124275)) -- staggerLight

			-- if (dna.IsBlank(staggerActive)) then _,_,_,_,_,_,expirationTime,_,_,_,_,_,_,_,staggerActive = dna:GetUnitDebuff("player", GetSpellInfo(124274)) end -- staggerModerate
			-- if (dna.IsBlank(staggerActive)) then _,_,_,_,_,_,expirationTime,_,_,_,_,_,_,_,staggerActive = dna:GetUnitDebuff("player", GetSpellInfo(124273)) end -- staggerHeavy

			--staggerA=dna.NilToNumeric( staggerA )

			-- expirationTime=dna.NilToNumeric( expirationTime )
			-- staggerActive=dna.NilToNumeric( staggerActive )
			-- print("staggerActive="..tostring(staggerActive))
			-- staggerTotal=dna.NilToNumeric( staggerActive*(expirationTime-GetTime()) )
			dna.D.P["STAGGER"].percent=dna.NilToNumeric( ( (dna.NilToNumeric( UnitStagger("player") ) /UnitHealthMax("player") ) * 100) )
			dna.D.P["STAGGER"].total=dna.NilToNumeric( UnitStagger("player") )
			--print("total="..tostring(dna.D.P["STAGGER"].total))
			--print("percent="..tostring(dna.D.P["STAGGER"].percent))
		end
		if (dna.D.PClass == "WARLOCK") then --WARLOCK Metamorphosis tracking
			local lPlayerHasMeta = UnitBuff("player", GetSpellInfo(103958))
			if ( dna.D.P["METAMORPHOSIS"].appliedtimestamp == 0 ) then
				--Check if Meta was applied
				if ( lPlayerHasMeta ) then
					dna.D.P["METAMORPHOSIS"].appliedtimestamp = GetTime()
				end
			elseif ( not lPlayerHasMeta ) then
				dna.D.P["METAMORPHOSIS"].appliedtimestamp = 0
			end
		end
	end
end

function dna:UNIT_SPELLCAST_START(event, casterUnit, castGUID, spellID)
	name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellID)
	if ( spellId and casterUnit == "player" ) then
        if spellId ~= 6603 then
            dna.D.lastcastedspellid = spellId
        end
		if spellId == dna.nLastSpellCastStartId then
			dna.nRunningSpellCastStartCount = (dna.nRunningSpellCastStartCount or 0) + 1
			dna:doprint("dna.nRunningSpellCastStartCount="..dna.nRunningSpellCastStartCount)
		elseif spellId ~= dna.D.lastcastedspellid then
			dna.nRunningSpellCastStartCount = 1
			dna:doprint("dna.nRunningSpellCastStartCount="..dna.nRunningSpellCastStartCount)
		end
		dna.nLastSpellCastStartId = spellId
		dna.SetSpellInfo( spellId, 'lastcastedtime', GetTime())
		dna:doprint(GetTime().." UNIT_SPELLCAST_START:Player spellid["..tostring(spellId).."] spellname["..tostring(name)..']')
	end
	if ( spellId and casterUnit == "pet" ) then
		dna.SetSpellInfo( spellId, 'lastcastedtime', GetTime())
		dna:doprint(GetTime().." UNIT_SPELLCAST_START:Pet spellid["..tostring(spellId).."] spellname["..tostring(name)..']')
	end
    if ( spellId and casterUnit ~= "player" and not UnitIsFriend(casterUnit, "player" ) ) then
        if ( dna.GetUnitCastingInterruptibleSpell(casterUnit) ) then
            dna.AddListEntry( 'NPC_INTERRUPTABLE', false, spellId, 's' )
        else
            dna.AddListEntry( 'NPC_OTHER', false, spellId, 's' )
        end
    end
end

function dna:UNIT_SPELLCAST_CHANNEL_START(event, casterUnit, castGUID, spellID)
	name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellID)
	if ( spellId and casterUnit == "player" ) then
        if spellId ~= 6603 then
            dna.D.lastcastedspellid = spellId
        end
		dna.SetSpellInfo( spellId, 'lastcastedtime', GetTime())
		dna:doprint(GetTime().." UNIT_SPELLCAST_CHANNEL_START:Player "..tostring(numSpellId).." "..tostring(dna.GetSpellName(numSpellId)))
	end
	if ( spellId and casterUnit == "pet" ) then
		dna.SetSpellInfo( spellId, 'lastcastedtime', GetTime())
		dna:doprint(GetTime().." UNIT_SPELLCAST_CHANNEL_START:Pet spellid["..tostring(spellId).."] spellname["..tostring(name)..']')
	end
    if ( spellId and casterUnit ~= "player" and not UnitIsFriend(casterUnit, "player" ) ) then
        if ( dna.GetUnitCastingInterruptibleSpell(casterUnit) ) then
            dna.AddListEntry( 'NPC_INTERRUPTABLE', false, spellId, 's' )
        else
           dna.AddListEntry( 'NPC_OTHER', false, spellId, 's' )
        end
    end
end
function dna:UNIT_SPELLCAST_SUCCEEDED(event, casterUnit, castGUID, spellID)
	--https://wow.gamepedia.com/UNIT_SPELLCAST_SUCCEEDED
	--https://wow.gamepedia.com/API_GetSpellInfo
	name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellID)
	if ( spellId and casterUnit == "player" ) then
		if ( dna.GetSpellCastTime(spellId) == 0 ) then				-- Only update last casted time for instant or channeled spells
            if spellId ~= 6603 then
                dna.D.lastcastedspellid = spellId
            end
			dna.SetSpellInfo( spellId, 'lastcastedtime', GetTime())
            dna:doprint(GetTime().." UNIT_SPELLCAST_SUCCEEDED:Player spellid["..tostring(spellId).."] spellname["..tostring(name)..']')
		end
	end
	if ( spellId and casterUnit == "pet" ) then
		if ( dna.GetSpellCastTime(spellId) == 0 ) then
			dna.SetSpellInfo( spellId, 'lastcastedtime', GetTime())
			dna:doprint(GetTime().." UNIT_SPELLCAST_SUCCEEDED:Pet spellid["..tostring(spellId).."] spellname["..tostring(name)..']')
		end
	end
    if ( spellId and casterUnit ~= "player" and not UnitIsFriend(casterUnit, "player" ) ) then
        if ( dna.GetUnitCastingInterruptibleSpell(casterUnit) ) then
            dna.AddListEntry( 'NPC_INTERRUPTABLE', false, spellId, 's' )
        else
           dna.AddListEntry( 'NPC_OTHER', false, spellId, 's' )
        end
    end
end

function self:ACTIVE_TALENT_GROUP_CHANGED()
	self:SetRotationForCurrentSpec()
end

function dna:PLAYER_ENTERING_WORLD()
	if ( dna.IsBlank(dna.D.OTM[dna.D.PClass].selectedrotation) ) then
		self:SetRotationForCurrentSpec()								-- Select the rotation that matches the current specialization or talentgroup
	else
		dna.ui.SelectRotation(dna.D.OTM[dna.D.PClass].selectedrotation, false) 		  		-- Select the last loaded rotation
	end
end

function dna:PLAYER_REGEN_ENABLED()
	dna.D.P.EnteredCombatTime = 0
end

function dna:PLAYER_REGEN_DISABLED()
	dna.D.P.EnteredCombatTime = GetTime()
end