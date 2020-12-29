local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

--*****************************************************
--DataBroker Menu functions
--*****************************************************
function dna.ui.SortMenu(item1, item2)
	return item1.id < item2.id
end

function dna.ui.MenuChangeRotation(self, rotationname)
	dna.ui.SelectRotation( rotationname )
end

function dna.ui.MenuCreate(self, _level)
	local level = _level or 1
	local id = 1
	local info = {}
	dna.ui.Menu = {}

	for rtk, rotation in pairs(dna.D.RTMC) do
		info = {
			id = id,
			text = rotation.text,
			icon = nil,
			func = dna.ui.MenuChangeRotation,
			arg1 = rotation.text,
			notCheckable = true,
		}
		dna.ui.Menu[id] = info
		id = id + 1
	end
	table.sort(dna.ui.Menu, dna.ui.SortMenu)
end

function dna.ui.InitMenu(self, _level)
	local level = _level or 1
	for _, value in pairs(dna.ui.Menu) do
		UIDropDownMenu_AddButton(value, level)
	end
end

function dna.ui.MenuOnClick(self, button)
	if button == "LeftButton" then
		if (IsShiftKeyDown()) then
			ReloadUI()
			return
		end
		GameTooltip:Hide()
		if (not dna.ui.MenuFrame) then
			dna.ui.MenuFrame = CreateFrame("Frame", "dnaMenuFrame", UIParent, "UIDropDownMenuTemplate")
		end
		dna.ui.MenuCreate()
		UIDropDownMenu_Initialize(dna.ui.MenuFrame, dna.ui.InitMenu, "MENU")
		ToggleDropDownMenu(1, nil, dna.ui.MenuFrame, self, 20, 4)
	elseif button == "RightButton" then
		if (IsShiftKeyDown()) then
			dna:CreateDebugFrame()
			return
		end
		dna.ui.CreateMainFrame()
	end
end
