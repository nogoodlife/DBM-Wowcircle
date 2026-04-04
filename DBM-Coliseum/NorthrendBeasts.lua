local mod	= DBM:NewMod("NorthrendBeasts", "DBM-Coliseum")
local L		= mod:GetLocalizedStrings()

local UnitExists, UnitGUID, UnitName = UnitExists, UnitGUID, UnitName
local GetSpellInfo = GetSpellInfo
local GetPlayerMapPosition, SetMapToCurrentZone = GetPlayerMapPosition, SetMapToCurrentZone
local sformat = string.format

mod:SetRevision("20250929220131")
mod:SetCreatureID(34796, 35144, 34799, 34797)
mod:SetEncounterID(629)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)
mod:SetMinSyncRevision(20220925000000)
mod:SetMinCombatTime(30)
mod:SetBossHPInfoToHighest()

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)
mod:RegisterEventsInCombat(
	"SPELL_CAST_START 66313 66330 67647 67648 67649 66794 67644 67645 67646 66821 66818 66901 67615 67616 67617 66902 67627 67628 67629",
	"SPELL_CAST_SUCCESS 67641 66883 67642 67643 66824 67612 67613 67614 66879 67624 67625 67626 66689 67650 67651 67652",
	"SPELL_AURA_APPLIED 67477 66331 67478 67479 67657 66759 67658 67659 66823 67618 67619 67620 66869 66758 66636 68335",
	"SPELL_AURA_APPLIED_DOSE 67477 66331 67478 67479 66636",
	"SPELL_AURA_REMOVED 66869 66758",
	"SPELL_DAMAGE 66320 67472 67473 67475 66317 66881 67638 67639 67640",
	"SPELL_MISSED 66320 67472 67473 67475 66317 66881 67638 67639 67640",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_DIED",
	"UNIT_SPELLCAST_START boss1",
	"UNIT_SPELLCAST_SUCCEEDED boss1 boss2"
)

local gormok = L.Gormok
local dreadscale = L.Dreadscale
local acidmaw = L.Acidmaw
local icehowl = L.Icehowl

-- General
local enrageTimer			= mod:NewBerserkTimer(223) -- enrage when?
local timerCombatStart		= mod:NewCombatTimer(51.2) -- PLAYER_REGEN_DISABLED
local timerEngage			= mod:NewTimer(11.4, "TimerEngage", 1180, nil, nil, 6)
local timerNextBoss			= mod:NewTimer(170, "TimerNextBoss", 2457, nil, nil, 1)

mod:AddRangeFrameOption("10")

-- Stage One: Gormok the Impaler
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..gormok)
local warnImpaleOn			= mod:NewStackAnnounce(66331, 2, nil, "Tank|Healer")
local warnFireBomb			= mod:NewSpellAnnounce(66317, 3, nil, false)
local WarningSnobold		= mod:NewAnnounce("WarningSnobold", 4)

local specWarnImpale3		= mod:NewSpecialWarningStack(66331, nil, 3, nil, nil, 1, 6)
local specWarnAnger3		= mod:NewSpecialWarningStack(66636, "Tank|Healer", 3, nil, nil, 1, 6)
local specWarnGTFO			= mod:NewSpecialWarningGTFO(66317, nil, nil, nil, 1, 8)
--local specWarnSilence		= mod:NewSpecialWarningSpell(66330, "SpellCaster") --probably remake into spellannounce, bcz we don't need 2 specwarnings for the same spell ?
local specWarnStompPreWarn	= mod:NewSpecialWarningPreWarn(66330, "SpellCaster", 3, nil, nil, 1, 2)

local timerNextStomp		= mod:NewNextTimer(20, 66330, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON, nil, mod:IsSpellCaster() and 3 or nil, 3) -- cd 20.06, 20.08
local timerImpaleCD			= mod:NewVarTimer("v8.0-10.0", 66331, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON, true)
local timerRisingAnger		= mod:NewVarTimer("v15.0-30.0", 66636, nil, nil, nil, 1, nil, nil, true) -- need more logs

