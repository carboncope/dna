local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--*****************************************************
--Lists Utility functions
--*****************************************************
function dna.AddList( ListName, ForceRename, ShowError )
	if ( dna.ui.EntryHasErrors( ListName ) ) then
		if ( dna.ui.sgMain and ShowError ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], ListName) ) end
		return nil
	end
	local lListExists   = dna:SearchTable(dna.D.LTMC, "text", ListName)
	local lNewListValue = 'dna.CreateListPanel([=['..ListName..']=])'
	local lNewListText  = ListName
	if ( ForceRename and lListExists ) then
		local iSuffix = 0
		lNewListText = lNewListText..'_'
		while lListExists do
			iSuffix = iSuffix+1
			lListExists = dna:SearchTable(dna.D.LTMC, "text", lNewListText..iSuffix)
		end
		lNewListValue = 'dna.CreateListPanel([=['..lNewListText..iSuffix..']=])'
		lNewListText = lNewListText..iSuffix
	end
	local tNewList = {
        value = lNewListValue,
        text = lNewListText,
        treeList={},
        entries={},
    }
	if ( dna:SearchTable(dna.D.LTMC, "text", lNewListText) ) then
		if ( dna.ui.sgMain and ShowError == true ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], lNewListText) ) end
	else
		table.insert( dna.D.LTMC, tNewList)
		if ( dna.ui.sgMain ) then
			dna.ui.fMain:SetStatusText( '' )-- Clear any previous errors
		end
		lListExists = dna:SearchTable(dna.D.LTMC, "text", lNewListText)
	end
	if ( dna.ui.sgMain ) then dna.ui.sgMain.tgMain:RefreshTree() end
	-- dna.AButtons.bInitComplete = false		-- List was added
	return lNewListText, lListExists
end
function dna.AddListEntry( ListName, ShowError, ID, Type )
	if ( dna.ui.EntryHasErrors( ListName ) ) then
		if ( dna.ui.sgMain ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], ListName) ) end
		return
	end
	-- Create the list if needed
	local _, nListKey = dna.AddList( ListName, false, false )

    -- Create the list entry
	local lNewEntryValue = 'dna.ui.CreateListEntryPanel("'..ID..'","'..Type..'")'
	local strNewEntryText  = ''
	if ( Type == 's' ) then
		strNewEntryText = dna.GetSpellName(ID)
	elseif ( Type == 'i' ) then
		strNewEntryText = dna.GetItemName(ID)
	end
	local tNewEntry = { value = lNewEntryValue, text = strNewEntryText, entryType = Type}
    
    -- Check if entry exists
    local bDuplicateEntry = dna.D.LTMC[nListKey].entries[strNewEntryText]	
	if ( bDuplicateEntry ) then
		if ( dna.ui.sgMain and ShowError ) then dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], strNewEntryText) ) end
	else
		if ( dna.ui.sgMain ) then dna.ui.fMain:SetStatusText( '' ) end -- Clear any previous errors
        
		table.insert( dna.D.LTMC[nListKey].treeList, tNewEntry) -- Insert into the List Tree Main Children for user visibility
        dna.D.LTMC[nListKey].entries[strNewEntryText]=true -- Insert into the List Tree Main Children entries for fast lookup
	end
	nNewEntryKey= dna:SearchTable(dna.D.LTMC[nListKey].treeList, "value", 'dna.ui.CreateListEntryPanel("'..ID..'","'..Type..'")')
	if ( dna.ui.sgMain ) then dna.ui.sgMain.tgMain:RefreshTree() end
	return strNewEntryText, nNewEntryKey
end
function dna.GetListEntryExportString( ListKey, EntryKey )
	local EntryDB = dna.D.LTMC[ListKey].treeList[EntryKey]
	local lID, lType = strmatch( EntryDB.value, 'CreateListEntryPanel%("([^"]+)","(%a)"%)' )
	return 'dna.AddListEntry([=['..dna.D.LTMC[ListKey].text..']=],false,"'..lID..'","'..lType..'");'.."\n"
