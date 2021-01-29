local dna = LibStub("AceAddon-3.0"):GetAddon("dna")
local L = LibStub("AceLocale-3.0"):GetLocale("dna")

--********************************************************************************************
-- Locals
--********************************************************************************************
local tsort, tinsert = table.sort, table.insert

--********************************************************************************************
-- dna buttons table
--********************************************************************************************
dna.buttons	= {} 				-- Table of secure action buttons found with spellIds as the index
-- dna.AButtons.Frames			= {}				--The Action Button Frames
-- dna.AButtons.ExternalButtons	= {}				--Saved table of external buttons
--dna.AButtons.SlotToSABFrame	= {}				--Convert action slots to external frames that we care about
-- dna.AButtons.RFrames			= {}				--The Rotation Button Frames used for binding a key to a rotation
-- dna.AButtons.bInitComplete 	= false				--The boolean to tell the engine the buttons need to be reinitialized
-- dna.AButtons.bInInit			= false				--The boolean to throttle calls to initialize
-- dna.AButtons.LastInit      	= GetTime()			--Last Initialization time stamp

local LABs = {
	['LibActionButton-1.0'] = true,
	['LibActionButton-1.0-ElvUI'] = true,
}

function dna:AddStandardButton(button)
	local type = button:GetAttribute('type');
	if type then
		local actionType = button:GetAttribute(type);
		local id;
		local spellId;

		if type == 'action' then
			local slot = button:GetAttribute('action');
			if not slot or slot == 0 then
				slot = button:GetPagedID();
			end
			if not slot or slot == 0 then
				slot = button:CalculateAction();
			end

			if HasAction(slot) then
				type, actionType = GetActionInfo(slot);
			else
				return
			end
		end

		if type == 'macro' then
			spellId = GetMacroSpell(actionType);
		elseif type == 'item' then
			self:AddItemButton(button);
			return
		elseif type == 'spell' then
			spellId = select(7, GetSpellInfo(actionType));
		end

		self:AddButton(spellId, button);
	end
end

function dna:FetchDominos()
	-- Dominos is using half of the blizzard frames so we just fetch the missing one

	for i = 1, 60 do
		local button = _G['DominosActionButton' .. i];
		if button then
			--self:AddStandardButton(button);
		end
	end
end

function dna:scan_buttons()
	
	-- Store a lookup table of commands to key bindings so we can identify the keybind for the command
	for buttonIndex=1, GetNumBindings() do
		local command, category, key1, key2, result3 = GetBinding(buttonIndex)
		if ( command ) then
			--dna:dprint('    buttonIndex['..buttonIndex..'] key1['..tostring(key1)..'] key2['..tostring(key2)..']') 
			if ( key1 and strlen(key1) == 1 ) then
				dna.D.binds[command] = key1
			elseif ( key2 and strlen(key2) == 1 ) then
				dna.D.binds[command] = key2
			end
		end
	end

	-- self:GlowClear();
	-- self.Spells = {};
	-- self.ItemSpells = {};
	-- self.Flags = {};
	-- self.SpellsGlowing = {};

	dna:scan_lib_action_buttons()
	-- self:FetchBlizzard();

	-- It does not alter original button frames so it needs to be fetched too
	if IsAddOnLoaded('ButtonForge') then
		-- self:FetchButtonForge();
	end

	if IsAddOnLoaded('G15Buttons') then
		-- self:FetchG15Buttons();
	end

	if IsAddOnLoaded('SyncUI') then
		-- self:FetchSyncUI();
	end

	if IsAddOnLoaded('LUI') then
		-- self:FetchLUI();
	end

	if IsAddOnLoaded('Dominos') then
		self:FetchDominos();
	end

	if IsAddOnLoaded('DiabolicUI') then
		-- self:FetchDiabolic();
	end

	if IsAddOnLoaded('AzeriteUI') then
		-- self:FetchAzeriteUI();
	end

	if IsAddOnLoaded('Neuron') then
		-- self:FetchNeuron();
	end

end

function dna:add_button(spellId, button)
    if spellId then
        if dna.buttons[spellId] == nil then
            dna.buttons[spellId] = {}
        end

        tinsert(dna.buttons[spellId], button)
    end
end

function dna:add_item_button(button)
    local actionSlot = button:GetAttribute("action")

    if actionSlot and (IsEquippedAction(actionSlot) or IsConsumableAction(actionSlot)) then
        local type, itemId = GetActionInfo(actionSlot)
        if type == "item" then
            local _, itemSpellId = GetItemSpell(itemId)
            self:add_button(itemSpellId, button)
        end
    end
end

function dna:scan_lib_action_buttons()
	for LAB in pairs(LABs) do
		local lib = LibStub(LAB, true);
		if lib then
			for button in pairs(lib:GetAllButtons()) do
				local spellId = button:GetSpellId();
				if spellId then
					self:add_button(spellId, button);
				end

				self:add_item_button(button);
			end
		end
	end
end



