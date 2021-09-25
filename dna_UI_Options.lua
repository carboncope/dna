local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--*****************************************************
--Options Panel
--*****************************************************
function dna.CreateOptionsPanel()
	dna.ui.sgMain.tgMain.sgPanel:PauseLayout()--Pause the layout so you can position correctly

	-- Print Highest Priority CheckBox
	local PrintHighestPriority = dna.lib_acegui:Create("CheckBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( PrintHighestPriority )
	PrintHighestPriority:SetLabel( L["options/cbPrintHighestPriority/l"] )
	PrintHighestPriority:SetWidth(400)
	PrintHighestPriority:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 0, 0)
	PrintHighestPriority:SetCallback( "OnValueChanged", function(self) dna.D.OTM[dna.D.PClass].bPrintSpells = self:GetValue() end )
	if (dna.IsBlank(dna.D.OTM[dna.D.PClass].bPrintSpells)) then
		PrintHighestPriority:SetValue(false)
		dna.D.OTM[dna.D.PClass].bPrintSpells=false
	else
		PrintHighestPriority:SetValue( dna.D.OTM[dna.D.PClass].bPrintSpells)
	end

	local ShowHighestKeybind = dna.lib_acegui:Create("CheckBox")
	dna.ui.sgMain.tgMain.sgPanel:AddChild( ShowHighestKeybind )
	ShowHighestKeybind:SetLabel( L["options/cbShowHighestKeybind/l"] )
	ShowHighestKeybind:SetWidth(400)
	ShowHighestKeybind:SetPoint("TOPLEFT", dna.ui.sgMain.tgMain.sgPanel.frame, "TOPLEFT", 0, -20)
	ShowHighestKeybind:SetCallback( "OnValueChanged", function(self) dna.D.OTM[dna.D.PClass].bShowHighestKeybind = self:GetValue() end )
	if (dna.IsBlank(dna.D.OTM[dna.D.PClass].bShowHighestKeybind)) then
		ShowHighestKeybind:SetValue(false)
		dna.D.OTM[dna.D.PClass].bShowHighestKeybind=false
	else
		ShowHighestKeybind:SetValue( dna.D.OTM[dna.D.PClass].bShowHighestKeybind)
	end
end