end
--*****************************************************
--Lists Panel
--*****************************************************
function dna.CreateListsPanel()
	-- Pause or resume the rightsgPanel fill layout if you need it or not
	dna.ui.sgMain.tgMain.sgPanel:PauseLayout()

	-- new list name edit box
	local ebListName = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebListName )
	ebListName:SetLabel( L["lists/ebListName/l"] )
	ebListName:SetWidth(480)
	ebListName:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 5, 0);
	ebListName:SetCallback( "OnEnterPressed", dna.ui.ebListNameOnEnterPressed )

	-- List Import edit box
	local mlebListImport = dna.lib_acegui:Create("MultiLineEditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( mlebListImport )
	mlebListImport:SetLabel( L["lists/mlebListImport/l"] )
	mlebListImport:SetWidth(480)
	mlebListImport:SetPoint("TOPLEFT", ebListName.frame, "BOTTOMLEFT", 5, 0)
	mlebListImport:SetCallback( "OnEnterPressed", function(self)
		dna.fListImport( self:GetText() )
	 end )
end
--Lists Panel Callbacks----------------------------
function dna.ui.ebListNameOnEnterPressed(...)
	local lNewListName = select(3,...)
	local _,lNewListKey = dna.AddList( lNewListName, false, true )
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..dna.D.LTMC[lNewListKey].value)
end
--*****************************************************
--Specific List Panel
--*****************************************************
function dna.CreateListPanel(ListName)
	dna.ui.DB = {}
	dna.ui.DB = dna.D.LTMC[dna.ui.STL[2]]

	-- Pause or resume the rightsgPanel fill layout if you need it or not
	dna.ui.sgMain.tgMain.sgPanel:ResumeLayout()

	-- List of spells tree goes in the sgPanel on right
	dna.ui.sgMain.tgMain.sgPanel.tgList = dna.lib_acegui:Create("TreeGroup")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.tgList )
	dna.ui.sgMain.tgMain.sgPanel.tgList:SetTree( dna.ui.DB.treeList )

	dna.ui.sgMain.tgMain.sgPanel:SetHeight(400)
	--dna.ui.sgMain.tgMain.sgPanel.tgList:SetHeight( 50 )
	dna.ui.sgMain.tgMain.sgPanel.tgList:SetTreeWidth( 350, true )
	dna.ui.sgMain.tgMain.sgPanel.tgList:SetFullWidth(true)
	--dna.ui.sgMain.tgMain.sgPanel.tgList:SetHeight(400)

	dna.ui.sgMain.tgMain.sgPanel.tgList:SetCallback( "OnGroupSelected", dna.ui.tgListOnGroupSelected )
	dna.ui.sgMain.tgMain.sgPanel.tgList:EnableButtonTooltips( false )
	dna.ui.sgMain.tgMain.sgPanel.tgList:SetCallback( "OnButtonEnter", function(self, path, frame)
		local _,_,spellID = string.find(frame, '"(.*)","s"')
		local _,_,itemID = string.find(frame, '"(.*)","i"')
		if ( itemID ) then
			dna.ui.ShowTooltip(dna.ui.sgMain.tgMain.frame, select(2,GetItemInfo( itemID )), "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0, "link")
		elseif ( spellID ) then

			dna.ui.ShowTooltip(dna.ui.sgMain.tgMain.frame, GetSpellLink( spellID ), "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0, "link")
		end
	end )
	dna.ui.sgMain.tgMain.sgPanel.tgList:SetCallback( "OnButtonLeave", dna.ui.HideTooltip )

	-- Create the Entry panel on the right
	dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel = dna.lib_acegui:Create("SimpleGroup")
	dna.ui.sgMain.tgMain.sgPanel.tgList:AddChild(dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel)
	dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:SetLayout("List")
	-- dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:SetFullWidth(true)
    dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:SetWidth(130)
	dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:SetHeight(60)



	-- New spell list entry edit box
	dna.ui.sgMain.tgMain.sgPanel.ebAddSpellEntry = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.ebAddSpellEntry )
	local ebAddSpellEntry = dna.ui.sgMain.tgMain.sgPanel.ebAddSpellEntry
	ebAddSpellEntry:SetLabel( L["list/ebAddSpellEntry/l"] )
	ebAddSpellEntry:SetWidth(250)
	ebAddSpellEntry:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.tgList.frame, "BOTTOMLEFT", -4, 5);
	ebAddSpellEntry:SetCallback( "OnEnterPressed", dna.ui.ebAddSpellEntryOnEnterPressed )
	ebAddSpellEntry:SetCallback( "OnTextChanged", dna.ui.ebAddSpellEntryOnTextChanged )
	ebAddSpellEntry:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ebAddSpellEntry/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 5, "text") end )
	ebAddSpellEntry:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- List export
	local ebListExport = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebListExport )
	ebListExport:SetLabel( L["list/ebListExport/l"] )
	ebListExport:SetWidth(250)
	ebListExport:SetPoint("TOPLEFT", ebAddSpellEntry.frame, "TOPRIGHT", 5, 0)
	ebListExport:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ebListExport/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebListExport:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Export List button
	local bListExport = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bListExport )
	bListExport:SetText( L["list/bListExport/l"] )
	bListExport:SetWidth(100)
	bListExport:SetPoint("TOPLEFT", ebListExport.frame, "BOTTOMLEFT", 0, 0);
	bListExport:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/bListExport/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 0, "text") end )
	bListExport:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	bListExport:SetCallback( "OnClick", function()
		local strExport = dna.fGetListExport()
		ebListExport:SetText( strExport )
		ebListExport.editbox:SetFocus(0)
		ebListExport.editbox:SetCursorPosition(0)
		ebListExport.editbox:HighlightText()
	end )
	
	-- Sort List button
	local bListSort = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bListSort )
	bListSort:SetText( L["list/bListSort/l"] )
	bListSort:SetWidth(100)
	bListSort:SetPoint("TOPLEFT", bListExport.frame, "BOTTOMLEFT", 0, 0);
	bListSort:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/bListSort/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 0, "text") end )
	bListSort:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	bListSort:SetCallback( "OnClick", function()
		local nListKey = dna.ui.STL[2]
		table.sort(dna.D.LTMC[nListKey].treeList, function(a,b) return a.text < b.text end) -- sort list ascending by spell or item text
		local strSelectedList = dna.D.LTMC[dna.ui.STL[2]].value
		dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..strSelectedList) -- Click back on main list: Require the user to click another spell and update dna.ui.SelectedListEntryKey
	end )

	-- Spell Link interactive label
	dna.ui.sgMain.tgMain.sgPanel.ilSpellLink = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.ilSpellLink )
	local ilSpellLink = dna.ui.sgMain.tgMain.sgPanel.ilSpellLink
	ilSpellLink:SetWidth(200)
	ilSpellLink.Tooltip=nil
	ilSpellLink:SetPoint("TOPRIGHT", ebAddSpellEntry.frame, "TOPRIGHT", 50, -5);
	ilSpellLink:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, self.Tooltip, "LEFT", "RIGHT", 0, 0, "link") end )
	ilSpellLink:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- New item list entry edit box
	dna.ui.sgMain.tgMain.sgPanel.ebAddItemEntry = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.ebAddItemEntry )
	local ebAddItemEntry = dna.ui.sgMain.tgMain.sgPanel.ebAddItemEntry
	ebAddItemEntry:SetLabel( L["list/ebAddItemEntry/l"] )
	ebAddItemEntry:SetWidth(250)
	ebAddItemEntry:SetPoint("TOPLEFT", ebAddSpellEntry.frame, "BOTTOMLEFT", 0, 6);
	ebAddItemEntry:SetCallback( "OnEnterPressed", dna.ui.ebAddItemEntryOnEnterPressed )
	ebAddItemEntry:SetCallback( "OnTextChanged", dna.ui.ebAddItemEntryOnTextChanged )
	ebAddItemEntry:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ebAddItemEntry/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 5, "text") end )
	ebAddItemEntry:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Item Link interactive label
	dna.ui.sgMain.tgMain.sgPanel.ilItemLink = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( dna.ui.sgMain.tgMain.sgPanel.ilItemLink )
	local ilItemLink = dna.ui.sgMain.tgMain.sgPanel.ilItemLink
	ilItemLink:SetWidth(250)
	ilItemLink.Tooltip=nil
	ilItemLink:SetPoint("TOPRIGHT", ebAddItemEntry.frame, "TOPRIGHT", 0, -5);
	ilItemLink:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, self.Tooltip, "LEFT", "RIGHT", 0, 0, "link") end )
	ilItemLink:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Rename List edit box
	local ebRenameList = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebRenameList )
	ebRenameList:SetLabel( L["list/ebRenameList/l"] )
	ebRenameList:SetWidth(250)
	ebRenameList:SetPoint("TOPLEFT", ebAddItemEntry.frame, "BOTTOMLEFT", 0, 6)
	ebRenameList:SetCallback( "OnEnterPressed", dna.ui.ebRenameListOnEnterPressed )
	ebRenameList:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ebRenameList/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebRenameList:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	ebRenameList:SetText( dna.ui.DB.text )

	-- Copy List edit box
	local ebCopyList = dna.lib_acegui:Create("EditBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ebCopyList )
	ebCopyList:SetLabel( L["list/ebCopyList/l"] )
	ebCopyList:SetWidth(250)
	ebCopyList:SetPoint("TOPLEFT", ebRenameList.frame, "BOTTOMLEFT", 0, 6);
	ebCopyList:SetCallback( "OnEnterPressed", dna.ui.ebCopyListOnEnterPressed )
	ebCopyList:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ebCopyList/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, -10, "text") end )
	ebCopyList:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Move up interactive label
	local ilLMoveUp = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ilLMoveUp )
	ilLMoveUp:SetWidth(40);ilLMoveUp:SetHeight(40)
	ilLMoveUp:SetImage("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonUp-Up")
	ilLMoveUp:SetImageSize(40, 40)
	ilLMoveUp:SetHighlight("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonUp-Highlight")
	ilLMoveUp:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", -5, -545);
	ilLMoveUp:SetCallback( "OnClick", function() dna.ui.bMoveList(-1) end )
	ilLMoveUp:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ilLMoveUp/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	ilLMoveUp:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Move down interactive label
	local ilLMoveDown = dna.lib_acegui:Create("InteractiveLabel")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ilLMoveDown )
	ilLMoveDown:SetWidth(40);ilLMoveDown:SetHeight(40)
	ilLMoveDown:SetImage("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonDown-Up")
	ilLMoveDown:SetImageSize(40, 40)
	ilLMoveDown:SetHighlight("Interface\\MINIMAP\\UI-Minimap-MinimizeButtonDown-Highlight")
	ilLMoveDown:SetPoint("TOPLEFT", ilLMoveUp.frame, "BOTTOMLEFT", 0, 5);
	ilLMoveDown:SetCallback( "OnClick", function() dna.ui.bMoveList(1) end )
	ilLMoveDown:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/ilLMoveDown/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	ilLMoveDown:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

	-- Delete List button
	local bListDelete = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( bListDelete )
	bListDelete:SetWidth(100)
	bListDelete:SetText(L["common/delete"])
	bListDelete:SetPoint("TOPLEFT", ilLMoveDown.frame, "TOPRIGHT", 110, -10);
	bListDelete:SetCallback( "OnClick", dna.ui.bListDeleteOnClick )
	bListDelete:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/bListDelete/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	bListDelete:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )

