local mod	= DBM:NewMod("Patchwerk", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(16028)
mod:SetEncounterID(1118)

mod:RegisterCombat("combat_yell", L.yell1, L.yell2)

mod:RegisterEventsInCombat(
	"SPELL_DAMAGE 28308 59192",
	"SPELL_MISSED 28308 59192",
	"SPELL_AURA_APPLIED 28131",
	"UNIT_HEALTH boss1"
)

local warnFrenzySoon		= mod:NewSoonAnnounce(28131, 2, nil, nil) 						-- wtf is 2 ? color ? how arg4 "Tank|Healer" works ?
local specWarnFrenzy		= mod:NewSpecialWarningDefensive(28131, nil, nil, nil, 1, 2)	-- spellId, optionDefault, optionName, optionVersion, runSound, hasVoice, difficulty?
mod.vb.warned_preFrenzy = false

local enrageTimer	= mod:NewBerserkTimer(360)

mod:AddBoolOption("WarningHateful", false, "announce", nil, nil, nil, 28308)

local timerAchieve	= mod:NewAchievementTimer(180, 1857)

local function announceStrike(target, damage)
	SendChatMessage(L.HatefulStrike:format(target, damage), "RAID")
end

function mod:OnCombatStart(delay)
	mod.vb.warned_preFrenzy = false
	enrageTimer:Start(-delay)
	timerAchieve:Start(-delay)
end

function mod:SPELL_DAMAGE(_, _, _, _, destName, _, spellId, _, _, amount)
	if (spellId == 28308 or spellId == 59192) and self.Options.WarningHateful and DBM:GetRaidRank() >= 1 then
		announceStrike(destName, amount or 0)
	end
end

function mod:SPELL_MISSED(_, _, _, _, destName, _, spellId, _, _, missType)
	if (spellId == 28308 or spellId == 59192) and self.Options.WarningHateful and DBM:GetRaidRank() >= 1 then
		announceStrike(destName, getglobal("ACTION_SPELL_MISSED_"..(missType)) or "")
	end
end



function mod:UNIT_HEALTH(uId)
	if not self.vb.warned_preFrenzy and self:GetUnitCreatureId(uId) == 16028 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.11 then
		self.vb.warned_preFrenzy = true
		if self:IsDifficulty("heroic10", "heroic25") then
			warnFrenzySoon:Show()
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 28131 then
		
		if mod:IsTank() then
			specWarnFrenzy:Show()
			specWarnFrenzy:Play("defensive")
		end
	end
end
