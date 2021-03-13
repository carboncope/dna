local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--*****************************************************
--Rotation Utility functions
--*****************************************************
function dna.ui.SelectRotation(rotationname, bQuiet)
	local lRotationKey = dna:SearchTable(dna.D.RTMC, "text", rotationname)
	if ( lRotationKey ) then
		dna.D.OTM[dna.D.PClass].selectedrotationkey = lRotationKey	--srk=selected rotation key
		dna.D.OTM[dna.D.PClass].selectedrotation  = rotationname	--sr=selected rotation
		
		dna.nSelectedRotationTableIndex = lRotationKey
		
		dna.ui.fUpdateMenuText()
		if ( not bQuiet ) then print(L["utils/debug/prefix"]..format(L["rotations/selected"], rotationname)) end
		
		-- set all the toggles off
		if dna.txtToggle then
			for nToggleId, tEntry in pairs(dna.txtToggle) do
				dna.txtToggle[nToggleId]:SetAlpha(0)
				dna.bToggle[nToggleId] = false
			end
		end
		
		-- time stamp the rotation switch
		dna.last_rotation_switch_timestamp = GetTime()
        
        dna.ui.fUpdateMenuText()

	end
end

function dna:SetRotationForCurrentSpec()
	local nSpecialization = GetSpecialization()
	if ( nSpecialization and nSpecialization > 0 ) then
		for rtk,rotation in pairs(dna.D.RTMC) do
			if ( rotation.nSpecialization == nSpecialization and rotation.strClass == dna.D.PClass ) then 
				dna.ui.SelectRotation( rotation.text, false )
				return
			end
		end
	end
end

function dna.fGetRotationExport()
	local tExport = {}
	tExport.data = {}
	tExport.strType = "rotation"
	tExport.data = dna:CopyTable( dna.D.RTMC[dna.ui.STL[2]] )

	-- Loop through the actions and remove the .fFunction because ace serializer cannot handle them
	for nActionKey, tAction in pairs(tExport.data.children) do		
		tAction.fCriteria = nil
	end
	strExport = dna.Serialize(tExport)
	return strExport
end

function dna.fRotationImport( strRotationText )
	local tImportedData = dna.DeserializeString( strRotationText ) 
	-- dna:dprint( tostring(tImportedData) )
	-- dna:dprint("   tImportedData.strType="..tostring(tImportedData['strType']))
	if tImportedData.strType == 'rotation' then
		-- dna:dprint("    tImportedData.strType is rotation")
		tImportedData.data.text = 'ImportedRotation'
		-- We have to set the .value so the tree selects properly
		tImportedData.data.value = 'dna.SetRotationPanel([=['..tImportedData.data.text..']=])'
		tImportedData.data.strClass = dna.D.PClass
		tImportedData.data.nSpecialization = ""
		
		-- Check if the ImportedRotation exists already
		local nImportedRotationIndex = dna:SearchTable(dna.D.RTMC, "text", tImportedData.data.text)
		if not dna.IsBlank(nImportedRotationIndex) then
			-- dna:dprint( "rotation already existing nImportedRotationIndex="..tostring(nImportedRotationIndex) )
			dna.D.RTMC[nImportedRotationIndex] =  dna:CopyTable(tImportedData.data)
		else
			-- dna:dprint( "rotation is new nImportedRotationIndex="..tostring(nImportedRotationIndex) )
			table.insert(dna.D.RTMC, tImportedData.data)
		end
		dna.fLoadCriteriaStrings()
		if ( dna.ui.sgMain ) then dna.ui.sgMain.tgMain:RefreshTree() end
	end
end

