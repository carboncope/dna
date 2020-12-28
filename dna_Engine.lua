local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

-- dna.Engine 		= {}

function dna:fEngineOnTimer()


	-- clear the debug text first otherwise we cause lag
	dna.strAPIFunctionsCalled = ''
    dna.fSetPixelColors()
	local highestSpell = nil

	-- Return and save time if there is nothing to check
	if dna.bEngineReady == false then return end
	dna.bEngineReady = false

	if dna.nSelectedRotationTableIndex and dna.D.RTMC[dna.nSelectedRotationTableIndex] then
        dna.Actions = dna.D.RTMC[dna.nSelectedRotationTableIndex].children
        
		local bFoundHighestPriority = false
		for nActionKey, tAction in pairs(dna.D.RTMC[dna.nSelectedRotationTableIndex].children) do		
			--dna:dprint(tostring(GetTime()).." Engine checking tAction.text="..tostring(tAction.text))
						
			-- clear the debug text
			dna.strAPIFunctionsCalled = ''
			
			-- dna.nActionTicksTotal = 0
			--dna:dprint( "  tAction.fCriteria="..tostring(tAction.fCriteria))
			if tAction.fCriteria ~= nil then
				dna.bAPIResult = nil
				
				-- local nStartTick = os.clock()		
				local bNoErrors
                bNoErrors, dna.bAPIResult = pcall(tAction.fCriteria, tAction)
				tAction["_nemo_criteria_passed"] = false
				
				if bNoErrors and dna.bAPIResult == true and bFoundHighestPriority == false then
					tAction["_nemo_criteria_passed"] = true -- set _nemo_criteria_passed property to true so dna.GetActionCriteriaState works 
					-- In order for weak auras to work, you have to add this to first step of a action criteria
					-- Example: dna:SetActionValue(select(1,...),"_spellid",116670)
					if (tAction["_spellid"]) then
						highestSpell = tAction["_spellid"]
					end
					dna.Actions[nActionKey].bReady = dna.bAPIResult -- dna.Actions is a global that Weak auras can use to check if the criteria is passing for all actions in a rotation
						
					-- Only change values if the passing action has changed from the previous check
					-- print("  ["..tAction.text.."] Key="..tostring(dna.CurrentActionKeyBind))
					if dna.strPassingActionKeyBind ~= dna.CurrentActionKeyBind
						or dna.strPassingActionName ~= tAction.text
						then
						-- this section only fires if something changes
						if dna.D.OTM[dna.D.PClass].bPrintSpells then
							print("  ["..tAction.text.."] Key="..tostring(dna.CurrentActionKeyBind))
						end

						dna.strPassingActionKeyBind = dna.CurrentActionKeyBind
						dna.strPassingActionName = tAction.text
					end
					bFoundHighestPriority = true

				end
			end
			dna.fSetDebugInfo(dna.nSelectedRotationTableIndex, nActionKey)
		end
        -- We looped through the entire rotation, check if nothing passed then we need to clear the keybind
        if bFoundHighestPriority == false then
            dna.strPassingActionKeyBind = ""
			dna.strPassingActionName = ""
			dna.strPassingActionName = ""
		end
		if ( WeakAuras )then
			WeakAuras.ScanEvents('DNA_SPELL_UPDATE', highestSpell);
		end
	end
	
	dna.bEngineReady = true
end