local soundAuraMastery		= mod:NewSound(66330, "soundConcAuraMastery")

-- Stage Two: Acidmaw & Dreadscale
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..dreadscale.." & "..acidmaw)
local warnSlimePool			= mod:NewSpellAnnounce(66883, 2, nil, "Melee")
local warnToxin				= mod:NewTargetAnnounce(66823, 3)
local warnBile				= mod:NewTargetAnnounce(66869, 3)
local warnEnrageWorm		= mod:NewSpellAnnounce(68335, 3)

local specWarnToxin			= mod:NewSpecialWarningMoveTo(66823, nil, nil, nil, 1, 2)
local specWarnBile			= mod:NewSpecialWarningYou(66869, nil, nil, nil, 1, 2)

local timerSubmerge			= mod:NewCDSourceTimer(44.5, 66948, nil, nil, nil, 6, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local timerEmerge			= mod:NewNextSourceTimer(5, 66947, nil, nil, nil, 6, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local timerSweepCD			= mod:NewCDSourceTimer(16, 66794, nil, "Melee", nil, 3, nil, nil, true) -- REVIEW! variance?
local timerAcidicSpewCD		= mod:NewCDTimer(21, 66819, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON, true) -- Added "Keep" arg
local timerMoltenSpewCD		= mod:NewCDTimer(21, 66820, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON, true) -- REVIEW! remove keep cuz no variance?
local timerParalyticSprayCD	= mod:NewCDTimer(6, 66901, nil, nil, nil, 3, nil, nil, true) -- REVIEW! ~6s variance? -- 11.23, 6.88, 11.27, 6.30
local timerBurningSprayCD	= mod:NewCDTimer(17.1, 66902, nil, nil, nil, 3, nil, nil, true) -- REVIEW! check variance?
local timerParalyticBiteCD	= mod:NewCDTimer(15, 66824, nil, "Melee", nil, 3, nil, nil, true) -- Added "Keep" arg
local timerBurningBiteCD	= mod:NewCDTimer(15, 66879, nil, "Melee", nil, 3, nil, nil, true) -- REVIEW! remove keep cuz no variance?
local timerSlimePoolCD		= mod:NewCDSourceTimer(12, 66883, nil, "Melee", nil, 3) -- Dreadscale: 12.09 12.08 12.5 12.55 12.10;   Acidmaw: 12.08 12.06 12.08 12.06

mod:AddSetIconOption("SetIconOnBileTarget", 66869, false, 0, {1, 2, 3, 4, 5, 6, 7, 8})

-- Stage Three: Icehowl
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3)..": "..icehowl)
local warnBreath			= mod:NewSpellAnnounce(66689, 2)
local warnRage				= mod:NewSpellAnnounce(66759, 3)
local warnCharge			= mod:NewTargetNoFilterAnnounce(52311, 4)

local specWarnCharge		= mod:NewSpecialWarningRun(52311, nil, nil, nil, 4, 2)
local specWarnChargeNear	= mod:NewSpecialWarningClose(52311, nil, nil, nil, 3, 2)
local specWarnFrothingRage	= mod:NewSpecialWarningDispel(66759, "RemoveEnrage", nil, nil, 1, 2)