function dna.AddRotation( RotationName, ShowError, nSpecialization )
	if ( dna.ui.EntryHasErrors( RotationName ) ) then
		if ( dna.ui.sgMain and ShowError ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], RotationName) ) end
		return nil
	end
	if ( dna.IsNumeric(RotationName) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/numbers"], RotationName) )
		return
	end
	
	local lRotationExists   = dna:SearchTable(dna.D.RTMC, "text", RotationName)
	local lNewRotationValue = 'dna.SetRotationPanel([=['..RotationName..']=])'
	local lNewRotationText  = RotationName
	if ( dna.D.UpdateMode==0 and lRotationExists ) then
		local iSuffix = 0
		lNewRotationText = lNewRotationText..'_'
		while lRotationExists do
			iSuffix = iSuffix+1
			lRotationExists = dna:SearchTable(dna.D.RTMC, "text", lNewRotationText..iSuffix)
		end
		lNewRotationValue = 'dna.SetRotationPanel([=['..lNewRotationText..iSuffix..']=])'
		lNewRotationText = lNewRotationText..iSuffix
	end
	dna.D.ImportName = lNewRotationText
	local lNewRotation = {
        value = lNewRotationValue,
        text = lNewRotationText,
        icon="Interface\\PaperDollInfoFrame\\UI-GearManager-Undo",
        children = {},
        nSpecialization = "",
        strClass = dna.D.PClass,
		equipmentset = "",
    }
	lRotationExists = dna:SearchTable(dna.D.RTMC, "text", lNewRotationText)
	if ( lRotationExists ) then
		if ( dna.ui.sgMain and ShowError ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], lNewRotationText) ) end
	else
		table.insert( dna.D.RTMC, lNewRotation)
		if ( dna.ui.sgMain ) then dna.ui.fMain:SetStatusText( '' ) end -- Clear any previous errors
		lRotationExists = dna:SearchTable(dna.D.RTMC, "text", lNewRotationText)
	end
	lRotationExists = dna:SearchTable(dna.D.RTMC, "text", lNewRotationText)
	if ( lRotationExists ) then 
		local RotationDB = dna.D.RTMC[lRotationExists]
		if ( not dna.IsBlank(nSpecialization) ) then
            RotationDB.nSpecialization = nSpecialization
        end
	end
	if ( dna.ui.sgMain ) then dna.ui.sgMain.tgMain:RefreshTree() end	
	-- dna.AButtons.bInitComplete = false	-- Rotation was added
	return lNewRotationText, lRotationExists
end

function dna.DeleteRotation( RotationName )
	if ( InCombatLockdown() ) then print(L["utils/debug/prefix"]..L["common/error/deleteincombat"]); return end
	if ( dna.ui.fMain ) then dna.ui.fMain:SetStatusText( '' ) end

	local DeleteKey				= nil
	local DeleteKeyText			= nil
	local bHideGUI      		= true

	if ( dna.IsBlank(RotationName) ) then
		bHideGUI  = false
		DeleteKey = dna.ui.STL[2]

	else
		DeleteKey = dna:SearchTable(dna.D.RTMC, "text", RotationName)
	end
	if ( DeleteKey ) then
		DeleteKeyText = dna.D.RTMC[DeleteKey].text

		tremove(dna.D.RTMC, DeleteKey)
		if ( dna.D.OTM[dna.D.PClass].selectedrotation == DeleteKeyText ) then
			dna.D.OTM[dna.D.PClass].selectedrotationkey = nil
			dna.D.OTM[dna.D.PClass].selectedrotation  = nil
		end
		if ( dna.ui.fMain and bHideGUI ) then dna.ui.fMain:Hide() end					-- Hide the main gui if deleting from localization file
		-- dna.AButtons.bInitComplete = false												-- Rotation was deleted
		dna.ui.HideTooltip()
		if ( dna.ui.sgMain ) then
			dna.ui.sgMain.tgMain:RefreshTree() 										-- Gets rid of the rotation from the tree
			dna.ui.sgMain.tgMain.sgPanel:ReleaseChildren() 							-- clears the right panel
			dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value)
		end
		if (dna.D.LDB) then															-- cleanup lib data broker text
			if ( not dna.IsBlank(dna.D.OTM[dna.D.PClass].selectedrotation) ) then
				dna.D.LDB.text = L["common/dna"].." "..tostring( dna.D.OTM[dna.D.PClass].selectedrotation or "" )
			else
				dna.D.LDB.text = L["common/dna"]
			end
		end
	end
