local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--*****************************************************
--Action UI Utility functions
--*****************************************************
function dna.ui:GetMacrotextTooltip( macrotext )
	if ( macrotext ) then
		local spell = macrotext:match("^%s*#show%a*%s*(.*)")
		if ( spell ) then
			spell = string.gsub(spell, "(;.*)", "")
			spell = string.gsub(spell, "(\n.*)", "")
			spell = strtrim(spell)
			return spell
		end
	end
end
function dna.ui:GetActionTexture( dnaSABFrame )
	local lTexture		= "Interface\\Icons\\INV_Misc_QuestionMark"
	if ( not dnaSABFrame or not dnaSABFrame._dna_action_db ) then
		return lTexture
	end
	local bHasType = not dna.IsBlank(dnaSABFrame._dna_action_db.at)
	local lType    = dnaSABFrame._dna_action_db.at
	local bHasAtt1 = not dna.IsBlank(dnaSABFrame._dna_action_db.att1)
	local lAtt1    = dnaSABFrame._dna_action_db.att1
	local bHasAtt2 = not dna.IsBlank(dnaSABFrame._dna_action_db.att2)
	local lAtt2    = dnaSABFrame._dna_action_db.att2
	local lTargetType, lTargetGID = GetActionInfo( dnaSABFrame._dna_external_slot or 0 )