end
--List Panel Callbacks-----------------------------
function dna.ui.tgListOnGroupSelected(self)
	self:RefreshTree()														--Refresh the tree so .selected gets updated
	dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:ReleaseChildren()		--Clears the right panel in the list Entry tree
	dna.ui.SelectedListEntryKey=nil										--Save the selected list entry for global scope
	dna.ui.SelectedListEntryTable=nil
	for k,v in pairs(self.buttons) do
		if ( v.selected ) then
			if ( dna:SearchTable( dna.D.LTMC[dna.ui.STL[2]].treeList, "value", v.value ) ) then
				dna.ui.SelectedListEntryKey = k
				dna.ui.SelectedListEntryTable = v
			end
		end
	end
	if( not dna.ui.SelectedListEntryKey ) then
		--dna:dprint("Error: tgListOnGroupSelected called without a button selection")
	else
		dna.D.RunCode( dna.ui.SelectedListEntryTable.value, '', "error pcall:", false, true  )


		-- local func, errorMessage = loadstring(dna.ui.SelectedListEntryTable.value)	-- Use the .value field to create a function specific to the button
		-- if( not func ) then	dna:dprint("Error: tgListOnGroupSelected loadingstring:"..dna.ui.SelectedListEntryTable.value.." Error:"..errorMessage) return end
		-- local success, errorMessage = pcall(func);								-- Call the button specific function we loaded
		-- if( not success ) then
			-- dna:dprint("error pcall:"..errorMessage)
		-- end
	end