end
--*****************************************************
--Rotations Panel
--*****************************************************
function dna.CreateRotationsPanel()
	-- Pause or resume the rightsgPanel fill layout if you need it or not
	dna.ui.sgMain.tgMain.sgPanel:PauseLayout()
	-- new rotation name edit box
	dna.ui.sgMain.tgMain.sgPanel.ebRotationName = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.ebRotationName )
	dna.ui.sgMain.tgMain.sgPanel.ebRotationName:SetLabel( L["rotations/ebRotationName/l"] )
	dna.ui.sgMain.tgMain.sgPanel.ebRotationName:SetWidth(480)
	dna.ui.sgMain.tgMain.sgPanel.ebRotationName:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 5, 0);
	dna.ui.sgMain.tgMain.sgPanel.ebRotationName:SetCallback( "OnEnterPressed", function(self)
		dna.AddRotation( self:GetText(), true )
	end )

	-- Rotation Import edit box
	local mlebRotationImport = dna.lib_acegui:Create("MultiLineEditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( mlebRotationImport )
	mlebRotationImport:SetLabel( L["rotations/mlebRotationImport/l"] )
	mlebRotationImport:SetWidth(480)
	mlebRotationImport:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.ebRotationName.frame, "BOTTOMLEFT", 0, 0)
	mlebRotationImport:SetCallback( "OnEnterPressed", function(self)
		dna.fRotationImport( self:GetText() )
	 end )

	dna.ui.sgMain.tgMain.sgPanel:ResumeLayout()
end
--Rotations Panel Callbacks----------------------------