-- if ( dnaSABFrame._dna_action_text == '[A]Ancestral Swiftness' ) then
-- print( "GetActionTexture  lType="..tostring(lType) )		
-- print( "   lAtt1="..tostring(lAtt1) )		
-- print( "   bHasAtt1="..tostring(bHasAtt1) )		
-- end

	if ( not bHasType ) then
		dnaSABFrame._dna_getactiontexture_status = L["action/_dna_getactiontexture_status/e2"]
		return lTexture
	end
	
	if ( lType == "spell" and bHasAtt2 ) then	-- Handle a spell type action
		local lSpellID 		= dna.GetSpellID(lAtt2)
		local ldnaSpellDB	= dna.D.SpellInfo[lSpellID]
		
		if ( ldnaSpellDB and ldnaSpellDB.texture ) then
			dnaSABFrame._dna_getactiontexture_status = "|cff00FF00OK|r"
			return ldnaSpellDB.texture
		elseif ( lSpellID and GetSpellInfo( lSpellID ) and GetSpellTexture( GetSpellInfo( lSpellID ) ) ) then
			lTexture = select(2, GetSpellInfo( lSpellID ) )
			dnaSABFrame._dna_getactiontexture_status = "|cff00FF00OK|r"
			return lTexture
		elseif ( dnaSABFrame._dna_external_frame and tostring(dnaSABFrame._dna_gid) == tostring(lTargetGID) and lType == lTargetType ) then
			lTexture = ( _G[dnaSABFrame._dna_external_frame:GetName().."Icon"]:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark" )
			dnaSABFrame._dna_getactiontexture_status = "|cff00FF00OK|r"
			return lTexture
		end
		
		-- dna:dprint( 'couldnt find spell in dna dna.D.SpellInfo['..tostring(lAtt2)..'] dna.GetSpellID='..tostring(dna.GetSpellID(lAtt2)) )			
		dnaSABFrame._dna_getactiontexture_status = L["action/_dna_getactiontexture_status/e3"]
		return "Interface\\Icons\\INV_Misc_QuestionMark"

		
		--return GetSpellTexture( dna.GetSpellID(lAtt2) ) or ""
	elseif ( lType == "macro" and bHasAtt1 ) then
-- dna:dprint( 'lType == macro '..lAtt1 )			
		lTexture = select(2, GetMacroInfo( lAtt1 ) ) or ""
		dnaSABFrame._dna_getactiontexture_status = "|cff00FF00Macro|r"
		return lTexture
	elseif ( lType == "macrotext" and dna.ui:GetMacrotextTooltip(lAtt1) and bHasAtt1 ) then
		lTexture = GetSpellTexture( dna.GetSpellID( dna.ui:GetMacrotextTooltip(lAtt1) ) )
		dnaSABFrame._dna_getactiontexture_status = "|cff00FF00Macrotext|r"
		return lTexture
	elseif ( lType == "item" and bHasAtt1 ) then
		lTexture = select(10, GetItemInfo( lAtt1 ) ) or lAtt1
		dnaSABFrame._dna_getactiontexture_status = "|cff00FF00Item|r"
		return lTexture
	else
		return ""
	end
end
function dna.ui.GetActionLink( actiontype, att1, att2 )
	if ( dna.IsBlank(actiontype) ) then return nil end
	if ( actiontype == "spell" and (not dna.IsBlank(att2)) ) then
		return GetSpellLink( dna.GetSpellID( att2 ) )
	elseif ( actiontype == "macrotext" and dna.ui:GetMacrotextTooltip(att1) and not dna.IsBlank(att1) ) then
		return GetSpellLink( dna.GetSpellID( dna.ui:GetMacrotextTooltip(att1) ) )
	elseif ( actiontype == "item" and (not dna.IsBlank(att1)) ) then
		return select(2, GetItemInfo( att1 ) ) or nil
	end
end
function dna.ui.ShowTooltip(frame, text, anchor1, anchor2, xOff, yOff, ttType)
 	if ( dna.IsBlank( text) ) then return end
	if ( frame ) then GameTooltip:SetOwner(frame, "ANCHOR_NONE") end
	if ( anchor1 ) then GameTooltip:SetPoint(anchor1 or "LEFT", frame, anchor2 or "RIGHT", xOff, yOff) end
	if ( ttType == "link" ) then
		GameTooltip:SetHyperlink(text or "")
	elseif ( ttType == "action" ) then
		GameTooltip:SetAction(text)
	elseif ( ttType == "text" ) then
		GameTooltip:SetText(text or "")
	end
	GameTooltip:Show()
end
function dna.ui.EntryHasErrors( text, bAllowBlank )
	if ( (not bAllowBlank) and dna.IsBlank( text ) ) then return 1 end 		-- Blank
	if ( text and string.find(text, '%[=%[') ) then return 2 end				-- Nesting
	if ( text and string.find(text, '%]=%]') ) then return 3 end				-- Nesting
	if ( text and string.find(text, '%[==%[') ) then return 4 end				-- Nesting
	if ( text and string.find(text, '%]==%]') ) then return 5 end				-- Nesting
	if ( text and string.find(text, 'update') ) then return 5 end				-- update is a command line arg
	return nil
end

function dna.ui.HideTooltip()
	GameTooltip:Hide()
end
function dna.ui.SetSelectedTreeLevel(ttable, button, buttonpathtable, level)
	level = level or 1
	for k,v in pairs(ttable) do
		if ( v.value == buttonpathtable[level] ) then
			tinsert(dna.ui.STL, k)
			if ( level ~= button.level ) then									--Selected Tree Button Level
				dna.ui.SetSelectedTreeLevel(ttable[k].children, button, buttonpathtable, level+1)
			end
			return
		end
	end
end

function dna.ui.fUpdateMenuText()
	if ( dna.D.LDB ) then
		if ( not dna.IsBlank(dna.D.OTM[dna.D.PClass].selectedrotation) ) then
			dna.D.LDB.text = L["common/dna"].." "..tostring( dna.D.OTM[dna.D.PClass].selectedrotation or "" )
		else
			dna.D.LDB.text = L["common/dna"]
		end
	end
end

--*****************************************************
--Create Yes/No Dialog function
--*****************************************************
function dna.ui.CreateYesNoPopupDialog(DialogText, hasEditBox, EditBoxText)
	StaticPopupDialogs["dna_YESNOPOPUP"] = {
		text = DialogText,
		button1 = L["common/yes"],
		button2 = L["common/no"],
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		hasEditBox = (hasEditBox or false),
		OnShow = function (self, data)
			if hasEditBox then
				self.editBox:SetText(EditBoxText)
				self.editBox:SetFocus(0)
				self.editBox:SetCursorPosition(0)
				self.editBox:HighlightText()
			end
		end,
	}
	StaticPopup_Show("dna_YESNOPOPUP")
end
--*****************************************************
--Create Text Dialog function
--*****************************************************
function dna.ui.CreateTextPopupDialog(DialogText, hasEditBox, EditBoxText)
	StaticPopupDialogs["dna_TEXTPOPUP"] = {
		text = DialogText,
		button1 = L["common/done"],
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		hasEditBox = (hasEditBox or false),
		OnShow = function (self, data)
			if hasEditBox then
				self.editBox:SetText(EditBoxText)
				self.editBox:SetFocus(0)
				self.editBox:SetCursorPosition(0)
				self.editBox:HighlightText()
			end
		end,
	}
	return StaticPopup_Show("dna_TEXTPOPUP")
end


--*****************************************************
--Main Configuration window
--*****************************************************
function dna.ui.CreateMainFrame()
	if ( dna.ui.fMain and dna.ui.fMain:IsShown() ) then
		return
	end

	dna.ui.fMain = dna.lib_acegui:Create("Frame")
	dna.ui.fMain:SetTitle(L["common/dna"]..' '..L["common/versionprefix"]..GetAddOnMetadata("dna", "Version"))
	dna.ui.fMain:SetWidth(750)
	dna.ui.fMain:SetHeight(700)
	dna.ui.fMain:SetLayout("Fill")
	dna.ui.fMain:EnableResize(false)
	dna.ui.fMain.frame:SetScale( 1 )

	-- simplegroup to hold the Main treegroup, treegroups require fill layouts to display properly
	dna.ui.sgMain = dna.lib_acegui:Create("SimpleGroup")
	dna.ui.sgMain:SetLayout("Fill")
	dna.ui.fMain:AddChild(dna.ui.sgMain)

	-- Main treegroup on the left
	dna.ui.sgMain.tgMain = dna.lib_acegui:Create( "TreeGroup" )
	dna.ui.sgMain:AddChild(dna.ui.sgMain.tgMain)
	dna.ui.sgMain.tgMain:SetTree( dna.DB.global.treeMain )
	dna.ui.sgMain.tgMain:SetCallback( "OnGroupSelected", dna.ui.tgMainOnGroupSelected )
	dna.ui.sgMain.tgMain:SetTreeWidth( 200, false )
	dna.ui.sgMain.tgMain:EnableButtonTooltips(true)

	-- Main simple group panel on right
	dna.ui.sgMain.tgMain.sgPanel = dna.lib_acegui:Create("SimpleGroup")
	dna.ui.sgMain.tgMain:AddChild(dna.ui.sgMain.tgMain.sgPanel)
	dna.ui.sgMain.tgMain.sgPanel:SetFullWidth(true)
	dna.ui.sgMain.tgMain.sgPanel:SetHeight(0)
	dna.ui.sgMain.tgMain.sgPanel:SetLayout("Fill")

end

--Main UI Callbacks-------------------------------
function dna.ui.tgMainOnGroupSelected(self, functionname, buttonvalue)
	local lUniqueValue = ""
	self:RefreshTree()															--Call wowace RefreshTree so .selected gets updated
	dna.ui.sgMain.tgMain.sgPanel:ReleaseChildren()								--Clears the right panel
	dna.ui.STL 					= {}											--Reset the Selected Tree Level (STL)
	
	if strfind(buttonvalue, "\001") then
		for token in string.gmatch(buttonvalue, "[^\001]+") do
			lUniqueValue = token												--Last token is the unique value
		end
	else
		lUniqueValue=buttonvalue
	end
	
	for k,button in pairs(dna.ui.sgMain.tgMain.buttons) do						--Loop through the tree menu buttons to find the one that matches what was selected
		if ( button.value == lUniqueValue and button.selected) then
			dna.ui.SetSelectedTreeLevel(dna.DB.global.treeMain, button, { strsplit("\001", button.uniquevalue) } )
			dna.D.RunCode( button.value, '', "dna.ui.tgMainOnGroupSelected error pcall:", false, true  )	-- Use the wowace .value field to create a function
		end
	end
end