end
function dna.ui.CreateListEntryPanel()
	-- Delete List Entry button
	local bEntryDelete = dna.lib_acegui:Create("Button")
	dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:AddChild( bEntryDelete )
    bEntryDelete:SetWidth(130)
	bEntryDelete:SetText( L["common/delete"] )
	bEntryDelete:SetPoint("BOTTOMRIGHT", dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel.frame, "BOTTOMRIGHT", 0, 0);
	bEntryDelete:SetCallback( "OnClick", function() dna.ui.bEntryDeleteOnClick() end )
	bEntryDelete:SetCallback( "OnEnter", function(self) dna.ui.ShowTooltip(self.frame, L["list/bEntryDelete/tt"], "LEFT", "RIGHT", 0, 0, "text") end )
	bEntryDelete:SetCallback( "OnLeave", function() dna.ui.HideTooltip() end )
	
	-- Add to list Dropdown
	local ddAddToList = dna.lib_acegui:Create("Dropdown")
	dna.ui.sgMain.tgMain.sgPanel.tgList.sgEntryPanel:AddChild( ddAddToList )
	ddAddToList:SetList( dna.ui.GetListNames() )
	ddAddToList:SetLabel( L["list/ddAddToList/l"] )
	ddAddToList:SetWidth(132)
	ddAddToList:SetPoint("TOPLEFT", bEntryDelete.frame, "BOTTOMLEFT", 0, 0)
	ddAddToList:SetCallback( "OnValueChanged", function(self)
		local targetListName = dna.ui.GetListNames()[self:GetValue()]
		if (not dna.IsBlank(targetListName) and not dna.IsBlank(dna.ui.SelectedListEntryKey)) then
			local strText = dna.D.LTMC[dna.ui.STL[2]].treeList[dna.ui.SelectedListEntryKey].text
			dna:dprint('strText='..tostring(strText))
			local entryType = dna.D.LTMC[dna.ui.STL[2]].treeList[dna.ui.SelectedListEntryKey].entryType
			dna.AddListEntry(targetListName, true, strText, entryType )
		end
	end )
	ddAddToList:SetCallback( "OnEnter", function(self)
		dna.ui.ShowTooltip(self.frame, L["list/ddAddToList/tt"], "BOTTOMRIGHT", "TOPRIGHT", 0, 0, "text")
	end )
	ddAddToList:SetCallback( "OnLeave", function()
		dna.ui.HideTooltip()
	end )