--[[
function dna.ui.RotationImport( ImportString, ShowErrors )
	local success, iString
	
	if ( strfind( ImportString, "actions%+%=") or strfind( ImportString, "actions%=") ) then
		if ( IsShiftKeyDown() ) then
			-- Adding this in for legacy purposes until new simcraft parser works again
			-- This will let me deploy rotation fixes while we work on LSP at same time
			print(L["utils/debug/prefix"]..'Alternate import' )
			success, iString = dna:Deserialize( dna_UI_ParseSimcraftRotation_Old( ImportString ) )
		else
			success, iString = dna:Deserialize( dna.ui.ParseSimcraftRotation( ImportString ) )
		end
	

	elseif ( strfind( ImportString, '~Jdna') ) then
		success, iString = dna:Deserialize( ImportString )	-- serialized import detected need to deserialize
	else
		ImportString = string.gsub(ImportString, "\10", "\n")	-- script import
		ImportString = dna:Serialize( ImportString )  -- Serialize the import string to preserve spaces and new lines
		success, iString = dna:Deserialize( ImportString )		
	end	
	
	if ( not success or dna.IsBlank( iString ) or type(iString) == "table" ) then
		if ( dna.ui.fMain and dna.ui.fMain:IsShown() and ShowErrors ) then dna.ui.fMain:SetStatusText( L["rotations/rimportfail"]..':E1' ) end
		if ( ShowErrors ) then print(L["utils/debug/prefix"]..L["rotations/rimportfail"]..':E1' ) end
		return
	end
	
-- dna:dprint("calling import on ==========================\n"..tostring(iString))
	--pcall stuff
	if ( dna.D.RunCode( iString, L["utils/debug/prefix"]..L["rotations/rimportfail"]..':E2', L["utils/debug/prefix"].."Error import pcall:", true, true  ) == 0 ) then
		if ( dna.ui.fMain and dna.ui.fMain:IsShown() ) then
			if ( dna.D.ImportType and dna.D.ImportType == 'actionpack' ) then
				dna.ui.fMain:SetStatusText( L["rotation/actionpackimportsuccess"]..(dna.D.ImportName or "") )
			else
				dna.ui.fMain:SetStatusText( L["rotations/importsuccess"]..(dna.D.ImportName or "") )
			end
		end
	end
	
	-- local func, errorMessage = loadstring(iString)
	-- if( not func and ShowErrors ) then
		-- print(L["utils/debug/prefix"]..L["rotations/rimportfail"]..':E2' )
		-- dna:dprint(tostring(errorMessage))
		-- if ( dna.ui.fMain and dna.ui.fMain:IsShown() ) then dna.ui.fMain:SetStatusText( L["rotations/rimportfail"]..':E2:' ) end
		-- return
	-- end
	
	-- success, errorMessage = pcall(func);								-- Call the button specific function we loaded
	-- if( not success ) then
		-- print(L["utils/debug/prefix"].."Error import pcall:"..errorMessage)
	-- end


end
--]]
--*****************************************************
--Specific Rotation Panel
--*****************************************************
function dna.SetRotationPanel(RotationName)
	dna.ui.DB = {}
	dna.ui.DB = dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]]
	dna.ui.SelectRotation(dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].text, true)
	-- Pause or resume the rightsgPanel fill layout if you need it or not
	dna.ui.sgMain.tgMain.sgPanel:PauseLayout()
	-- dna.AButtons.bInitComplete = false	-- Rotation Panel gui was opened

	-- Rename Rotation edit box
	local ebRenameRotation = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebRenameRotation )
	ebRenameRotation:SetLabel( L["rotation/ebRenameRotation/l"] )
	ebRenameRotation:SetWidth(480)
	ebRenameRotation:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 0, 0)
	ebRenameRotation:SetCallback( "OnEnterPressed", dna.ui.ebRenameRotationOnEnterPressed )
	ebRenameRotation:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebRenameRotation/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebRenameRotation:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	ebRenameRotation:SetText( dna.ui.DB.text )

	-- New Action edit box
	local ebActionName = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebActionName )
	ebActionName:SetLabel( L["rotation/ebActionName/l"] )
	ebActionName:SetWidth(480)
	ebActionName:SetPoint("TOPLEFT", ebRenameRotation.frame, "BOTTOMLEFT", 0, 0)
	ebActionName:SetCallback( "OnEnterPressed", dna.ui.ebActionNameOnEnterPressed )
	ebActionName:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebActionName/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebActionName:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Copy Rotation edit box
	local ebCopyRotation = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebCopyRotation )
	ebCopyRotation:SetLabel( L["rotation/ebCopyRotation/l"] )
	ebCopyRotation:SetWidth(480)
	ebCopyRotation:SetPoint("TOPLEFT", ebActionName.frame, "BOTTOMLEFT", 0, 0);
	ebCopyRotation:SetCallback( "OnEnterPressed", dna.ui.ebCopyRotationOnEnterPressed )
	ebCopyRotation:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebCopyRotation/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebCopyRotation:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Rotation export
	local ebRotationExport = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebRotationExport )
	ebRotationExport:SetLabel( L["rotation/ebRotationExport/l"] )
	ebRotationExport:SetWidth(480)
	ebRotationExport:SetPoint("TOPLEFT", ebCopyRotation.frame, "BOTTOMLEFT", 0, 0)
	ebRotationExport:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebRotationExport/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebRotationExport:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Export button
	local bExport = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bExport )
	bExport:SetText( L["rotation/bExport/l"] )
	bExport:SetWidth(100)
	bExport:SetPoint("TOPLEFT", ebRotationExport.frame, "BOTTOMLEFT", 0, 0);
	bExport:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/bExport/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 0, "text") end )
	bExport:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	bExport:SetCallback( "OnClick", function()
		local strExport = dna.fGetRotationExport()
		ebRotationExport:SetText( strExport )
		ebRotationExport.editbox:SetFocus(0)
		ebRotationExport.editbox:SetCursorPosition(0)
		ebRotationExport.editbox:HighlightText()
	end )

	local ebShareExport = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebShareExport )
	ebShareExport:SetLabel( L["rotation/ebShareExport/l"] )
	ebShareExport:SetWidth(480)
	ebShareExport:SetPoint("TOPLEFT", bExport.frame, "BOTTOMLEFT", 0,0)
	ebShareExport:SetCallback( "OnEnterPressed", function(self)
		local strExport = dna.fGetRotationExport()
		if ( not dna.IsBlank( strExport ) and not dna.IsBlank( self:GetText() ) ) then
			dna:SendCommMessage(dna.D.Prefix, strExport, 'WHISPER', self:GetText())
		end
	end )
	ebShareExport:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebShareExport/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebShareExport:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Bind to spec Dropdown
	dna.ui.sgMain.tgMain.sgPanel.ddBindToSpec = dna.lib_acegui:Create("Dropdown")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.ddBindToSpec )
	local ddBindToSpec = dna.ui.sgMain.tgMain.sgPanel.ddBindToSpec
	ddBindToSpec:SetList( dna.ui.ddBindToSpecGetList() )
	ddBindToSpec:SetLabel( L["rotation/ddBindToSpec/l"] )
	ddBindToSpec:SetWidth(480)
	ddBindToSpec:SetPoint("TOPLEFT", ebShareExport.frame, "BOTTOMLEFT", 0, 0)
	ddBindToSpec:SetCallback( "OnValueChanged", function(self)
		dna.ui.DB.nSpecialization = self:GetValue()
	end )
	ddBindToSpec:SetCallback( "OnEnter", function(self)
		dna.ui.ShowTooltip(self.frame, L["rotation/ddBindToSpec/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 0, "text")
	end )
	ddBindToSpec:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	ddBindToSpec:SetValue( dna.ui.DB.nSpecialization or nil )
  
    -- Melee spell
	local ebMeleeSpell = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebMeleeSpell )
	ebMeleeSpell:SetLabel( L["rotation/ebMeleeSpell/l"] )
	ebMeleeSpell:SetWidth(480)
	ebMeleeSpell:SetPoint("TOPLEFT", ddBindToSpec.frame, "BOTTOMLEFT", 0,0)
	ebMeleeSpell:SetCallback( "OnEnterPressed", function(self)
		if ( not dna.IsBlank( self:GetText() ) ) then
            dna.ui.DB.meleespell = self:GetText()
		end
	end )
	ebMeleeSpell:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebMeleeSpell/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebMeleeSpell:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
    ebMeleeSpell:SetText( dna.ui.DB.meleespell )

    -- Range spell
	local ebRangeSpell = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebRangeSpell )
	ebRangeSpell:SetLabel( L["rotation/ebRangeSpell/l"] )
	ebRangeSpell:SetWidth(480)
	ebRangeSpell:SetPoint("TOPLEFT", ebMeleeSpell.frame, "BOTTOMLEFT", 0,0)
	ebRangeSpell:SetCallback( "OnEnterPressed", function(self)
		if ( not dna.IsBlank( self:GetText() ) ) then
            dna.ui.DB.rangespell = self:GetText()
		end
	end )
	ebRangeSpell:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ebRangeSpell/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebRangeSpell:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
    ebRangeSpell:SetText( dna.ui.DB.rangespell )

	-- Move up Rotation interactive label
	local ilRMoveUp = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ilRMoveUp )
	ilRMoveUp:SetWidth(40);ilRMoveUp:SetHeight(40)
	ilRMoveUp:SetImage("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonUp-Up")
	ilRMoveUp:SetImageSize(40, 40)
	ilRMoveUp:SetHighlight("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonUp-Highlight")
	ilRMoveUp:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", -5, -545);
	ilRMoveUp:SetCallback( "OnClick", function() dna.ui.bMoveRotation(-1) end )
	ilRMoveUp:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ilRMoveUp/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	ilRMoveUp:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Move down Rotation interactive label
	local ilRMoveDown = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ilRMoveDown )
	ilRMoveDown:SetWidth(40);ilRMoveDown:SetHeight(40)
	ilRMoveDown:SetImage("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonDown-Up")
	ilRMoveDown:SetImageSize(40, 40)
	ilRMoveDown:SetHighlight("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonDown-Highlight")
	ilRMoveDown:SetPoint("TOPLEFT", ilRMoveUp.frame, "BOTTOMLEFT", 0, 5);
	ilRMoveDown:SetCallback( "OnClick", function() dna.ui.bMoveRotation(1) end )
	ilRMoveDown:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/ilRMoveDown/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	ilRMoveDown:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Delete Rotation button
	local bRotationDelete = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bRotationDelete )
	bRotationDelete:SetWidth(100)
	bRotationDelete:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 100, -555)
	-- bRotationDelete:SetPoint("TOPLEFT", bRotationKeybind.frame, "TOPRIGHT", 0, -20);
	bRotationDelete:SetText(L["common/delete"])
	bRotationDelete:SetCallback( "OnClick", function() dna.DeleteRotation() end )
	bRotationDelete:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["rotation/bRotationDelete/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	bRotationDelete:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	dna.ui.sgMain.tgMain.sgPanel:ResumeLayout()
end
--Rotation Panel Callbacks-----------------------------
function dna.ui.ebRenameRotationOnEnterPressed(...)
	local args = {...}
	if ( dna.ui.EntryHasErrors( args[3] ) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], args[3]) )
		return
	end
	if ( dna.IsNumeric(args[3]) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/numbers"], args[3]) )
		return
	end
	
	
	local NewRotationText = args[3]
	local NewRotationValue = 'dna.SetRotationPanel([=['..args[3]..']=])'
	if ( dna:SearchTable(dna.D.RTMC, "text", args[3]) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], args[3]) )
	else
		dna.ui.fMain:SetStatusText( "" ) 										-- Clear any previous errors
		dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].text = NewRotationText
		dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].value = NewRotationValue
		dna.ui.sgMain.tgMain:RefreshTree() 									-- Refresh the tree
		-- dna.AButtons.bInitComplete = false										-- Rotation was renamed
		dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..NewRotationValue)
	end
