local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

dna.class_action = {}
dna.class_action.__index = dna.class_action

--[[
-- syntax equivalent to "MyClass.new = function..."
function MyClass.new(init)
  local self = setmetatable({}, MyClass)
  self.value = init
  return self
end

function MyClass.set_value(self, newval)
  self.value = newval
end

function MyClass.get_value(self)
  return self.value
end

local i = MyClass.new(5)
-- tbl:name(arg) is a shortcut for tbl.name(tbl, arg), except tbl is evaluated only once
print(i:get_value()) --> 5
i:set_value(6)
print(i:get_value()) --> 6
--]]

--*****************************************************
--Action Utility functions
--*****************************************************
function dna.AddAction( ActionName, ShowError, ActionType, Att1, Att2, X,Y,H,W, Criteria)
	if ( dna.ui.EntryHasErrors( ActionName ) ) then
		if ( dna.ui.sgMain ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], ActionName) ) end
		return
	end
	-- Create the rotation if needed
-- dna:dprint("AddAction to rotationname="..dna.D.ImportName)
	local lRotationKey = nil
	if ( dna.D.ImportType and dna.D.ImportType == 'actionpack' and dna.D.OTM[dna.D.PClass].selectedrotationkey ) then
		lRotationKey  = dna.D.OTM[dna.D.PClass].selectedrotationkey
	else
		lRotationKey  = dna:SearchTable(dna.D.RTMC, "text", dna.D.ImportName)
	end
-- dna:dprint("AddAction lRotationKey="..tostring(lRotationKey))
	if ( not lRotationKey ) then
		if ( dna.ui.fMain and dna.ui.fMain:IsShown() ) then dna.ui.fMain:SetStatusText( L["rotations/rimportfail/E6"] ) end
		print( L["utils/debug/prefix"]..L["rotations/rimportfail/E5"] )
		return
	end
	
	-- Create the action
	local lActionExists   = dna:SearchTable(dna.D.RTMC[lRotationKey].children, "text", ActionName)
	local lNewActionValue = 'dna.ui:CAP([=['..ActionName..']=])'
	local lNewActionText  = ActionName
	if ( dna.D.UpdateMode==0 and lActionExists ) then
-- dna:dprint("found duplicate action="..ActionName.." dna.D.UpdateMode="..dna.D.UpdateMode)
		local iSuffix = 0
		lNewActionText = lNewActionText..'_'
		while lActionExists do
			iSuffix = iSuffix+1
			lActionExists = dna:SearchTable(dna.D.RTMC[lRotationKey].children, "text", lNewActionText..iSuffix)
		end
		lNewActionValue = 'dna.ui:CAP([=['..lNewActionText..iSuffix..']=])'
		lNewActionText = lNewActionText..iSuffix
	end
	local lNewAction = { value = lNewActionValue, text = lNewActionText}
	lActionExists   = dna:SearchTable(dna.D.RTMC[lRotationKey].children, "text", lNewActionText)
	if ( lActionExists ) then
		if ( dna.ui.sgMain and ShowError ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], lNewActionText) ) end
        if ( dna.ui.sgMain ) then dna.ui.fMain:SetStatusText( '' ) end -- Clear any previous errors
        if ( dna.D.ImportType and dna.D.ImportType == 'rotation' ) then
            table.insert( dna.D.RTMC[lRotationKey].children, lNewAction)
        else
            dna.D.ImportIndex = dna.D.ImportIndex + 1
            table.insert( dna.D.RTMC[lRotationKey].children, dna.D.ImportIndex, lNewAction)
        end
	else
		if ( dna.ui.sgMain ) then dna.ui.fMain:SetStatusText( '' ) end -- Clear any previous errors
		if ( dna.D.ImportType and dna.D.ImportType == 'rotation' ) then
			table.insert( dna.D.RTMC[lRotationKey].children, lNewAction)
		else
			dna.D.ImportIndex = dna.D.ImportIndex + 1
			table.insert( dna.D.RTMC[lRotationKey].children, dna.D.ImportIndex, lNewAction)
		end
	end
	lActionExists   = dna:SearchTable(dna.D.RTMC[lRotationKey].children, "text", lNewActionText)
	if ( lActionExists ) then 
		local ActionDB = dna.D.RTMC[lRotationKey].children[lActionExists]
		if ( not dna.IsBlank(ActionType) ) then ActionDB.at   = ActionType end
		if ( not dna.IsBlank(Att1) )       then ActionDB.att1 = Att1 end
		if ( not dna.IsBlank(Att2) )       then ActionDB.att2 = Att2 end		
		if ( not dna.IsBlank(X) and dna.IsBlank(ActionDB.x) )	then ActionDB.x = X end --Only update if the database is blank and the update is not blank
		if ( not dna.IsBlank(Y) and dna.IsBlank(ActionDB.y) )	then ActionDB.y = Y end
		if ( not dna.IsBlank(H) and dna.IsBlank(ActionDB.h) )	then ActionDB.h = H end
		if ( not dna.IsBlank(W) and dna.IsBlank(ActionDB.w) )	then ActionDB.w = W end
		if ( not dna.IsBlank(Criteria) ) 	then ActionDB.criteria = Criteria end
	end
	if ( dna.ui.sgMain ) then dna.ui.sgMain.tgMain:RefreshTree() end
	--TODO: Add reinit any overlays here
	return lNewActionText, lActionExists