local timerBreath			= mod:NewCastTimer(5, 66689, nil, nil, nil, 3) -- 5s channel. is it random target or tank?
local timerBreathCD			= mod:NewCDTimer(20, 66689, nil, nil, nil, 3, nil, nil, true)
local timerStaggeredDaze	= mod:NewBuffActiveTimer(15, 66758, nil, nil, nil, 5, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerNextCrash		= mod:NewCDTimer(53, 66683, nil, nil, nil, 2, nil, DBM_COMMON_L.MYTHIC_ICON, true) -- REVIEW! variance? v53-54.2 ?

mod:AddSetIconOption("SetIconOnChargeTarget", 52311, true, 0, {8})
mod:AddBoolOption("ClearIconsOnIceHowl", true)
mod:AddBoolOption("IcehowlArrow")

mod:GroupSpells(66902, 66869)--Burning Spray with Burning Bile
mod:GroupSpells(66901, 66823)--Paralytic Spray with Toxic Bile
mod:GroupSpells(52311, 66758, 66759)--Furious Charge, Staggering Daze, and Frothing Rage

local bileName = DBM:GetSpellInfo(66869)
local phases = {}
local acidmawEngaged = false
--local acidmawSubmerged = false
local dreadscaleEngaged = false
mod.vb.burnIcon = 1
mod.vb.DreadscaleMobile = true
mod.vb.AcidmawMobile = true
mod.vb.DreadscaleDead = false
mod.vb.AcidmawDead = false
local ParalyticSprayCount = 1

local function updateHealthFrame(phase)
	if phases[phase] then
		return
	end
	phases[phase] = true
	mod.vb.phase = phase
	if phase == 1 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(34796, gormok)
	elseif phase == 2 then
		DBM.BossHealth:AddBoss(35144, acidmaw)
		DBM.BossHealth:AddBoss(34799, dreadscale)
	elseif phase == 3 then
		DBM.BossHealth:AddBoss(34797, icehowl)
	end
end

local function isBuffOwner(uId, spellId)
	if not uId and not spellId then return end
	local _, _, _, _, _, _, _, unitCaster = DBM:UnitBuff(uId, spellId)
	if unitCaster == uId then
		return true
	else
		return false
	end
end

local function GormokEngage(self, timeOffset)
	specWarnStompPreWarn:Schedule(11.5-timeOffset) -- 3s pre-warn
	if self.Options.soundConcAuraMastery and isBuffOwner("player", 19746) then -- Concentration Aura Mastery by a Paladin will negate the interrupt effect of Staggering Stomp
		soundAuraMastery:Schedule(11.5-timeOffset, "Interface\\AddOns\\DBM-Core\\sounds\\PlayerAbilities\\AuraMastery.ogg")
	else
		specWarnStompPreWarn:ScheduleVoice(11.5-timeOffset, "silencesoon")
	end
	timerNextStomp:Start(14.5-timeOffset) -- pull:14.54
	timerImpaleCD:Start(sformat("v%s-%s", 16.0-timeOffset, 18.5-timeOffset))
	timerRisingAnger:Start(sformat("v%s-%s", 15.0-timeOffset, 30.0-timeOffset)) -- 15-30 ? need more logs
end

function mod:OnCombatStart(delay)
	table.wipe(phases)
	acidmawEngaged = false
	--acidmawSubmerged = false
	dreadscaleEngaged = false
	self.vb.burnIcon = 8
	self.vb.DreadscaleMobile = true
	self.vb.AcidmawMobile = true
	self.vb.DreadscaleDead = false
	self.vb.AcidmawDead = false
	ParalyticSprayCount = 1
	self:SetStage(1)
	timerEngage:Start(11.4-delay)
	self:Schedule(11.4-delay, GormokEngage, self, 11.4-delay)	--GormokEngage(self, timeOffset)
	if self:IsHeroic() then
		timerNextBoss:Start(-delay)
	end
	updateHealthFrame(1)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 66313 then									-- FireBomb (Impaler)
		warnFireBomb:Show()
	elseif args:IsSpellID(66330, 67647, 67648, 67649) then		-- Staggering Stomp
		timerNextStomp:Start()
--		specWarnSilence:Show()
		specWarnStompPreWarn:Schedule(17) -- prewarn 3 sec before next
		if self.Options.soundConcAuraMastery and isBuffOwner("player", 19746) then -- Concentration Aura Mastery by a Paladin will negate the interrupt effect of Staggering Stomp
			soundAuraMastery:Schedule(17, "Interface\\AddOns\\DBM-Core\\sounds\\PlayerAbilities\\AuraMastery.ogg")
		else
			specWarnStompPreWarn:ScheduleVoice(17, "silencesoon")
		end
	elseif args:IsSpellID(66794, 67644, 67645, 67646) and self:AntiSpam() then		-- Sweep stationary worm -- on circle antispam needed, source: @trustmebro
		timerSweepCD:Start(args.sourceName)
	elseif spellId == 66821 then							-- Molten spew
		timerMoltenSpewCD:Start()
	elseif spellId == 66818 then							-- Acidic Spew
		timerAcidicSpewCD:Start()
	elseif args:IsSpellID(66901, 67615, 67616, 67617) then		-- Paralytic Spray
		ParalyticSprayCount = ParalyticSprayCount + 1
		if ParalyticSprayCount == 2 or ParalyticSprayCount == 4 then
			timerParalyticSprayCD:Start(10.85)
		elseif ParalyticSprayCount == 3 or ParalyticSprayCount == 5 then
			timerParalyticSprayCD:Start(6.7)
		else
			timerParalyticSprayCD:Start(17.1)
		end
	elseif args:IsSpellID(66902, 67627, 67628, 67629) then		-- Burning Spray
		self.vb.burnIcon = 1
		timerBurningSprayCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(67641, 66883, 67642, 67643) then			-- Slime Pool Cloud Spawn
		warnSlimePool:Show()
		timerSlimePoolCD:Start(args.sourceName)
	elseif args:IsSpellID(66824, 67612, 67613, 67614) then		-- Paralytic Bite
		timerParalyticBiteCD:Start()
	elseif args:IsSpellID(66879, 67624, 67625, 67626) then		-- Burning Bite
		timerBurningBiteCD:Start()
	elseif args:IsSpellID(66689, 67650, 67651, 67652) then		-- Arctic Breath
		timerBreath:Start()
		timerBreathCD:Start()
		warnBreath:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if args:IsSpellID(67477, 66331, 67478, 67479) then	-- Impale
		timerImpaleCD:Start()
		warnImpaleOn:Show(args.destName, 1)
	elseif args:IsSpellID(67657, 66759, 67658, 67659) then	-- Frothing Rage
		timerBreathCD:Start(5.5) -- variance? (Lordaeron 10N [2024-07-04]@[22:52:09]) - 5.5
		warnRage:Show()
		specWarnFrothingRage:Show()
		specWarnFrothingRage:Play("trannow")
	elseif args:IsSpellID(66823, 67618, 67619, 67620) then	-- Paralytic Toxin
		warnToxin:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnToxin:Show(bileName)
			specWarnToxin:Play("targetyou")
		end
	elseif spellId == 66869 then	-- Burning Bile
		warnBile:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnBile:Show()
			specWarnBile:Play("targetyou")
		end
		if self.Options.SetIconOnBileTarget and self.vb.burnIcon < 9 then
			self:SetIcon(args.destName, self.vb.burnIcon)
			self.vb.burnIcon = self.vb.burnIcon + 1
		end
	elseif spellId == 66758 then	-- Staggered Daze
		timerStaggeredDaze:Start()
	elseif spellId == 66636 then	-- Rising Anger
		WarningSnobold:Show(args.destName)
		timerRisingAnger:Start()
	elseif spellId == 68335 then	-- Enrage
		warnEnrageWorm:Show()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(67477, 66331, 67478, 67479) then	-- Impale
		local amount = args.amount or 1
		timerImpaleCD:Start()
		if (amount >= 3) or (amount >= 2 and self:IsHeroic()) then
			if args:IsPlayer() then
				specWarnImpale3:Show(amount)
				specWarnImpale3:Play("stackhigh")
			else
				warnImpaleOn:Show(args.destName, amount)
			end
		end
	elseif args.spellId == 66636 then	-- Rising Anger
		local amount = args.amount or 1
		WarningSnobold:Show(args.destName)
		if amount <= 3 then
			timerRisingAnger:Start()
		elseif amount >= 4 then -- only 4 snobolds
			timerRisingAnger:Stop()
			specWarnAnger3:Show(amount)
			specWarnAnger3:Play("stackhigh")
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 66869 then
		if self.Options.SetIconOnBileTarget then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 66758 then -- Staggered Daze
		timerBreathCD:Start(5) -- variance? ~ 4.3 + ?
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
	if ((spellId == 66320 or spellId == 67472 or spellId == 67473 or spellId == 67475 or spellId == 66317) or (spellId == 66881 or spellId == 67638 or spellId == 67639 or spellId == 67640)) and destGUID == UnitGUID("player") then	-- Fire Bomb (66317 is impact damage, not avoidable but leaving in because it still means earliest possible warning to move. Other 4 are tick damage from standing in it) // Slime Pool
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if (msg:match(L.Charge) or msg:find(L.Charge)) and target then
		target = DBM:GetUnitFullName(target)
		warnCharge:Show(target)
		if self.Options.ClearIconsOnIceHowl then
			self:ClearIcons()
		end
		if target == UnitName("player") then
			specWarnCharge:Show()
			specWarnCharge:Play("justrun")
			if self.Options.PingCharge then
				Minimap:PingLocation()
			end
		elseif self:CheckNearby(11, target) then
			specWarnChargeNear:Show(target)
			specWarnChargeNear:Play("runaway")
		end
		if self.Options.IcehowlArrow then
			local uId = DBM:GetRaidUnitId(target)
			local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
			DBM.Arrow:ShowRunAway(x, y, 12, 5)
		end
		if self.Options.SetIconOnChargeTarget then
			self:SetIcon(target, 8, 5)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.CombatStart or msg:find(L.CombatStart) then --Gormok the Impaler
		timerCombatStart:Start()
		-- 0.00 PLAYER_REGEN_DISABLED 				-- player entering combat
		-- +0.4-0.5 INSTANCE_ENCOUNTER_ENGAGE_UNIT	-- DBM StartCombat
		-- +11.4-11.5 UNIT_TARGET 					-- actuall bossfight start ?
	elseif msg == L.Phase2 or msg:find(L.Phase2) then
		self:SetStage(1.5)
--		self:ScheduleMethod(13.5, "WormsEmerge")
		timerCombatStart:Start(12.7)
		timerNextBoss:Cancel()
		updateHealthFrame(2)
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(10)
		end
		self:RegisterShortTermEvents(
			"INSTANCE_ENCOUNTER_ENGAGE_UNIT"
		)
	elseif msg == L.Phase3 or msg:find(L.Phase3) then
		updateHealthFrame(3)
		self:SetStage(2.5)
		if self:IsHeroic() then
			enrageTimer:Start()
		end
		timerCombatStart:Start(9)
		timerNextBoss:Cancel()
		timerSubmerge:Cancel()
		self:UnscheduleMethod("acidmawSubmerge")
		self:UnscheduleMethod("dreadscaleSubmerge")
		timerEmerge:Cancel()
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
		self:RegisterShortTermEvents(
			"INSTANCE_ENCOUNTER_ENGAGE_UNIT"
		)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 34796 then
		specWarnStompPreWarn:Cancel()
		specWarnStompPreWarn:CancelVoice()
		soundAuraMastery:Cancel()
		timerNextStomp:Stop()
		timerImpaleCD:Stop()
		timerRisingAnger:Stop()
		DBM.BossHealth:RemoveBoss(cid) -- remove Gormok from the health frame
	elseif cid == 35144 then -- Acidmaw dead
		self.vb.AcidmawDead = true
		timerParalyticSprayCD:Cancel()
		timerParalyticBiteCD:Cancel()
		timerAcidicSpewCD:Cancel()
		timerSubmerge:Cancel(acidmaw)
		self:UnscheduleMethod("acidmawSubmerge")
		if self.vb.AcidmawMobile then
			timerSlimePoolCD:Cancel(args.destName)
		else
			timerSweepCD:Cancel(args.destName)
		end
		if self.vb.DreadscaleDead then
			timerNextBoss:Cancel()
			DBM.BossHealth:RemoveBoss(35144)
			DBM.BossHealth:RemoveBoss(34799)
		end
	elseif cid == 34799 then -- Dreadscale dead
		self.vb.DreadscaleDead = true
		timerBurningSprayCD:Cancel()
		timerBurningBiteCD:Cancel()
		timerMoltenSpewCD:Cancel()
		timerSubmerge:Cancel(dreadscale)
		self:UnscheduleMethod("dreadscaleSubmerge")
		if self.vb.DreadscaleMobile then
			timerSlimePoolCD:Cancel(args.destName)
		else
			timerSweepCD:Cancel(args.destName)
		end
		if self.vb.AcidmawDead then
			timerNextBoss:Cancel()
			DBM.BossHealth:RemoveBoss(35144)
			DBM.BossHealth:RemoveBoss(34799)
		end
	elseif cid == 34797 then
		DBM:EndCombat(self)
	end
end

function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	for i = 1, 5 do
		local unitID = "boss"..i
		if UnitExists(unitID) then
			local cid = self:GetUnitCreatureId(unitID)
			local bossName = UnitName(unitID)
			if cid == 35144 and not acidmawEngaged then -- Acidmaw (stationary on engage)
				--print("IEEU Acidmaw PHASE_MOBILE: " .. tostring(self.vb.AcidmawMobile))
				DBM:Debug("Acidmaw PHASE_MOBILE: " .. tostring(self.vb.AcidmawMobile), 2)
				acidmawEngaged = true
				if acidmawEngaged and dreadscaleEngaged then
					self:UnregisterShortTermEvents()
				end
			elseif cid == 34799 and not dreadscaleEngaged then -- Dreadscale (mobile on engage)
				--print("IEEU Dreadscale PHASE_MOBILE: " .. tostring(self.vb.DreadscaleMobile))
				DBM:Debug("Dreadscale PHASE_MOBILE: " .. tostring(self.vb.DreadscaleMobile), 2)
				self:SetStage(2)
				dreadscaleEngaged = true
				timerSubmerge:Start(44.5, bossName)
				self:ScheduleMethod(44.5, "dreadscaleSubmerge")
				timerSlimePoolCD:Start(13.4, bossName)
				timerMoltenSpewCD:Start(9.4)
				timerBurningBiteCD:Start(14.4)
				if self:IsHeroic() then
					timerNextBoss:Start() -- what timer on circle?
				end
				if acidmawEngaged and dreadscaleEngaged then
					self:UnregisterShortTermEvents()
				end
			elseif cid == 34797 then -- Icehowl
				self:SetStage(3)
				timerBreathCD:Start(14.5)
				timerNextCrash:Start(30)
				self:UnregisterShortTermEvents()
			end
			--if unitID == "boss2" then
			--	self:UnregisterShortTermEvents() -- both worms are on boss frames, job finished. -- what if boss1 Gormok still alive, boss2=Dreadscale ? we are fucked ?
			--end
		end
	end
end

function mod:acidmawSubmerge()
	timerAcidicSpewCD:Stop()
	timerParalyticBiteCD:Stop()
	timerParalyticSprayCD:Stop()
	timerSlimePoolCD:Stop(acidmaw)
	timerSweepCD:Stop(acidmaw)
	timerEmerge:Start(8.1, acidmaw)
end

function mod:dreadscaleSubmerge()
	timerMoltenSpewCD:Stop()
	timerBurningBiteCD:Stop()
	timerBurningSprayCD:Stop()
	timerSlimePoolCD:Stop(dreadscale)
	timerSweepCD:Stop(dreadscale)
	timerEmerge:Start(8.1, dreadscale)
end


function mod:UNIT_SPELLCAST_START(_, spellName)
	if spellName == GetSpellInfo(66683) and self:AntiSpam() then -- Massive Crash -- so massive that it crashes x2times at once on circle =_=
		timerBreathCD:Cancel()
		timerNextCrash:Start()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, spellName)
	if spellName == GetSpellInfo(66948) then -- Submerge --no events for 66948
	print("DBM: UNIT_SPELLCAST_SUCCEEDED GetSpellInfo(66948) DETECTED! plz report")
	--[[
	local npcId = self:GetUnitCreatureId(uId)
		local unitName = UnitName(uId) or UNKNOWN
		DBM:Debug("Submerge casted by " .. unitName.. ": " .. tostring(npcId), 2)
		if npcId == 35144 then -- Acidmaw
			acidmawSubmerged = true -- this workaround is necessary since I had one log (25H Lordaeron 2022/09/24) that Emerged fired 1.0s after IEEU, so enforce submerge/emerge conditional logic
			timerAcidicSpewCD:Stop()
			timerParalyticBiteCD:Stop()
			timerParalyticSprayCD:Stop()
			timerSlimePoolCD:Stop(acidmaw)
			timerSweepCD:Stop(acidmaw)
			timerEmerge:Start(7.5, unitName) -- REVIEW! 3s delay from visual to emerge (25H Lordaeron 2022/09/03) - 8, 7
		elseif npcId == 34799 then -- Dreadscale
			timerMoltenSpewCD:Stop()
			timerBurningBiteCD:Stop()
			timerBurningSprayCD:Stop()
			timerSlimePoolCD:Stop(dreadscale)
			timerSweepCD:Stop(dreadscale)
			timerEmerge:Start(6.5, unitName) -- (25H Lordaeron 2022/09/03) - 7, 6
		end
	]]
	elseif spellName == GetSpellInfo(66947) then -- Emerge
		local npcId = self:GetUnitCreatureId(uId)
		local unitName = UnitName(uId) or UNKNOWN
		DBM:Debug("Emerge casted by " .. unitName.. ": " .. tostring(npcId), 2)
		if npcId == 35144 then -- Acidmaw
			timerEmerge:Stop(acidmaw)
			self.vb.AcidmawMobile = not self.vb.AcidmawMobile
			--acidmawSubmerged = false
			--print("Acidmaw PHASE_MOBILE: " .. tostring(self.vb.AcidmawMobile))
			DBM:Debug("Acidmaw PHASE_MOBILE: " .. tostring(self.vb.AcidmawMobile), 2)
			timerSubmerge:Start(42, acidmaw)
			self:ScheduleMethod(42, "acidmawSubmerge")
			if self.vb.AcidmawMobile then
				timerSlimePoolCD:Start(9, acidmaw)
				timerParalyticBiteCD:Start(11.9)
				timerAcidicSpewCD:Start(15.9)
			else
				timerSweepCD:Start(13.4, acidmaw)
				if ParalyticSprayCount == 1 then
					timerParalyticSprayCD:Start(5.5)
				else
					timerParalyticSprayCD:Start(14.9)
				end
			end
		elseif npcId == 34799 then -- Dreadscale
			timerEmerge:Stop(dreadscale)
			self.vb.DreadscaleMobile = not self.vb.DreadscaleMobile
			--print("Dreadscale PHASE_MOBILE: " .. tostring(self.vb.DreadscaleMobile))
			DBM:Debug("Dreadscale PHASE_MOBILE: " .. tostring(self.vb.DreadscaleMobile), 2)
			timerSubmerge:Start(42, dreadscale)
			self:ScheduleMethod(42, "dreadscaleSubmerge")
			if self.vb.DreadscaleMobile then
				timerSlimePoolCD:Start(9, dreadscale)
				timerMoltenSpewCD:Start(18)
				timerBurningBiteCD:Start(12)
			else
				timerSweepCD:Start(13.4, dreadscale)
				timerBurningSprayCD:Start(14.9)
			end
		end
	end
end