end
function dna.ui.ebActionNameOnEnterPressed(...)
	local lNewActionName = select(3, ...)
	dna.D.ImportName = dna.D.RTMC[dna.ui.STL[2]].text
	dna.D.ImportType = 'rotation'
	local _,lNewActionKey = dna.AddAction( lNewActionName, true )
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..dna.D.RTMC[dna.ui.STL[2]].value.."\001"..dna.D.RTMC[dna.ui.STL[2]].children[lNewActionKey].value)
end
function dna.ui.ebCopyRotationOnEnterPressed(...)
	local args = {...}
	if ( dna.ui.EntryHasErrors( args[3] ) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], args[3]) )
		return
	end
	if ( dna.IsNumeric(args[3]) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/numbers"], args[3]) )
		return
	end
	
	if ( dna:SearchTable(dna.D.RTMC, "text", args[3]) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], args[3]) )
	else
		dna.ui.fMain:SetStatusText( "" )
		local NewRotation = dna:CopyTable( dna.D.RTMC[dna.ui.STL[2]] )
		NewRotation.text = args[3]
		NewRotation.value = 'dna.SetRotationPanel([=['..args[3]..']=])'
		table.insert( dna.D.RTMC, NewRotation)
		dna.ui.sgMain.tgMain:RefreshTree() 									-- Gets rid of the action from the tree
		-- dna.AButtons.bInitComplete = false										-- Rotation was copied
	end