end

function dna.fActionSave()
	-- Create the criteria function from the ActionDB.criteria field
	-- local dnaSABFrame = nil
-- dna:dprint(GetTime().."dna.fActionSave dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].criteria="..tostring(dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].criteria))
	local ret1
	if (string.find( dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].criteria or "", '--_dna_enable_lua' ) ) then	
		dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].fCriteria, ret1=loadstring(dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].criteria or "return false")			-- Create Function for engine to check the criteria with full lua allowed in criteria
	else
-- dna:dprint(GetTime().."dna.fActionSave lua not enabled")
		dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].fCriteria, ret1=loadstring("return "..(dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].criteria or "false"))		-- Create Function for engine to check the criteria with prepended return
-- dna:dprint(GetTime().."dna.fActionSave after save fCriteria="..tostring(dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].fCriteria))
	end
	
	if ( not dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].fCriteria ) then
		-- We have a syntax problem
		dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].strSyntax = L["action/_dna_syntax_status/e1"]..":"..ret1
		print(L["utils/debug/prefix"]..L["action/bCriteriaTest/loadstringerror"].." "..tostring(dna.D.RTMC[dna.ui.STL[2]].text)..":"..tostring(dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].text))
	else
		dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].strSyntax = nil
	end
end
--*****************************************************
--Action Panel
--*****************************************************
function dna.ui:CAP(ActionName)--CAP=Create Action Panel
	dna.ui.DB = {}

	dna.ui.sgMain.tgMain:RefreshTree() 										-- Gets rid of the rotation from the tree
	dna.ui.sgMain.tgMain.sgPanel:ReleaseChildren() 							-- clears the right panel
	
	dna.ui.SelectRotation(dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].text, true)	-- Select the rotation first
	dna.ui.DB = dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].children[dna.ui.STL[3]]
	
	dna.ui.sgMain.tgMain.sgPanel:ResumeLayout()	-- Pause or resume the righ tsgPanel fill layout if you need it or not
	
	-- Criteria tree goes in the sgPanel
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria = dna.lib_acegui:Create("TreeGroup")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.tgCriteria )
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria:SetTree( dna.D.criteriatree )

	dna.ui.sgMain.tgMain.sgPanel:SetHeight(315)
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria:SetTreeWidth( 350, true )  -- This is the left side width with the categories
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria:SetFullWidth(true)
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria:SetCallback( "OnGroupSelected", dna.ui.tgCriteriaOnGroupSelected )

	-- Create the criteria panel
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel = dna.lib_acegui:Create("SimpleGroup")
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria:AddChild(dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel)
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel:SetLayout("List")
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel:SetFullWidth(true)
    dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel:SetWidth(100)

	-- The criteria edit box
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.mlebCriteria = dna.lib_acegui:Create( "MultiLineEditBox" )
	local mlebCriteria = dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.mlebCriteria
	dna.ui.sgMain.tgMain.sgPanel:AddChild( mlebCriteria )
	mlebCriteria:SetLabel( L["action/mlebCriteria/l"] )
	mlebCriteria:SetHeight(250)
	mlebCriteria:SetWidth(480)
	mlebCriteria:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.tgCriteria.frame, "BOTTOMLEFT", 20, 0)
	mlebCriteria:SetCallback( "OnEnterPressed" , function(self)
		dna.ui.DB.criteria = self:GetText()
		dna.fActionSave()
	end )
	mlebCriteria.editBox:SetScript("OnMouseUp",function(self, button)
		dna.ui.fMain:SetStatusText( '' )
		local Text, Cursor = self:GetText(), self:GetCursorPosition()
		self:Insert( "" ) -- Delete selected text
		local TextNew, CursorNew = self:GetText(), self:GetCursorPosition()
		self:SetText( Text ) --Restore previous text
		self:SetCursorPosition( Cursor )
		local Start, End = CursorNew, #Text - ( #TextNew - CursorNew )
		self:HighlightText( Start, End )
		local lHighlightedText = tostring(string.sub(self:GetText(), (Start+1), End))
		local spellLink = GetSpellLink( lHighlightedText )
		if ( spellLink ) then
			print(L["utils/debug/prefix"]..spellLink)
			dna.ui.fMain:SetStatusText( spellLink )
		elseif ( select(2, GetItemInfo( lHighlightedText ) ) ) then
			print(L["utils/debug/prefix"]..select(2, GetItemInfo( lHighlightedText ) ) )
			dna.ui.fMain:SetStatusText( select(2, GetItemInfo( lHighlightedText ) ) )
		end
	end )
	mlebCriteria:SetText( dna.ui.DB.criteria or "")

	-- The Line Numbers label
	-- https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets#title-2-10
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.labelLineNumbers = dna.lib_acegui:Create("Label")
	local labelLineNumbers = dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.labelLineNumbers
	dna.ui.sgMain.tgMain.sgPanel:AddChild( labelLineNumbers )
	labelLineNumbers:SetText( L["action/labelLineNumbers/l"] )
	labelLineNumbers:SetHeight(250)
	labelLineNumbers:SetWidth(20)
	--labelLineNumbers:SetFont("Fonts\\FRIZQT__.TTF", 14)
	labelLineNumbers:SetFontObject(ChatFontNormal)
	labelLineNumbers:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.tgCriteria.frame, "BOTTOMLEFT", 0, -20)

	-- And button
	local bCriteriaAnd = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bCriteriaAnd )
	bCriteriaAnd:SetText( L["action/bCriteriaAnd/l"] )
	bCriteriaAnd:SetWidth(85)
	bCriteriaAnd:SetPoint("TOPLEFT", mlebCriteria.frame, "BOTTOMLEFT", 65, 27);
	bCriteriaAnd:SetCallback( "OnClick", function()
		dna.ui.DB.criteria=mlebCriteria:GetText().." and \n"
		mlebCriteria:SetText( dna.ui.DB.criteria )
		dna.fActionSave()
	end )

	-- Or button
	local bCriteriaOr = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bCriteriaOr )
	bCriteriaOr:SetText( L["action/bCriteriaOr/l"] )
	bCriteriaOr:SetWidth(85)
	bCriteriaOr:SetPoint("TOPLEFT", bCriteriaAnd.frame, "TOPRIGHT", 0, 0);
	bCriteriaOr:SetCallback( "OnClick", function()
		dna.ui.DB.criteria=mlebCriteria:GetText().." or "
		mlebCriteria:SetText( dna.ui.DB.criteria )
		dna.fActionSave()
	end )

	-- Not button
	local bCriteriaNot = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bCriteriaNot )
	bCriteriaNot:SetText( L["action/bCriteriaNot/l"] )
	bCriteriaNot:SetWidth(85)
	bCriteriaNot:SetPoint("TOPLEFT", bCriteriaOr.frame, "TOPRIGHT", 0, 0);
	bCriteriaNot:SetCallback( "OnClick", function()
		dna.ui.DB.criteria=mlebCriteria:GetText().." not "
		mlebCriteria:SetText( dna.ui.DB.criteria )
		dna.fActionSave()
	end )

	-- Clear button
	local bCriteriaClear = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bCriteriaClear )
	bCriteriaClear:SetText( L["common/clear"] )
	bCriteriaClear:SetWidth(85)
	bCriteriaClear:SetPoint("TOPLEFT", bCriteriaNot.frame, "TOPRIGHT", 0, 0);
	bCriteriaClear:SetCallback( "OnClick", function()
		dna.ui.DB.criteria=""
		mlebCriteria:SetText( dna.ui.DB.criteria )
		dna.fActionSave()
	end )

	-- Information MultiLineEditBox where we display debug information
	dna.ui.sgMain.tgMain.sgPanel.mlebInfo = dna.lib_acegui:Create( "MultiLineEditBox" )
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.mlebInfo )
	local mlebInfo = dna.ui.sgMain.tgMain.sgPanel.mlebInfo
	mlebInfo:SetNumLines(22)
	mlebInfo:SetWidth(500)
	mlebInfo:SetLabel("")
	mlebInfo:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 0, 5)
	mlebInfo:SetText( "" )
	mlebInfo:SetCallback( "OnEnter", function(self)
		dna.ui.ShowTooltip(self.frame, L["action/mlebInfo/tt"], "TOPRIGHT", "TOPLEFT", 0, 0, "text")		
		dna.bPauseDebugDisplay = true
	end )
	mlebInfo:SetCallback( "OnLeave", function() dna.ui.HideTooltip(); dna.bPauseDebugDisplay = false end )
	mlebInfo:DisableButton( true )
	mlebInfo.frame:Hide()
	
	-- Debug Information CheckBox
	dna.ui.sgMain.tgMain.sgPanel.cbInfo = dna.lib_acegui:Create("CheckBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.cbInfo )
	local cbInfo = dna.ui.sgMain.tgMain.sgPanel.cbInfo
	cbInfo:SetWidth(20)
	cbInfo.Tooltip=nil
	cbInfo:SetPoint("TOPRIGHT", mlebCriteria.frame, "BOTTOMRIGHT", -20, 25);
	cbInfo:SetImage("Interface\\FriendsFrame\\InformationIcon")
	cbInfo:SetLabel( "" )
	cbInfo:SetCallback( "OnValueChanged", function(self)
		if ( self:GetValue() == true ) then	
			dna.ui.sgMain.tgMain.sgPanel.tgCriteria.frame:Hide()
			mlebInfo.frame:Show()
		else
			dna.ui.sgMain.tgMain.sgPanel.mlebInfo.frame._dna_sabframe = nil
			dna.ui.sgMain.tgMain.sgPanel.tgCriteria.frame:Show()
			mlebInfo.frame:Hide()
		end
	end )
	cbInfo:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame,  L["action/cbInfo/tt"], "BOTTOM", "TOP", 0, 0, "text") end )
	cbInfo:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Move up Action interactive label
	local ilAMoveUp = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ilAMoveUp )
	ilAMoveUp:SetWidth(40);ilAMoveUp:SetHeight(40)
	ilAMoveUp:SetImage("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonUp-Up")
	ilAMoveUp:SetImageSize(40, 40)
	ilAMoveUp:SetHighlight("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonUp-Highlight")
	ilAMoveUp:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", -7, -560);
	ilAMoveUp:SetCallback( "OnClick", function() dna.ui.bMoveAction(-1) end )
	ilAMoveUp:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["action/ilAMoveUp/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	ilAMoveUp:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Move down Action interactive label
	local ilAMoveDown = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ilAMoveDown )
	ilAMoveDown:SetWidth(40);ilAMoveDown:SetHeight(40)
	ilAMoveDown:SetImage("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonDown-Up")
	ilAMoveDown:SetImageSize(40, 40)
	ilAMoveDown:SetHighlight("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonDown-Highlight")
	ilAMoveDown:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", -7, -585);
	ilAMoveDown:SetCallback( "OnClick", function() dna.ui.bMoveAction(1) end )
	ilAMoveDown:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["action/ilAMoveDown/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	ilAMoveDown:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Keybind
	-- local bActionKeybind = dna.lib_acegui:Create("Keybinding")
	-- dna.ui.sgMain.tgMain.sgPanel:AddChild( bActionKeybind )
	-- bActionKeybind:SetWidth(100)
	-- bActionKeybind:SetLabel(L["common/hotkey/l"])
	-- bActionKeybind:SetPoint("TOPLEFT", ilAMoveDown.frame, "TOPRIGHT", 0, 10);
	-- bActionKeybind:SetCallback( "OnKeyChanged", function(self)
		-- if ( InCombatLockdown() ) then dna.ui.fMain:SetStatusText( L["common/error/keybindincombat"] )	end
		-- dna.ui.DB.hk = self:GetKey();
		-- dna.AButtons.bInitComplete = false;
		-- self:SetKey( dna.ui.DB.hk or L["action/bActionKeybind/blizzard"])
	-- end )
	-- bActionKeybind:SetKey( dna.ui.DB.hk or L["action/bActionKeybind/blizzard"] )
	-- bActionKeybind.label:SetPoint("TOPLEFT", bActionKeybind.frame, "TOPLEFT", -40, 0);

	-- Delete Action button
	local bActionDelete = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bActionDelete )
	bActionDelete:SetWidth(100)
	bActionDelete:SetText(L["common/delete"])
	bActionDelete:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 40, -590);
	bActionDelete:SetCallback( "OnClick", dna.ui.bActionDeleteOnClick )
	bActionDelete:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["action/bActionDelete/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	bActionDelete:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Rename Action edit box
	local ebRenameAction = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebRenameAction )
	ebRenameAction:SetLabel( L["action/ebRenameAction/l"] )
	ebRenameAction:SetWidth(160)
	ebRenameAction:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 200, -570);
	ebRenameAction:SetCallback( "OnEnterPressed", dna.ui.ebRenameActionOnEnterPressed )
	ebRenameAction:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["action/ebRenameAction/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebRenameAction:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	ebRenameAction:SetText( dna.ui.DB.text )

end
--Action Panel Callbacks-------------------------------
function dna.CreateCriteriaPanel(...)
	local args = {...}
	if ( not dna.ui.sgMain.tgMain.sgPanel.tgCriteria ) then return end
	for argi=1,dna.D.criteria[args[1]].a do									--Build the criteria options based on dna.D.criteria
		dna.ui["ebArg"..argi] = dna.lib_acegui:Create("EditBox")
		dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel:AddChild( dna.ui["ebArg"..argi] )
		dna.ui["ebArg"..argi]:SetFullWidth(true)
		dna.ui["ebArg"..argi]:SetLabel( dna.D.criteria[args[1]]["a"..argi.."l"] or L["action/ebArg/l"]..argi )
		dna.ui["ebArg"..argi]:SetText( dna.D.criteria[args[1]]["a"..argi.."dv"] or "" )
		dna.ui["ebArg"..argi]:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, dna.D.criteria[args[1]]["a"..argi.."tt"], "BOTTOMLEFT", "TOPRIGHT", 0, 0, "text") end )
		dna.ui["ebArg"..argi]:SetCallback( "OnLeave", dna.ui.HideTooltip )
		dna.ui["ebArg"..argi]:DisableButton(true)
	end
	-- Add Criteria button
	local bCriteriaAdd = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel:AddChild( bCriteriaAdd )
	bCriteriaAdd:SetText( L["action/bCriteriaAdd/l"] )
	bCriteriaAdd:SetFullWidth(true)
	bCriteriaAdd:SetPoint("BOTTOMRIGHT", dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.frame, "BOTTOMRIGHT", 0, 0);
	bCriteriaAdd:SetCallback( "OnClick", function() dna.ui.CriteriaAddOnClick(args[1]) end )
