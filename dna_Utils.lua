local dna 		= LibStub("AceAddon-3.0"):GetAddon("dna")
local L       	= LibStub("AceLocale-3.0"):GetLocale("dna")

function dna:CreateDebugFrame()
	if ( dna.ui.fDebug and dna.ui.fDebug:IsVisible() ) then
		dna.ui.fDebug.frame:Show()
		return
	end
	-- frame Debug
	dna.ui.fDebug = dna.lib_acegui:Create("Frame")
	dna.ui.fDebug:SetTitle("Debug")
	dna.ui.fDebug:SetCallback("OnClose", function(widget)
		dna.lib_acegui:Release(widget)
		dna.ui.fDebug = nil
	end)
	dna.ui.fDebug:SetLayout("Fill")
	dna.ui.fDebug:SetWidth(475)
	dna.ui.fDebug:SetHeight(600)
	dna.ui.fDebug:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
	dna.ui.fDebug:PauseLayout()

	-- simplegroup to hold the editbox
	dna.ui.sgDebug = dna.lib_acegui:Create("SimpleGroup")
	dna.ui.sgDebug:SetLayout("Fill")
	dna.ui.fDebug:AddChild(dna.ui.sgDebug)
	dna.ui.sgDebug:SetPoint("TOPLEFT", dna.ui.fDebug.frame, "TOPLEFT", 10, -10);
	dna.ui.sgDebug:SetWidth(450)
	dna.ui.sgDebug:SetHeight(450)

	dna.ui.sgDebug.mlebDebug = dna.lib_acegui:Create("MultiLineEditBox")
	dna.ui.sgDebug:AddChild( dna.ui.sgDebug.mlebDebug )
	dna.ui.sgDebug.mlebDebug:SetLabel( L["utils/debug/mlebDebug/l"] )
	dna.ui.sgDebug.mlebDebug:SetPoint("TOPLEFT", dna.ui.sgDebug.frame, "TOPLEFT", 0, 0);
	dna.ui.sgDebug.mlebDebug:SetWidth(450)
	dna.ui.sgDebug.mlebDebug:DisableButton(true)

	-- Code box
	dna.ui.sgDebug.mlebCode = dna.lib_acegui:Create("MultiLineEditBox")
	dna.ui.sgDebug:AddChild( dna.ui.sgDebug.mlebCode )
	dna.ui.sgDebug.mlebCode:SetLabel( L["utils/debug/lua/l"] )
	dna.ui.sgDebug.mlebCode:SetPoint("TOPLEFT", dna.ui.sgDebug.mlebDebug.frame, "BOTTOMLEFT", 0, 5);
	dna.ui.sgDebug.mlebCode:SetWidth(450)
	dna.ui.sgDebug.mlebCode:SetCallback( "OnEnterPressed" , dna.ui.mlebCodeOnEnterPressed )

	-- Clear button
	dna.ui.sgDebug.bClear = dna.lib_acegui:Create("Button")
	dna.ui.sgDebug:AddChild( dna.ui.sgDebug.bClear )
	dna.ui.sgDebug.bClear:SetText( "Clear" )
	dna.ui.sgDebug.bClear:SetWidth(100)
	dna.ui.sgDebug.bClear:SetPoint("BOTTOMRIGHT", dna.ui.sgDebug.frame, "BOTTOMRIGHT", 0, -100);
	dna.ui.sgDebug.bClear:SetCallback( "OnClick", function() dna.ui.sgDebug.mlebDebug:SetText("") end )

	-- Test2 button
	-- dna.ui.sgDebug.bTest2 = dna.lib_acegui:Create("Button")
	-- dna.ui.sgDebug:AddChild( dna.ui.sgDebug.bTest2 )
	-- dna.ui.sgDebug.bTest2:SetText( "Test2" )
	-- dna.ui.sgDebug.bTest2:SetWidth(100)
	-- dna.ui.sgDebug.bTest2:SetPoint("BOTTOMRIGHT", dna.ui.sgDebug.bClear.frame, "BOTTOMLEFT", 0, 0);
	-- dna.ui.sgDebug.bTest2:SetCallback( "OnClick", function()
	--DEBUG2 START-----------------------------------------------
		-- dna.ui.sgDebug.mlebDebug:SetText("")
		-- dna.Engine.PrintQueue()
	--DEBUG2 END-------------------------------------------------
	-- end )

	-- Test1 button
	-- dna.ui.sgDebug.bTest1 = dna.lib_acegui:Create("Button")
	-- dna.ui.sgDebug:AddChild( dna.ui.sgDebug.bTest1 )
	-- dna.ui.sgDebug.bTest1:SetText( "Test1" )
	-- dna.ui.sgDebug.bTest1:SetWidth(100)
	-- dna.ui.sgDebug.bTest1:SetPoint("BOTTOMRIGHT", dna.ui.sgDebug.bTest2.frame, "BOTTOMLEFT", 0, 0);
	-- dna.ui.sgDebug.bTest1:SetCallback( "OnClick", function()
	--DEBUG1 START-----------------------------------------------

	--DEBUG1 END-------------------------------------------------
	-- end )