end


function dna.ui.GetListNames()
	local listNames = {}
	for k, v in pairs(dna.D.LTMC) do
		listNames[k] = v.text
	end
	return listNames
end

function dna.fGetListExport()
	local tExport = {}
	tExport.data = {}
	tExport.strType = "list"
	tExport.data = dna:CopyTable( dna.D.LTMC[dna.ui.STL[2]] )
	strExport = dna.Serialize(tExport)
	return strExport	
end

function dna.ui.bEntryDeleteOnClick() -- 12/28/2020
	if ( dna.IsBlank(dna.ui.SelectedListEntryKey) ) then return end
	local strSelectedList = dna.D.LTMC[dna.ui.STL[2]].value
	local entryText = dna.D.LTMC[dna.ui.STL[2]].treeList[dna.ui.SelectedListEntryKey].text

	tremove(dna.D.LTMC[dna.ui.STL[2]].treeList, dna.ui.SelectedListEntryKey)
    dna.D.LTMC[dna.ui.STL[2]].entries[entryText] = nil
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..strSelectedList) -- Click back on main list: Require the user to click another spell and update dna.ui.SelectedListEntryKey
end
function dna.ui.ebRenameListOnEnterPressed(...)
	local lListName = select(3, ...)
	if ( dna.ui.EntryHasErrors( lListName ) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], lListName) )
		return
	end

	local NewListText = lListName
	local NewListValue = 'dna.CreateListPanel([=['..lListName..']=])'
	if ( dna:SearchTable(dna.D.LTMC, "text", lListName) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], lListName) )
	else
		dna.ui.fMain:SetStatusText( "" ) 														-- Clear any previous errors
		dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].text = NewListText
		dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]].value = NewListValue
		dna.ui.sgMain.tgMain:RefreshTree() 													-- Refresh the tree
		-- dna.AButtons.bInitComplete = false														-- List was renamed
		dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..NewListValue)
	end
end
function dna.ui.ebAddSpellEntryOnEnterPressed(...)
	local lEntryID = select(3,...)
	dna.AddListEntry( dna.D.LTMC[dna.ui.STL[2]].text, true, lEntryID, 's' )
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..dna.D.LTMC[dna.ui.STL[2]].value)
end
function dna.ui.ebAddSpellEntryOnTextChanged(...)
	local spell = select(3, ...)
	dna.ui.sgMain.tgMain.sgPanel.ilSpellLink:SetText( GetSpellLink( spell ) )
	dna.ui.sgMain.tgMain.sgPanel.ilSpellLink.Tooltip = GetSpellLink( spell)
