local self 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--********************************************************************************************
-- Locals
--********************************************************************************************
local strsub, strsplit, strlower, strmatch, strtrim, strfind, strlen= string.sub, string.split, string.lower, string.match, string.trim, string.find, string.len
local format, tonumber, tostring = string.format, tonumber, tostring
local TableInsert = tinsert;
local TableRemove = tremove;
local TableContains = tContains;
local TableIndexOf = tIndexOf;
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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


function dna:NAME_PLATE_UNIT_ADDED(_, nameplateUnit)
	if not TableContains(dna.D.visibleNameplates, nameplateUnit) then
		TableInsert(dna.D.visibleNameplates, nameplateUnit);
	end
end
function dna:NAME_PLATE_UNIT_REMOVED(_, nameplateUnit)
	if TableIndexOf(dna.D.visibleNameplates, nameplateUnit) ~= nil then
		TableRemove(dna.D.visibleNameplates, index)
	end
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
			
			
			-- dna.D.P["STAGGER"].percent=dna.NilToNumeric( ( (dna.NilToNumeric( UnitStagger("player") ) /UnitHealthMax("player") ) * 100) )
			-- dna.D.P["STAGGER"].total=dna.NilToNumeric( UnitStagger("player") )
			
			
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
	if (dna.GetSpellCooldown(61304) ~= dna.D.GCDTime ) then
		dna.D.GCDTime = dna.GetSpellCooldown(61304)
	end

	name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellID)
	if ( spellId and casterUnit == "player" ) then
        -- if spellId ~= 6603 then -- Changed 1/2/2021 because only successful casts should be counted in UNIT_SPELLCAST_SUCCEEDED
            -- dna.D.lastcastedspellid = spellId
        -- end
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
        -- if spellId ~= 6603 then -- Changed 1/2/2021 because only successful casts should be counted in UNIT_SPELLCAST_SUCCEEDED
            -- dna.D.lastcastedspellid = spellId
        -- end
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
	spellName1, spellSubName1 = GetSpellBookItemName( spellId, BOOKTYPE_SPELL );
	spellName2, spellSubName2 = GetSpellBookItemName( spellId, BOOKTYPE_PET  );

	if ( spellId and casterUnit == "player" ) then
		if ( dna.GetSpellCastTime(spellId) == 0 ) then				-- Only update last casted time for instant or channeled spells
            if spellId ~= 6603 then
				-- Before we update last casted spell, check if the spell changed from last time and reset the count to zero
				if (dna.D.lastcastedspellid ~= spellId) then
					dna.SetSpellInfo( dna.D.lastcastedspellid, 'castcount', 0)
					dna.SetSpellInfo( spellId, 'castcount', 1)
				else
					dna.D.SpellInfo[tostring(spellId)].castcount = dna.D.SpellInfo[tostring(spellId)].castcount + 1
				end

				-- Before adding a spell to cast history, make sure we dont track more than 10 spells
				if ( #dna.D.PlayerCastHistory > 9 ) then
					table.remove(dna.D.PlayerCastHistory,1)
				end
				dna.D.PlayerCastHistory[#dna.D.PlayerCastHistory+1] = name
				
				
				
				--dna:doprint(GetTime().." dna.D.PlayerCastHistory-------------------")
				--dna:rtprint(dna.D.PlayerCastHistory)
				
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

function dna:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, _, _, _, extraArg1, extraArg2, extraArg3, extraArg4, extraArg5, extraArg6, extraArg7, extraArg8, extraArg9, extraArg10 = CombatLogGetCurrentEventInfo()
	local amount
		
	-- Only destination player below here
	local amount

	if (destGUID == UnitGUID("player") and strfind(subevent, "DAMAGE")) then
		-- dna:doprint("COMBAT_LOG_EVENT_UNFILTERED subevent="..tostring(subevent))
		-- dna:doprint("    extraArg1="..tostring(extraArg1))
		-- dna:doprint("    extraArg2="..tostring(extraArg2))
		-- dna:doprint("    extraArg3="..tostring(extraArg3))
		-- dna:doprint("    extraArg4="..tostring(extraArg4))
	
		if subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE" then
			amount = extraArg4
		elseif subevent == "SWING_DAMAGE" then
			amount = extraArg1
		elseif subevent == "ENVIRONMENTAL_DAMAGE" then
			amount = extraArg2
		end
		if (amount) then
			-- Record new damage at the top of the log:
			tinsert(dna.D.damageAmounts, 1, amount)
			tinsert(dna.D.damageTimestamps, 1, timestamp)
		end
	end
	
	-- Clear out old entries from the bottom, and add up the remaining ones:
	local cutoff = timestamp - 5
	damageInLast5Seconds = 0
	for i = #dna.D.damageTimestamps, 1, -1 do
		local timestamp = dna.D.damageTimestamps[i]
		if timestamp < cutoff then
			dna.D.damageTimestamps[i] = nil
			dna.D.damageAmounts[i] = nil
		else
			damageInLast5Seconds = damageInLast5Seconds + dna.D.damageAmounts[i]
		end
	end
	dna.D.damageInLast5Seconds = damageInLast5Seconds
	--dna:dprint("  dna.D.damageInLast5Seconds="..tostring(dna.D.damageInLast5Seconds))
end

function dna:PLAYER_ENTERING_WORLD()
	if ( dna.IsBlank(dna.D.OTM[dna.D.PClass].selectedrotation) ) then
		self:SetRotationForCurrentSpec()								-- Select the rotation that matches the current specialization or talentgroup
	else
		dna.ui.SelectRotation(dna.D.OTM[dna.D.PClass].selectedrotation, false) 		  		-- Select the last loaded rotation
	end
	
	dna:scan_buttons()
end

function dna:PLAYER_REGEN_ENABLED()
	dna.D.P.EnteredCombatTime = 0
end

function dna:PLAYER_REGEN_DISABLED()
	dna.D.P.EnteredCombatTime = GetTime()
end