end

function dna.toBits(num,bits)
    -- returns a table of bits, most significant first.
    bits = bits or select(2,math.frexp(num))
    local t={} -- will contain the bits        
    for b=bits,1,-1 do
        t[b]=math.fmod(num,2)
        num=(num-t[b])/2
    end
    return t
end
function dna.ui.mlebCodeOnEnterPressed(...)
	--********************************************************************************************
	-- lua parser in debug window
	--********************************************************************************************
	local fCode = loadstring(select(3,...) or "")
	local success, errorMessage = pcall(fCode)
	dna:dprint("DebugCompile:"..tostring(success))
	dna:dprint("DebugError:"..tostring(errorMessage))
end
function dna:eprint(suffix, startTime, minElapsed)
	--********************************************************************************************
	-- Elapsed print for cpu profiling
	--********************************************************************************************
	local elapsedTime = debugprofilestop()-startTime
	--if ( elapsedTime > (minElapsed or 0) and dna.ui.fDebug and dna.ui.fDebug:IsVisible() ) then
	if ( elapsedTime > (minElapsed or 0) ) then
		print(format(" E: %f ms:", elapsedTime)..tostring(suffix) )
	end
end
function dna:dprint(value, cleardebug)
	--********************************************************************************************
	-- Debug print
	--********************************************************************************************
	dna:CreateDebugFrame()
	if ( cleardebug==true ) then dna.ui.sgDebug.mlebDebug:SetText("") end
	if ( dna.IsBlank(value) ) then
		dna.ui.sgDebug.mlebDebug:SetText(L["utils/debug/prefix"].."Error: Value is blank".."\n"..dna.ui.sgDebug.mlebDebug:GetText())
		return
	end
	if type(value) == "table" then
		dna:tprint(value)
	else
		--dna.ui.sgDebug.mlebDebug:SetText(L["utils/debug/prefix"]..value.."\n"..dna.ui.sgDebug.mlebDebug:GetText()) -- reverse scroll
		dna.ui.sgDebug.mlebDebug:SetText(dna.ui.sgDebug.mlebDebug:GetText().."\n".. L["utils/debug/prefix"]..value)
	end
end
function dna:doprint(value, cleardebug)
	--********************************************************************************************
	-- Debug open print
	-- Prints debug only if the debug window is open, used in COMBAT_LOG_EVENT_UNFILTERED
	--********************************************************************************************
	if ( dna.ui.fDebug and dna.ui.fDebug:IsVisible() ) then
		dna:dprint(value, cleardebug)
	end
end
function dna:tprint(ttable)
	--********************************************************************************************
	-- Prints a table without recursion
	--********************************************************************************************
	dna:CreateDebugFrame()
	if ( dna.IsBlank(ttable) ) then
		dna.ui.sgDebug.mlebDebug:SetText(dna.ui.sgDebug.mlebDebug:GetText().."\n"..L["utils/debug/prefix"].."Error: ttable is blank")
	else
		for k,v in pairs(ttable) do dna.ui.sgDebug.mlebDebug:SetText(dna.ui.sgDebug.mlebDebug:GetText().."\n"..L["utils/debug/prefix"]..k,v) end
	end
end
function dna:rtprint(ttable, indent, done)	-- recursive table print
	--********************************************************************************************
	-- recursive table print
	--********************************************************************************************
	dna:CreateDebugFrame()
	if ( dna.IsBlank(ttable) ) then
		print(L["utils/debug/prefix"].."Error: ttable is blank");
		return
	end
	done = done or {}
	indent = indent or 0
	if type(ttable) == "table" then
		for key, value in pairs (ttable) do
			formatting = strrep("  ", indent) .. tostring(key) .. ":"
			if type (value) == "table" and not done [value] then
				done [value] = true
				dna.ui.sgDebug.mlebDebug:SetText(dna.ui.sgDebug.mlebDebug:GetText().."\n"..formatting)

				dna:rtprint(value, indent+1, done)
			else
				dna.ui.sgDebug.mlebDebug:SetText(dna.ui.sgDebug.mlebDebug:GetText().."\n"..formatting..tostring(value))
			end
		end
	else
		dna.ui.sgDebug.mlebDebug:SetText( dna.ui.sgDebug.mlebDebug:GetText().."\n"..tostring(ttable) )
	end
end
function dna.IsNumeric(a)
    return type(tonumber(a)) == "number";
end
function dna.NilToNumeric(a, default)
	if ( dna.IsBlank(a) ) then
		if ( dna.IsNumeric(default) ) then
			return tonumber(default)
		else
			return 0
		end
	elseif ( dna.IsNumeric(a) ) then
		return tonumber(a)
	else
		return 0
	end
end
function dna:SearchTable(ttable, fieldname, value)
	if ( dna.IsBlank(ttable) ) then return nil end
	for k,v in pairs(ttable) do
		if ( ttable[k][fieldname] == value ) then return k end
	end
	return nil
