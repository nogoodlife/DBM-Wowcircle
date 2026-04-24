local mod	= DBM:NewMod("Festergut", "DBM-Icecrown", 2)
local L		= mod:GetLocalizedStrings()

local sformat = string.format

mod:SetRevision("20260308121616")
mod:SetCreatureID(36626)
mod:SetEncounterID(849)
mod:RegisterCombat("combat")
mod:SetUsedIcons(1, 2, 3)
mod:SetHotfixNoticeRev(20230627000000)
mod:SetMinSyncRevision(20230627000000)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 69195 71219 73031 73032",
	"SPELL_CAST_SUCCESS 69278 71221 69240 71218 73019 73020",
	"SPELL_AURA_APPLIED 69279 69166 71912 72219 72551 72552 72553 69240 71218 73019 73020 69291 72101 72102 72103",
	"SPELL_AURA_APPLIED_DOSE 69166 71912 72219 72551 72552 72553 69291 72101 72102 72103",
	"SPELL_AURA_REMOVED 69279",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

local warnInhaledBlight		= mod:NewStackAnnounce(69166, 3)
local warnGastricBloat		= mod:NewStackAnnounce(72219, 2, nil, "Tank|Healer")
local warnGasSpore			= mod:NewTargetNoFilterAnnounce(69279, 4)
local warnVileGas			= mod:NewTargetAnnounce(69240, 3)

local specWarnPungentBlight	= mod:NewSpecialWarningSpell(69195, nil, nil, nil, 2, 2)
local specWarnGasSpore		= mod:NewSpecialWarningYou(69279, nil, nil, nil, 1, 2)
local yellGasSpore			= mod:NewYellMe(69279)
local specWarnVileGas		= mod:NewSpecialWarningYou(69240, nil, nil, nil, 1, 2)
local yellVileGas			= mod:NewYellMe(69240)
local specWarnGastricBloat	= mod:NewSpecialWarningStack(72219, nil, 9, nil, nil, 1, 6)
local specWarnInhaled3		= mod:NewSpecialWarningStack(69166, "Tank", 3, nil, nil, 1, 2)
local specWarnGoo			= mod:NewSpecialWarningDodge(72297, true, nil, nil, 1, 2) -- Retail has default true for melee but it's more sensible to show for everyone.

local timerGasSpore			= mod:NewBuffFadesTimer(12, 69279, nil, nil, nil, 3)
local timerVileGas			= mod:NewBuffFadesTimer(6, 69240, nil, "Ranged", nil, 3)
local timerVileGasCD		= mod:NewCDTimer(30, 69240, nil, "Ranged", nil, 3, nil, nil, false) --false keep, cuz no idea how this timer works
local timerGasSporeCD		= mod:NewVarTimer("v40.0-43.5", 69279, nil, nil, nil, 3, nil, nil, true)
local timerPungentBlight	= mod:NewCDTimer(30.3, 69195, nil, nil, nil, 2)		-- 30.34 | 31.44 | 30.8 from 3rd stack applied +3s cast time
local timerInhaledBlight	= mod:NewVarTimer("v33.5-35.0", 69166, nil, nil, nil, 6, nil, nil, true)
local timerGastricBloat		= mod:NewTargetTimer(100, 72219, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON)	-- 100 Seconds until expired
local timerGastricBloatCD	= mod:NewVarTimer("v12.0-13.0", 72219, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) -- REVIEW! variance 12.33, 12.03, 12.41, 12.20, 12.47, 12.33, 12.17
local timerGooCD			= mod:NewVarTimer("v10.5-26.5", 72297, nil, nil, nil, 3, nil, nil, true) --true keep, cuz need logs

local berserkTimer			= mod:NewBerserkTimer(300)

mod:AddRangeFrameOption(10, 69240, "Ranged")
mod:AddSetIconOption("SetIconOnGasSpore", 69279, true, 7, {1, 2, 3})
mod:AddBoolOption("AnnounceSporeIcons", false, nil, nil, nil, nil, 69279)
mod:AddBoolOption("AchievementCheck", false, "announce", nil, nil, nil, 4615, "achievement")

local gasSporeTargets = {}
local vileGasTargets = {}
mod.vb.gasSporeCast = 0
mod.vb.vileGasCast = 0
mod.vb.warnedfailed = false

function mod:AnnounceSporeIcons(uId, icon)
	if self.Options.AnnounceSporeIcons and DBM:IsInGroup() and DBM:GetRaidRank() > 1 then
		SendChatMessage(L.SporeSet:format(icon, DBM:GetUnitFullName(uId)), DBM:IsInRaid() and "RAID" or "PARTY")
	end
end

local function warnGasSporeTargets()
	warnGasSpore:Show(table.concat(gasSporeTargets, "<, >"))
	timerGasSpore:Start()
	table.wipe(gasSporeTargets)
end

local function warnVileGasTargets()
	warnVileGas:Show(table.concat(vileGasTargets, "<, >"))
	table.wipe(vileGasTargets)
	timerVileGas:Start()