end

function dna.ui.CriteriaAddOnClick(criteriakey)
	local lCriteria = dna.D.criteria[criteriakey].f() or ""
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.mlebCriteria:SetText( (dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.mlebCriteria:GetText() or "")..lCriteria )
	dna.ui.DB.criteria = (dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel.mlebCriteria:GetText() or "")
	
	dna.fActionSave()
	
	
	-- dna.AButtons.bInitComplete = false										-- Criteria Add was clicked need initialization to create new criteria function
end
function dna.ui.tgCriteriaOnGroupSelected(...)
	local args = {...}
	args[1]:RefreshTree()														--Refresh the tree so .selected gets updated
	dna.ui.sgMain.tgMain.sgPanel.tgCriteria.sgCriteriaPanel:ReleaseChildren()	--Clears the right panel in the criteria tree
	dna.ui.SelectedCriteriaTreeButton=nil										--Save the selected criteria for global scope
	for k,v in pairs(args[1].buttons) do
		if ( v.selected ) then dna.ui.SelectedCriteriaTreeButton = v end
	end
	if( not dna.ui.SelectedCriteriaTreeButton ) then
		--dna:dprint("Error: tgCriteriaOnGroupSelected called without a button selection")
	else
		local func, errorMessage = loadstring(dna.ui.SelectedCriteriaTreeButton.value)	-- Use the .value field to create a function specific to the button
		if( not func ) then	dna:dprint("Error: tgCriteriaOnGroupSelected loadingstring:"..dna.ui.SelectedCriteriaTreeButton.value.." Error:"..errorMessage) return end
		local success, errorMessage = pcall(func);								-- Call the button specific function we loaded
		if( not success ) then
			print(L["utils/debug/prefix"].."Error criteria pcall:"..errorMessage)
		end
	end