end
function dna.IsBlank(value)
	if ( value == nil or value == "") then return true end
	return false
end
function dna:CopyTable( src )
    local copy = {}
    for k,v in pairs(src) do
        if ( type(v) == "table" ) then
            copy[k]=dna:CopyTable(v)
        else
            copy[k]=v
        end
    end
    return copy
end
function dna:TableCount( tTable )
  local count = 0
  for _ in pairs(tTable) do count = count + 1 end
  return count
end
function dna:Round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end

function dna:CreateDebugFrame1()
end

--
-- Aliases
--
function dna.DebugPrint(value, cleardebug)
	return dna:dprint(value, cleardebug)
end
function dna.DebugOpenPrint(value, cleardebug)
	return dna:doprint(value, cleardebug)
end
function dna.TablePrint(ttable)
	return dna:tprint(ttable)
end
function dna.TablePrintRec(ttable, indent, done)
	return dna:rtprint(ttable, indent, done)
end
function dna.IsValNumeric(a)
	return dna.IsNumeric(a)
end
function dna.TableSearch(ttable, fieldname, value)
	return dna:SearchTable(ttable, fieldname, value)
end
function dna.DeepCopyTable( src )
	return dna:CopyTable( src )
end
function dna.CountTable( tTable )
	return dna:TableCount( tTable )
end
function dna.Truncate(number, decimals)
	return dna:Round(number, decimals)
end

function dna.EnumerateTable(tab, f, recurse, callback)
	local seen = {}
	local function Enumerate(name, t)
		if seen[t] then
			return
		end
		f(name, t)
		seen[t] = true
		for k, v in pairs(t) do
			if type(v) == "table" then
				if recurse then
					Enumerate(string.format("%s[%s]", name, k), v)
				elseif callback then
					local count = 0
					for i, _ in pairs(v) do
						count = count + 1
					end
					callback(k, count)
				end
			end
		end
	end
	Enumerate('<root>', tab)
end

function dna.DebugTableMemory(tab, recurse, printer)
	local p = printer or dna.DebugPrint
	local function PrintRec(name, t)
		local contents = {}
		local counts = {}
		for k, v in pairs(t) do
			local obj = type(v)
			counts[obj] = (counts[obj] or 0) + 1
		end
		for k, v in pairs(counts) do
			contents[#contents+1] = string.format("%s=>%d", k, v)
		end
		local summary = table.concat(contents, ' ')
		p(string.format("Table %s: {%s}", name, summary))
		coroutine.yield()
	end
	local function PrintSummary(name, count)
		p(string.format("<subtable> %s: %d", name, count))
		coroutine.yield()
	end

	table.insert( dna.D.Threads, coroutine.create( dna.EnumerateTable ) )
	coroutine.resume( dna.D.Threads[1], tab, PrintRec, recurse, PrintSummary )
end

local function recurseStringify(data, level, lines)
  for k, v in pairs(data) do
    local lineFormat = strrep("    ", level) .. "[%s] = %s"
    local form1, form2, value
    local kType, vType = type(k), type(v)
    if kType == "string" then
      form1 = "%q"
    elseif kType == "number" then
      form1 = "%d"
    else
      form1 = "%s"
    end
    if vType == "string" then
      form2 = "%q"
      v = v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"")
    elseif vType == "boolean" then
      v = tostring(v)
      form2 = "%s"
    else
      form2 = "%s"
    end
    lineFormat = lineFormat:format(form1, form2)
    if vType == "table" then
      tinsert(lines, lineFormat:format(k, "{"))
      recurseStringify(v, level + 1, lines)
      tinsert(lines, strrep("    ", level) .. "},")
    else
      tinsert(lines, lineFormat:format(k, v) .. ",")
    end
  end
end

function dna.Serialize(data)
  local lines = {"{"}
  recurseStringify(data, 1, lines)
  tinsert(lines, "}")
  return table.concat(lines, "\n")
end


function dna.SerializeRotation(val, name)
	local tmp = ""

    if name then 
		if type(name) == "number" then
			tmp = tmp .. "[" .. name .. "]" .. " = "
		else
			tmp = tmp .. "['" .. name .. "']" .. " = "
		end
	end
	
    if type(val) == "table" then
		--dna:PrintR('Serialzing a table=')
		--dna:PrintR(val)
        tmp = tmp .. "{"

        for k, v in pairs(val) do
            tmp =  tmp .. dna.SerializeRotation(v, k) .. ","
        end

        tmp = tmp .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
	--Print("msg="..tostring(tmp))
    return tmp
end

function dna.DeserializeString(data)
  local fScript, loadStringError = loadstring("return " .. data)
  if fScript then
    local status, result = pcall(fScript)
    if status then
      if result ~= nil then
        return result
      else
        dna:dprint("Failed to import data. Data deserialized but was invalid.")
      end
    else
      dna:dprint("Failed to import data, invalid load data: " .. tostring(result))
    end
  else
    dna:dprint("Failed to import data, invalid load data: " .. tostring(loadStringError))
  end
end