end

function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	timerInhaledBlight:Start(sformat("v%s-%s", 33.4-delay, 33.6-delay))
	self.vb.vileGasCast = 0
	timerVileGasCD:Start(9.95-delay)
	timerGasSporeCD:Start(20-delay)
	timerGastricBloatCD:Start(sformat("v%s-%s", 10.8-delay, 11.0-delay))
	table.wipe(gasSporeTargets)
	table.wipe(vileGasTargets)
	self.vb.gasSporeCast = 0
	self.vb.warnedfailed = false
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(10) -- VileGas spread distance should be 8y, + char moves a bit ? so range 10 should be good enough
	end
	if self:IsHeroic() then --why only heroic ?
		timerGooCD:Start(sformat("v%s-%s", 16.5-delay, 19.5-delay))
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(69195, 71219, 73031, 73032) then	-- Pungent Blight
		specWarnPungentBlight:Show()
		specWarnPungentBlight:Play("aesoon")
	end
end

local gastimers = {30, 40, 41, 20, 30, 40} -- sometimes {30,40,62,30} for no reason? plz explain to me how that works

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(69278, 71221) then	-- Gas Spore (10 man, 25 man)
		self.vb.gasSporeCast = self.vb.gasSporeCast + 1
		if self.vb.gasSporeCast == 3 then
			timerGasSporeCD:Start("v50.0-51.5")
		else
			timerGasSporeCD:Start()
		end
	elseif args:IsSpellID(69240, 71218, 73019, 73020) and self:AntiSpam(1, 2) then	-- Vile Gas
		self.vb.vileGasCast = self.vb.vileGasCast + 1
		local gastimer = gastimers[self.vb.vileGasCast] or 30
		timerVileGasCD:Start(gastimer)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 69279 then	-- Gas Spore
		gasSporeTargets[#gasSporeTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnGasSpore:Show()
			specWarnGasSpore:Play("targetyou")
			yellGasSpore:Yell()
		end
		if self.Options.SetIconOnGasSpore then
			local maxIcon = self:IsDifficulty("normal25", "heroic25") and 3 or 2
			self:SetSortedIcon("roster", 0.3, args.destName, 1, maxIcon, false, "AnnounceSporeIcons")
		end
		self:Unschedule(warnGasSporeTargets)
		if #gasSporeTargets >= 3 then
			warnGasSporeTargets()
		else
			self:Schedule(0.3, warnGasSporeTargets)
		end
	elseif args:IsSpellID(69166, 71912) then	-- Inhaled Blight
		local amount = args.amount or 1
		warnInhaledBlight:Show(args.destName, amount)
		if amount >= 3 then
			specWarnInhaled3:Show(amount)
			specWarnInhaled3:Play("holdit")
			timerPungentBlight:Start()
			timerInhaledBlight:Cancel() -- added due to the "keep" arg
		else	--Prevent timer from starting after 3rd stack since he won't cast it a 4th time, he does Pungent instead.
			timerInhaledBlight:Start()
		end
	elseif args:IsSpellID(72219, 72551, 72552, 72553) then	-- Gastric Bloat
		local amount = args.amount or 1
		warnGastricBloat:Show(args.destName, amount)
		timerGastricBloat:Start(args.destName)
		timerGastricBloatCD:Start()
		if args:IsPlayer() and amount >= 9 then
			specWarnGastricBloat:Show(amount)
			specWarnGastricBloat:Play("stackhigh")
		end
	elseif args:IsSpellID(69240, 71218, 73019, 73020) and args:IsDestTypePlayer() then	-- Vile Gas
		vileGasTargets[#vileGasTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnVileGas:Show()
			specWarnVileGas:Play("scatter")
			yellVileGas:Yell()
		end
		self:Unschedule(warnVileGasTargets)
		self:Schedule(0.8, warnVileGasTargets)
	elseif args:IsSpellID(69291, 72101, 72102, 72103) and args:IsDestTypePlayer() then	--Inoculated
		local amount = args.amount or 1
		if self.Options.AchievementCheck and DBM:GetRaidRank() > 0 and not self.vb.warnedfailed and self:AntiSpam(3, 1) then
			if amount == 3 then
				self.vb.warnedfailed = true
				SendChatMessage(L.AchievementFailed:format(args.destName, amount), "RAID_WARNING")
			end
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 69279 then	-- Gas Spore
		if self.Options.SetIconOnGasSpore then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == GetSpellInfo(72299) then -- Malleable Goo Summon Trigger (10 player normal) (the other 3 spell ids are not needed here since all spells have the same name)
		specWarnGoo:Show()
		specWarnGoo:Play("watchstep")
		if self:IsDifficulty("heroic25") then
			timerGooCD:Start()
		else
			timerGooCD:Start(30) -- what cd on 10nm/25nm/10hc ?
		end
	elseif spellName == GetSpellInfo(73032) then -- Pungent Blight
		timerInhaledBlight:Start()
	end
end