end
function dna.ui.mlebActionTypeAttOnTextChanged(...)
	local args = {...}
	if ( not dna.IsBlank( args[1] ) and args[1]=="spell" ) then
		local spellID = dna.GetSpellID( args[3] )
		dna.ui.sgMain.tgMain.sgPanel.ilAtt2Link:SetText( (GetSpellLink( spellID ) or "")..' '..(spellID or "") )
		dna.ui.sgMain.tgMain.sgPanel.ilAtt2Link.Tooltip = GetSpellLink( spellID )
	end
	if ( not dna.IsBlank( args[1] ) and args[1]=="macrotext" ) then
		local spellID = dna.GetSpellID( dna.ui:GetMacrotextTooltip( args[2] ) )
		dna.ui.sgMain.tgMain.sgPanel.ilAtt2Link:SetText( (GetSpellLink( spellID ) or "")..' '..(spellID or "") )
		dna.ui.sgMain.tgMain.sgPanel.ilAtt2Link.Tooltip = GetSpellLink( spellID )
	end
	if ( not dna.IsBlank( args[1] ) and args[1]=="item" ) then
		local itemID = dna.GetItemId( args[2] )
		if ( itemID ) then
			dna.ui.sgMain.tgMain.sgPanel.ilAtt2Link:SetText( (select(2,GetItemInfo( itemID )) or "")..' '..(itemID or "") )
			dna.ui.sgMain.tgMain.sgPanel.ilAtt2Link.Tooltip = select(2,GetItemInfo( itemID ))
		end
	end