end
function dna.ui.ebAddItemEntryOnEnterPressed(...)
	local lEntryID = select(3,...)
	dna.AddListEntry( dna.D.LTMC[dna.ui.STL[2]].text, true, lEntryID, 'i' )
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..dna.D.LTMC[dna.ui.STL[2]].value)
end
function dna.ui.ebAddItemEntryOnTextChanged(...)
	local itemID = dna.GetItemId( select(3, ...) )
	if ( itemID ) then
		dna.ui.sgMain.tgMain.sgPanel.ilItemLink:SetText( (select(2,GetItemInfo( itemID )) or "")..' '..(itemID or "") )
		dna.ui.sgMain.tgMain.sgPanel.ilItemLink.Tooltip = select(2,GetItemInfo( itemID ))
	end
end
function dna.ui.ebCopyListOnEnterPressed(...)
	local lListName = select(3, ...)
	if ( dna.ui.EntryHasErrors( lListName ) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/unsafestring"], lListName) )
		return
	end
	local NewList = dna:CopyTable( dna.DB.global.treeMain[dna.ui.STL[1]].children[dna.ui.STL[2]] )
	NewList.text = lListName
	NewList.value = 'dna.CreateListPanel([=['..lListName..']=])'
	if ( dna:SearchTable(dna.D.LTMC, "text", lListName) ) then
		dna.ui.fMain:SetStatusText( string.format(L["common/error/exists"], lListName) )
	else
		dna.ui.fMain:SetStatusText( "" ) 											-- Clear any previous errors
		table.insert( dna.DB.global.treeMain[dna.ui.STL[1]].children, NewList)
		dna.ui.sgMain.tgMain:RefreshTree()
	end
end
function dna.ui.bListDeleteOnClick(...)
	local deleteKey = dna.ui.STL[2]
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value)
	tremove(dna.D.LTMC, deleteKey)
	dna.ui.sgMain.tgMain:RefreshTree() 										-- Gets rid of the rotation from the tree
	dna.ui.sgMain.tgMain.sgPanel:ReleaseChildren() 							-- clears the right panel
	-- dna.AButtons.bInitComplete = false											-- List was deleted
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value)						-- Select the list main tree
	dna.ui.HideTooltip()
end
function dna.ui.bMoveList(movevalue)
	local SavedValue	= dna.D.LTMC[dna.ui.STL[2]].value
	local SavedList		= dna:CopyTable(dna.ui.DB)							-- Deepcopy the list from the db
	local maxKey		= #(dna.D.LTMC)
	tremove(dna.D.LTMC, dna.ui.STL[2])
	dna.ui.STL[2] = dna.ui.STL[2]+movevalue											-- Now change the key value to up or down
	if ( dna.ui.STL[2] < 1) then dna.ui.STL[2] = 1 end
	if ( dna.ui.STL[2] > maxKey ) then dna.ui.STL[2] = maxKey end
	tinsert(dna.D.LTMC, dna.ui.STL[2], SavedList)
	dna.ui.sgMain.tgMain:SelectByValue(dna.D.LTM.value.."\001"..SavedValue)
end
function dna.fListImport( strListText )
	local tImportedData = dna.DeserializeString( strListText )
	-- dna:dprint( tostring(tImportedData) )
	-- dna:dprint("   tImportedData.strType="..tostring(tImportedData['strType']))
	if tImportedData.strType == 'list' then
		-- dna:dprint("    tImportedData.strType is list")
		tImportedData.data.text = 'ImportedList'
		-- We have to set the .value so the tree selects properly
		tImportedData.data.value = 'dna.CreateListPanel([=['..tImportedData.data.text..']=])'
		-- Check if the ImportedRotation exists already
		local nImportedListIndex = dna:SearchTable(dna.D.LTMC, "text", tImportedData.data.text)
		if not dna.IsBlank(nImportedListIndex) then
			-- dna:dprint( "rotation already existing nImportedListIndex="..tostring(nImportedListIndex) )
			dna.D.LTMC[nImportedListIndex] =  dna:CopyTable(tImportedData.data)
		else
			-- dna:dprint( "rotation is new nImportedListIndex="..tostring(nImportedListIndex) )
			table.insert(dna.D.LTMC, tImportedData.data)
		end

		if ( dna.ui.sgMain ) then dna.ui.sgMain.tgMain:RefreshTree() end
	end
end