{['strType'] = "rotation",['data'] = {['meleespell'] = "Maul",['nSpecialization'] = 4,['text'] = "Guardian MaxDps",['strClass'] = "DRUID",['equipmentset'] = "",['value'] = "dna.SetRotationPanel([=[Guardian MaxDps]=])",['children'] = {[1] = {['criteria'] = "--_dna_enable_lua\
dna.CreateToggle(1,-64,0,32,\"War Stomp\",\"War Stomp\")\
dna.GetToggleEnabled(1)\
return false",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Meta]=])",['text'] = "Meta",['bReady'] = true,},[2] = {['_spellid'] = "Ironfur",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"7\",\"Ironfur\") and\
dna.GetUnitPower(\"player\",\"Rage\")>=40 and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\") and\
dna.GetUnitCastingSpellInList(\"target\",\"ActiveMitigation\") and\
not dna.GetUnitHasBuffName(\"player\",\"Ironfur\",\"HELPFUL\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[ActiveMitigation]=])",['text'] = "ActiveMitigation",['bReady'] = true,},[3] = {['_spellid'] = "Barkskin",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"9\",\"Barkskin\") and\
dna.GetSpellCooldownLessThanGCD(\"Barkskin\") and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\") and\
dna.GetUnitCastingSpellInList(\"target\",\"Barkskin\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Barkskin]=])",['text'] = "Barkskin",['bReady'] = true,},[4] = {['_spellid'] = "Survival Instincts",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"-\",\"Survival Instincts\") and\
dna.GetSpellCharges(\"Survival Instincts\")>0 and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\") and\
dna.GetUnitCastingSpellInList(\"target\",\"Survival Instincts\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Survival Instincts]=])",['text'] = "Survival Instincts",['bReady'] = true,},[5] = {['_spellid'] = "Slimy Consumptive Organ",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\";\",\"Slimy Consumptive Organ\") and\
dna.GetItemIsEquipped(\"Slimy Consumptive Organ\") and\
dna.GetSlotCooldownLessThanGCD(\"Trinket0Slot\") and\
dna.GetUnitHasBuffNameStacks(\"player\",\"Gluttonous\",\"HELPFUL\")>8 and\
dna.GetUnitHealthLost(\"player\")>4300",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[[T] Heal Trinket]=])",['text'] = "[T] Heal Trinket",['bReady'] = true,},[6] = {['_spellid'] = "Frenzied Regeneration",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"8\",\"Frenzied Regeneration\") and\
dna.GetSpellCharges(\"Frenzied Regeneration\")>0 and\
dna.GetUnitPower(\"player\",\"Rage\")>=10 and\
dna.GetUnitHealthPercent(\"player\")<75 and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\") and\
not dna.GetUnitHasBuffName(\"player\",\"Frenzied Regeneration\",\"HELPFUL\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Frenzied Regen]=])",['text'] = "Frenzied Regen",['bReady'] = true,},[7] = {['_spellid'] = "Auto Attack",['criteria'] = "--_dna_enable_lua\
\
dna:SetWeakAuraInfo(select(1,...),nil,\"Auto Attack\")\
\
if (\
    dna.GetUnitAffectingCombat(\"target\")\
    or \
    dna.GetSpellInRangeOfUnit(\"Mangle\",\"target\")\
) then\
  return false -- move on to rotation\
end\
return true -- block rotation default\
",['_nemo_criteria_passed'] = true,['value'] = "dna.ui:CAP([=[[Hold Attack]]=])",['text'] = "[Hold Attack]",['bReady'] = true,},[8] = {['_spellid'] = "Incapacitating Roar",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"y\",\"Incapacitating Roar\") and\
dna.GetUnitCastingSpellInList(\"target\",\"HardInterrupts\") and\
dna.GetSpellCooldownLessThanGCD(\"Incapacitating Roar\") and\
dna.GetSpellInRangeOfUnit(\"Maul\",\"target\") and\
dna.GetUnitCastingSpellInList(\"target\",\"HardInterrupts\") and\
not dna.GetUnitHasBuffName(\"player\",\"Prowl\",\"HELPFUL\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[[HI] Incapacitating Roar]=])",['text'] = "[HI] Incapacitating Roar",['bReady'] = true,},[9] = {['_spellid'] = "War Stomp",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"i\",\"War Stomp\") and\
dna.GetUnitCastingSpellInList(\"target\",\"HardInterrupts\") and\
dna.GetSpellCooldownLessThanGCD(\"War Stomp\") and\
not dna.GetSpellCooldownLessThanGCD(\"Incapacitating Roar\") and\
dna.GetSpellInRangeOfUnit(\"Maul\",\"target\") and\
not dna.GetUnitHasBuffName(\"player\",\"Prowl\",\"HELPFUL\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[[HI] War Stomp]=])",['text'] = "[HI] War Stomp",['bReady'] = true,},[10] = {['_spellid'] = "Skull Bash",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"e\",\"Skull Bash\") and\
dna.GetUnitCastingInterruptibleSpell(\"target\") and\
dna.GetSpellCooldownLessThanGCD(\"Skull Bash\") and\
dna.GetSpellInRangeOfUnit(\"Skull Bash\",\"target\") and\
dna.GetUnitCastingSpellInList(\"target\",\"Interrupts\") and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\")\
and not dna.GetUnitHasBuffNameInList(\"target\",\"BuffsBlockingInterrupt\")",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[[I] Skull Bash]=])",['text'] = "[I] Skull Bash",['bReady'] = true,},[11] = {['_spellid'] = "Skull Bash",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"u\",\"Skull Bash\") and\
dna.GetUnitCastingInterruptibleSpell(\"focus\") and\
dna.GetSpellCooldownLessThanGCD(\"Skull Bash\") and\
dna.GetSpellInRangeOfUnit(\"Skull Bash\",\"focus\") and\
dna.GetUnitCastingSpellInList(\"focus\",\"Interrupts\") and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\")\
and not dna.GetUnitHasBuffNameInList(\"focus\",\"BuffsBlockingInterrupt\")",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[[I] Focus Interrupt]=])",['text'] = "[I] Focus Interrupt",},[12] = {['_spellid'] = "Remove Corruption",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"j\",\"Remove Corruption\") and\
dna.GetUnitPower(\"player\",\"Mana\")>= 130 and\
dna.GetSpellCooldownLessThanGCD(\"Remove Corruption\") and\
(\
  dna.GetUnitHasDebuffType(\"player\",\"Poison\")\
  or dna.GetUnitHasDebuffType(\"player\",\"Curse\")\
) and\
not dna.GetUnitHasBuffName(\"player\",\"Prowl\",\"HELPFUL\")\
",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Remove Corruption]=])",['text'] = "Remove Corruption",['bReady'] = true,},[13] = {['_spellid'] = "Soothe",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"l\",\"Soothe\") and\
dna.GetSpellCooldownLessThanGCD(\"Soothe\") and\
dna.GetUnitPower(\"player\",\"Mana\")>= 477 and\
(\
    dna.GetUnitHasBuffNameInList(\"target\",\"Enrage\")\
    or \
    dna.GetUnitCastingSpellInList(\"target\",\"Enrage\")\
)",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Soothe]=])",['text'] = "Soothe",['bReady'] = true,},[14] = {['_spellid'] = "Ironfur",['criteria'] = "dna:SetWeakAuraInfo(select(1,...),\"7\",\"Ironfur\") and\
dna.GetUnitPower(\"player\",\"Rage\")>=40 and\
dna.GetUnitHasBuffName(\"player\",\"Bear Form\",\"HELPFUL\")",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[Ironfur]=])",['text'] = "Ironfur",['bReady'] = true,},[15] = {['criteria'] = "dna.GetMaxDpsGlowingKeybind(select(1,...))~=nil",['_nemo_criteria_passed'] = false,['value'] = "dna.ui:CAP([=[MaxDps]=])",['text'] = "MaxDps",['bReady'] = true,},},['icon'] = "Interface\\PaperDollInfoFrame\\UI-GearManager-Undo",['rangespell'] = "Moonfire",},}