end

function dna.ui.ebShareExportOnEnterPressed( self )

	local strExport = dna.fGetRotationExport()

	
	local lExport = dna.ui.RotationExport(false)
	if ( not dna.IsBlank( lExport ) and not dna.IsBlank( self:GetText() ) ) then
		dna:SendCommMessage(dna.D.Prefix, lExport, 'WHISPER', self:GetText())
	end
end

function dna.ui.ddBindToSpecGetList()
	dna.D.Specs = {}
	for specID = 1, (GetNumSpecializations()+1) do
		local id, name, description, icon, background, role = GetSpecializationInfo(specID)
		if not dna.IsBlank(name) then
			dna.D.Specs[specID] = name
		else
			dna.D.Specs[specID]=L["common/none"]
		end
	end

	return dna.D.Specs
end

function dna.ui.bMoveRotation(movevalue)
	local SavedRotation	= dna:CopyTable(dna.ui.DB)									-- Deepcopy the action from the db
	local maxKey		= #(dna.D.RTMC)
	tremove(dna.D.RTMC, dna.ui.STL[2])
	dna.ui.STL[2] = dna.ui.STL[2]+movevalue											-- Now change the key value to up or down
	if ( dna.ui.STL[2] < 1) then dna.ui.STL[2] = 1 end
	if ( dna.ui.STL[2] > maxKey ) then dna.ui.STL[2] = maxKey end
	tinsert(dna.D.RTMC, dna.ui.STL[2], SavedRotation)
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.RTM.value.."\001"..dna.D.RTMC[dna.ui.STL[2]].value)
	-- dna.AButtons.bInitComplete = false												-- Rotation was moved in tree
end