end
function dna.ui.SetMultiActionValue( key, value)
	for atk, action in pairs( dna.D.RTMC[dna.ui.STL[2]].children ) do
		action[key] = value
	end
end
function dna.ui.bActionDeleteOnClick(...)
	if ( InCombatLockdown() ) then dna.ui.fMain:SetStatusText( L["common/error/deleteincombat"] ) return end
	dna.ui.fMain:SetStatusText( '' )
	local deleteAKey    = dna.ui.STL[3]

	dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..dna.D.RTMC[dna.ui.STL[2]].value)	-- Select parent tree before deleting so table does not get messed up

	tremove(dna.D.RTMC[dna.ui.STL[2]].children, deleteAKey)
	dna.ui.sgMain.tgMain:RefreshTree() 										-- Gets rid of the action from the tree
	dna.ui.sgMain.tgMain.sgPanel:ReleaseChildren() 							-- clears the right panel

	dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..dna.D.RTMC[dna.ui.STL[2]].value)
end
function dna.ui.bMoveAction(movevalue)
	if ( InCombatLockdown() ) then dna.ui.fMain:SetStatusText( L["common/error/priorityincombat"] ) return end	
	local SavedAction	= dna:CopyTable(dna.ui.DB)							-- Deepcopy the action from the db

	local maxKey		= #(dna.D.RTMC[dna.ui.STL[2]].children)
	tremove(dna.D.RTMC[dna.ui.STL[2]].children, dna.ui.STL[3])
	
	dna.ui.sgMain.tgMain:RefreshTree() 										-- Gets rid of the action from the tree
	dna.ui.sgMain.tgMain.sgPanel:ReleaseChildren() 							-- clears the right panel
	
	
	dna.ui.STL[3] = dna.ui.STL[3]+movevalue									-- Now change the key value to up or down
	if ( dna.ui.STL[3] < 1) then dna.ui.STL[3] = 1 end
	if ( dna.ui.STL[3] > maxKey ) then dna.ui.STL[3] = maxKey end
	tinsert(dna.D.RTMC[dna.ui.STL[2]].children, (dna.ui.STL[3]), SavedAction)
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..dna.D.RTMC[dna.ui.STL[2]].value.."\001"..dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].value)

end
function dna.ui.ebRenameActionOnEnterPressed(...)
	local args = {...}
	if ( dna.ui.EntryHasErrors( args[3] ) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], args[3]) )
		return
	end
	local NewActionText = args[3]
	local NewActionValue = 'dna.ui:CAP([=['..NewActionText..']=])'

	if ( dna:SearchTable(dna.D.RTMC[dna.ui.STL[2]].children, "text", NewActionText) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], NewActionText) )
	else
		dna.ui.fMain:SetStatusText( "" ) 											-- Clear any previous errors
		dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].text = NewActionText
		dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].value = NewActionValue
		dna.ui.sgMain.tgMain:RefreshTree() 									-- Refresh the tree
		dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..dna.D.RTMC[dna.ui.STL[2]].value.."\001"..dna.D.RTMC[dna.ui.STL[2]].children[dna.ui.STL[3]].value)

	end
end

