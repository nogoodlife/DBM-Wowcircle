local mod	= DBM:NewMod("Deathbringer", "DBM-Icecrown", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20251010110810")
mod:SetCreatureID(37813)
mod:SetEncounterID(848)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)
mod:SetMinSyncRevision(20220905000000)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 73058 72378", -- 72293",
	"SPELL_CAST_SUCCESS 72410 72769 72385 72441 72442 72443",
	"SPELL_AURA_APPLIED 72293 72385 72441 72442 72443 72737", -- 19753",
	"SPELL_AURA_REMOVED 72385 72441 72442 72443",
	"SPELL_SUMMON 72172 72173 72356 72357 72358",
	"UNIT_DIED",
	"UNIT_HEALTH boss1"
)

--local canShadowmeld = select(2, UnitRace("player")) == "NightElf"
--local canVanish = select(2, UnitClass("player")) == "ROGUE"

-- General
local timerCombatStart		= mod:NewCombatTimer(100.45)	-- set real timers at CHAT_MSG_MONSTER_YELL(msg)
local enrageTimer			= mod:NewBerserkTimer(480)

mod:RemoveOption("HealthFrame")
mod:AddBoolOption("RunePowerFrame", false, "misc")
--mod:AddBoolOption("RemoveDI")

-- Deathbringer Saurfang
mod:AddTimerLine(BOSS)
local warnFrenzySoon		= mod:NewSoonAnnounce(72737, 2, nil, "Tank|Healer")
local warnFrenzy			= mod:NewSpellAnnounce(72737, 2, nil, "Tank|Healer")
local warnBloodNova			= mod:NewSpellAnnounce(72378, 2)
local warnMark				= mod:NewTargetCountAnnounce(72293, 4, 72293, nil, 28836, nil, nil, nil, true)
local warnBoilingBlood		= mod:NewTargetNoFilterAnnounce(72385, 2, nil, "Healer")
local warnRuneofBlood		= mod:NewTargetNoFilterAnnounce(72410, 3, nil, "Tank|Healer")

local specwarnMark			= mod:NewSpecialWarningYou(72444, nil, 28836, nil, 1, 2)
local specwarnRuneofBlood	= mod:NewSpecialWarningTaunt(72410, nil, nil, nil, 1, 2)
local specwarnRuneofBloodYou= mod:NewSpecialWarningYou(72410, "Tank")

local timerRuneofBlood		= mod:NewNextTimer(19.5, 72410, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerBoilingBlood		= mod:NewVarTimer("v15.5-19.5", 72385, nil, "Healer", nil, 5, nil, DBM_COMMON_L.HEALER_ICON, true)
local timerBloodNova		= mod:NewCDTimer(20, 72378, nil, nil, nil, 2, nil, nil, true)

--local soundSpecWarnMark		= mod:NewSound(72293, nil, canShadowmeld or canVanish)

mod:AddRangeFrameOption(12, 72378, "Ranged")
mod:AddInfoFrameOption(72370, false)--Off by default, since you can literally just watch the bosses power bar
mod:AddSetIconOption("BoilingBloodIcons", 72385, false, 0, {1, 2, 3})

-- Blood Beasts
mod:AddTimerLine(DBM_COMMON_L.ADDS)
local warnAddsSoon			= mod:NewPreWarnAnnounce(72173, 10, 3)
local warnAdds				= mod:NewSpellAnnounce(72173, 4)

local specWarnScentofBlood	= mod:NewSpecialWarningSpell(72769, nil, nil, nil, nil, nil, 3) -- Heroic Ablility
local specWarnBeastOnYou	= mod:NewSpecialWarning("SpecWarnBloodBeastSwing", false, nil, nil, nil, 1, 2, nil, 72173, 72173)

local timerCallBloodBeast	= mod:NewNextTimer(40, 72173, nil, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON, nil, 3)
local timerNextScentofBlood	= mod:NewNextTimer(10, 72769, nil, nil, nil, 2) -- 10 seconds after Beasts spawn, if any of them is alive

mod:AddSetIconOption("BeastIcons", 72173, true, 5, {8, 7, 6, 5, 4})

mod.vb.warned_preFrenzy = false
mod.vb.boilingBloodIcon = 1
mod.vb.beastIcon = 8
mod.vb.Mark = 0
mod.vb.bloodBeastAlive = 0
local spellName = DBM:GetSpellInfo(72370)

do	-- add the additional Rune Power Bar
	local UnitGUID = UnitGUID
	local last = 0
	local function getRunePowerPercent()
		local guid = UnitGUID("focus")
		if mod:GetCIDFromGUID(guid) == 37813 then
			last = math.floor(UnitPower("focus")/UnitPowerMax("focus") * 100)
			return last
		end
		for i = 0, GetNumRaidMembers(), 1 do
			local unitId = ((i == 0) and "target") or ("raid"..i.."target")
			guid = UnitGUID(unitId)
			if mod:GetCIDFromGUID(guid) == 37813 then
				last = math.floor(UnitPower(unitId)/UnitPowerMax(unitId) * 100)
				return last
			end
		end
		return last
	end
	function mod:CreateBossRPFrame()
		DBM.BossHealth:AddBoss(getRunePowerPercent, L.RunePower)
	end
end

--[[function mod:FallenMarkTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		if canShadowmeld then
			soundSpecWarnMark:Play("Interface\\AddOns\\DBM-Core\\sounds\\PlayerAbilities\\Shadowmeld.ogg")
		elseif canVanish then
			soundSpecWarnMark:Play("Interface\\AddOns\\DBM-Core\\sounds\\PlayerAbilities\\Vanish.ogg")
		end
	end
end]]

function mod:OnCombatStart(delay)
	if self.Options.RunePowerFrame then
		DBM.BossHealth:Show(L.name)
		DBM.BossHealth:AddBoss(37813, L.name)
		self:ScheduleMethod(0.5, "CreateBossRPFrame")
	end
	if self:IsNormal() then
		enrageTimer:Start(-delay)
	else
		enrageTimer:Start(360-delay)
	end
	timerCallBloodBeast:Start(-delay) -- cd = 40
	warnAddsSoon:Schedule(35-delay)
	timerBloodNova:Start(-delay)
	timerRuneofBlood:Start(19.2-delay)
	timerBoilingBlood:Start(19.1-delay)
	self.vb.warned_preFrenzy = false
	self.vb.boilingBloodIcon = 1
	self.vb.beastIcon = 8
	self.vb.Mark = 0
	self.vb.bloodBeastAlive = 0
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(12)
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(spellName)
		DBM.InfoFrame:Show(1, "enemypower", 2)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
	DBM.BossHealth:Clear()
	self:UnregisterShortTermEvents()
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(73058, 72378) then	-- Blood Nova (only 2 cast IDs, 4 spell damage IDs, and one dummy)
		warnBloodNova:Show()
		timerBloodNova:Start()
--	elseif args.spellId == 72293 then
--		self:BossTargetScanner(37813, "FallenMarkTarget", 0.01, 10)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 72410 then
		warnRuneofBlood:Show(args.destName)
		if not args:IsPlayer() then
			specwarnRuneofBlood:Show(args.destName)
			specwarnRuneofBlood:Play("tauntboss")
		else
			specwarnRuneofBloodYou:Show()
		end
		timerRuneofBlood:Start()
	elseif spellId == 72769 then
		specWarnScentofBlood:Show()
	elseif args:IsSpellID(72385, 72441, 72442, 72443) then -- Boiling Blood
		self.vb.boilingBloodIcon = 1
		timerBoilingBlood:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 72293 then		-- Mark of the Fallen Champion
		self.vb.Mark = self.vb.Mark + 1
		warnMark:Show(self.vb.Mark, args.destName)
		if args:IsPlayer() then
			specwarnMark:Show()
			specwarnMark:Play("defensive")
		end
	elseif args:IsSpellID(72385, 72441, 72442, 72443) then	-- Boiling Blood
		if self.Options.BoilingBloodIcons then
			self:SetIcon(args.destName, self.vb.boilingBloodIcon)
		end
		self.vb.boilingBloodIcon = self.vb.boilingBloodIcon + 1
		warnBoilingBlood:CombinedShow(0.5, args.destName)
	elseif spellId == 72737 then						-- Frenzy
		warnFrenzy:Show()
--	elseif spellId == 19753 and self:IsInCombat() and self.Options.RemoveDI then	-- Remove Divine Intervention
--		CancelUnitBuff("player", GetSpellInfo(19753))
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(72385, 72441, 72442, 72443) and self.Options.BoilingBloodIcons then
		self:SetIcon(args.destName, 0)
	end
end

function mod:SPELL_SUMMON(args)
	if args:IsSpellID(72172, 72173) or args:IsSpellID(72356, 72357, 72358) then -- Summon Blood Beasts
		if self:AntiSpam(5) then
			self.vb.beastIcon = 8
			self.vb.bloodBeastAlive = self.vb.bloodBeastAlive + (self:IsDifficulty("normal25", "heroic25") and 5 or 2)
			warnAdds:Show()
			warnAddsSoon:Schedule(35)
			timerCallBloodBeast:Start() -- cd = 40
			if self:IsHeroic() then
				timerNextScentofBlood:Start()
			end
			self:RegisterShortTermEvents(
				"SWING_DAMAGE"
			)
		end
		if self.Options.BeastIcons then
			self:ScanForMobs(args.destGUID, 2, self.vb.beastIcon, 1, nil, 10, "BeastIcons")
			-- scanId=guid/cid, iconSetMethod, mobIcon, maxIcon, scanTable, scanningTime, optionName, allowFriendly, skipMarked, allAllowed, wipeGUID
		end
		self.vb.beastIcon = self.vb.beastIcon - 1
	end
end

function mod:SWING_DAMAGE(sourceGUID, _, _, destGUID)
	if destGUID == UnitGUID("player") and self:GetCIDFromGUID(sourceGUID) == 38508 then -- Blood Beast
		specWarnBeastOnYou:Show()
		specWarnBeastOnYou:Play("targetyou")
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 38508 then -- Blood Beast
		self.vb.bloodBeastAlive = self.vb.bloodBeastAlive - 1
		if self.vb.bloodBeastAlive == 0 then
			timerNextScentofBlood:Cancel()
			self:UnregisterShortTermEvents()
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if not self.vb.warned_preFrenzy and self:GetUnitCreatureId(uId) == 37813 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.33 then
		self.vb.warned_preFrenzy = true
		warnFrenzySoon:Show()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg:find(L.PullAlliance, 1, true) then
		timerCombatStart:Start(100.45)
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(12)
		end
	elseif msg:find(L.PullHorde, 1, true) then
		timerCombatStart:Start(99.83)
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(12)
		end
	end
end

--[[
  - PullAlliance > [DBM_Debug] INSTANCE_ENCOUNTER_ENGAGE_UNIT = 100.5 | 100.66
    - PullAlliance RU	= "Все павшие воины Орды, все дохлые псы Альянса – все пополнят армию Короля-лича. Даже сейчас валь'киры воскрешают ваших покойников, чтобы те стали частью Плети!"
    - PullAlliance EN	= "For every Horde soldier that you killed -- for every Alliance dog that fell, the Lich King's armies grew. Even now the val'kyr work to raise your fallen as Scourge."
		
	25HC
-101.99	"<4.72 14:30:51> [CHAT_MSG_MONSTER_YELL] Тогда выдвигаемся! Быст...#Мурадин Бронзобород#####0#0##0#142##0#", -- [34]
-100.5	"<6.21 14:30:52> [CHAT_MSG_MONSTER_YELL] Все павшие воины Орды, все дохлые псы Альянса – все пополнят армию Короля-лича. Даже сейчас валь'киры воскрешают ваших покойников, чтобы те стали частью Плети!#Саурфанг Смертоносный#####0#0##0#143##0#", -- [48]
-81.94	"<24.77 14:31:11> [CHAT_MSG_MONSTER_YELL] Я верил, что моя судьба лежит в другом месте - что однажды я буду служить великой цели. Мой отец подарил мне свои боевые доспехи и топор. Вскоре я нашел им хорошее применение.#Саурфанг Смертоносный#####0#0##0#144##0#", -- [291]
-70.94	"<35.77 14:31:22> [CHAT_MSG_MONSTER_YELL] Битва у Ангратар, Врат Гнева, была последней, я сражался с сильнейшими, Верховный Лорд Фордрагон до последнего поддерживал меня, но моя тщеславность и вера в великую цель все разрушила...#Саурфанг Смертоносный#####0#0##0#145##0#", -- [475]
-58.96	"<47.75 14:31:34> [CHAT_MSG_MONSTER_YELL] Ледяная Скорбь разбила мой топор, украла мою душу, Король-лич наделил меня мощью Плети, и сейчас...#Саурфанг Смертоносный#####0#0##0#146##0#", -- [678]
-51.95	"<54.76 14:31:41> [CHAT_MSG_MONSTER_YELL] Я ощутил что-то такое, чего не чувствовал прежде... Я... я жажду мести. Кровь за кровь.#Саурфанг Смертоносный#####0#0##0#147##0#", -- [784]
-45.96	"<60.75 14:31:47> [CHAT_MSG_MONSTER_YELL] Вы когда-нибудь чувствовали что-либо подобное?!#Саурфанг Смертоносный#####0#0##0#148##0#", -- [884]
-42		"<64.71 14:31:51> [CHAT_MSG_MONSTER_YELL] Меня охватывает непреодолимое желание схватить топор и сокрушить им моих врагов. Я готов сражаться до тех пор, пока рука не опустится в изнеможении.#Саурфанг Смертоносный#####0#0##0#149##0#", -- [944]
-32.94	"<73.77 14:32:00> [CHAT_MSG_MONSTER_YELL] Я не могу позволить Альянсу повеселиться сегодня.#Саурфанг Смертоносный#####0#0##0#150##0#", -- [1106]
-29.79	"<76.92 14:32:03> [CHAT_MSG_MONSTER_YELL] Сейчас все будет еще хуже! Идите сюда, я покажу вам, какой силой меня наделил Король-лич!#Саурфанг Смертоносный#####0#0##0#151##0#", -- [1153]
-11.9	"<94.81 14:32:21> [CHAT_MSG_MONSTER_YELL] Один орк против войска Альянса???#Мурадин Бронзобород#####0#0##0#152##0#", -- [1441]
-5.91	"<100.80 14:32:27> [CHAT_MSG_MONSTER_YELL] В атаку!#Мурадин Бронзобород#####0#0##0#153##0#", -- [1541]
-3.96	"<102.75 14:32:29> [CHAT_MSG_MONSTER_YELL] Дворфы...#Саурфанг Смертоносный#####0#0##0#154##0#", -- [1576]
00.00	"<106.71 14:32:33> [DBM_Debug] INSTANCE_ENCOUNTER_ENGAGE_UNIT event fired for zoneId605#3#", -- [1663]
		"<106.72 14:32:33> [INSTANCE_ENCOUNTER_ENGAGE_UNIT] Fake Args:#boss1#nil#1#1#Саурфанг Смертоносный#37813#0xF1500093B500001C#worldboss#43926752#boss2#nil#nil#nil#??#1#nil#normal#0#boss3#nil#nil#nil#??#1#nil#normal#0#boss4#nil#nil#nil#??#1#nil#normal#0#boss5#nil#nil#nil#??#1#nil#normal#0#Real Args:#", -- [1725]
		"<106.72 14:32:33> [CHAT_MSG_MONSTER_YELL] ВО ИМЯ КОРОЛЯ-ЛИЧА!#Саурфанг Смертоносный#####0#0##0#155##0#", -- [1727]
		"<106.73 14:32:33> [PLAYER_REGEN_DISABLED] +Entering combat!", -- [1729]
		"<106.73 14:32:33> [UNIT_TARGET] -boss1:Саурфанг Смертоносный- [CanAttack:1#Exists:1#IsVisible:1#ID:37813#GUID:0xF1500093B500001C#Classification:worldboss#Health:43926752] - Target: Nglpriest#TargetOfTarget: Саурфанг Смертоносный", -- [1730]
		
	25HC
-100.66	"<6.92 17:24:43> [CHAT_MSG_MONSTER_YELL] Все павшие воины Орды, все дохлые псы Альянса – все пополнят армию Короля-лича. Даже сейчас валь'киры воскрешают ваших покойников, чтобы те стали частью Плети!#Саурфанг Смертоносный#####0#0##0#4613##0#", -- [64]
		"<25.43 17:25:02> [CHAT_MSG_MONSTER_YELL] Я верил, что моя судьба лежит в другом месте - что однажды я буду служить великой цели. Мой отец подарил мне свои боевые доспехи и топор. Вскоре я нашел им хорошее применение.#Саурфанг Смертоносный#####0#0##0#4614##0#", -- [595]
		"<36.42 17:25:13> [CHAT_MSG_MONSTER_YELL] Битва у Ангратар, Врат Гнева, была последней, я сражался с сильнейшими, Верховный Лорд Фордрагон до последнего поддерживал меня, но моя тщеславность и вера в великую цель все разрушила...#Саурфанг Смертоносный#####0#0##0#4615##0#", -- [919]
		"<48.42 17:25:25> [CHAT_MSG_MONSTER_YELL] Ледяная Скорбь разбила мой топор, украла мою душу, Король-лич наделил меня мощью Плети, и сейчас...#Саурфанг Смертоносный#####0#0##0#4616##0#", -- [1246]
		"<55.43 17:25:32> [CHAT_MSG_MONSTER_YELL] Я ощутил что-то такое, чего не чувствовал прежде... Я... я жажду мести. Кровь за кровь.#Саурфанг Смертоносный#####0#0##0#4617##0#", -- [1454]
		"<61.44 17:25:38> [CHAT_MSG_MONSTER_YELL] Вы когда-нибудь чувствовали что-либо подобное?!#Саурфанг Смертоносный#####0#0##0#4618##0#", -- [1622]
		"<65.39 17:25:42> [CHAT_MSG_MONSTER_YELL] Меня охватывает непреодолимое желание схватить топор и сокрушить им моих врагов. Я готов сражаться до тех пор, пока рука не опустится в изнеможении.#Саурфанг Смертоносный#####0#0##0#4619##0#", -- [1726]
		"<74.45 17:25:51> [CHAT_MSG_MONSTER_YELL] Я не могу позволить Альянсу повеселиться сегодня.#Саурфанг Смертоносный#####0#0##0#4620##0#", -- [1990]
		"<77.69 17:25:54> [CHAT_MSG_MONSTER_YELL] Сейчас все будет еще хуже! Идите сюда, я покажу вам, какой силой меня наделил Король-лич!#Саурфанг Смертоносный#####0#0##0#4621##0#", -- [2075]
		"<95.58 17:26:12> [CHAT_MSG_MONSTER_YELL] Один орк против войска Альянса???#Мурадин Бронзобород#####0#0##0#4622##0#", -- [2579]
-6.01	"<101.57 17:26:18> [CHAT_MSG_MONSTER_YELL] В атаку!#Мурадин Бронзобород#####0#0##0#4623##0#", -- [2755]
-4.07	"<103.51 17:26:20> [CHAT_MSG_MONSTER_YELL] Дворфы...#Саурфанг Смертоносный#####0#0##0#4624##0#", -- [2811]
00.00	"<107.58 17:26:24> [DBM_Debug] INSTANCE_ENCOUNTER_ENGAGE_UNIT event fired for zoneId605#3#", -- [2952]
		"<107.58 17:26:24> [INSTANCE_ENCOUNTER_ENGAGE_UNIT] Fake Args:#boss1#nil#1#1#Саурфанг Смертоносный#37813#0xF1500093B500001C#worldboss#43926752#boss2#nil#nil#nil#??#1#nil#normal#0#boss3#nil#nil#nil#??#1#nil#normal#0#boss4#nil#nil#nil#??#1#nil#normal#0#boss5#nil#nil#nil#??#1#nil#normal#0#Real Args:#", -- [3014]
		"<107.58 17:26:24> [CHAT_MSG_MONSTER_YELL] ВО ИМЯ КОРОЛЯ-ЛИЧА!#Саурфанг Смертоносный#####0#0##0#4625##0#", -- [3016]
		"<107.59 17:26:24> [PLAYER_REGEN_DISABLED] +Entering combat!", -- [3021]
		"<107.60 17:26:24> [UNIT_TARGET] -boss1:Саурфанг Смертоносный- [CanAttack:1#Exists:1#IsVisible:1#ID:37813#GUID:0xF1500093B500001C#Classification:worldboss#Health:43926752] - Target: Nglpriest#TargetOfTarget: Саурфанг Смертоносный", -- [3022]
		
		
  - PullHorde > [DBM_Debug] INSTANCE_ENCOUNTER_ENGAGE_UNIT = 99.88
    - PullHorde RU	= "Кор'крон, выдвигайтесь! Герои, будьте начеку. Плеть только что..."
    - PullHorde EN	= "Kor'kron, move out! Champions, watch your backs. The Scourge have been..."

	25HC
-99.88	"<10.19 12:44:50> [CHAT_MSG_MONSTER_YELL] Кор'крон, выдвигайтесь! Герои, будьте начеку. Плеть только что...#Верховный правитель Саурфанг#####0#0##0#265##0#", -- [73]
-94.91	"<15.16 12:44:55> [CHAT_MSG_MONSTER_YELL] Присоединись ко мне, отец. Перейди на мою сторону, и вместе мы разрушим этот мир во имя Плети и во славу Короля-лича!#Саурфанг Смертоносный#####0#0##0#266##0#", -- [173]
-62		"<48.07 12:45:27> [CHAT_MSG_MONSTER_YELL] Старый упрямец. У тебя нет шансов. Я сильнее и могущественнее, чем ты можешь представить.#Саурфанг Смертоносный#####0#0##0#268##0#", -- [1129]
-9.03	"<101.04 12:46:20> [CHAT_MSG_MONSTER_YELL] Жалкий старик! Ну что ж, герои. Хотите узнать, сколь могущественна Плеть?#Саурфанг Смертоносный#####0#0##0#273##0#", -- [2646]
00.00	"<110.07 12:46:29> [DBM_Debug] INSTANCE_ENCOUNTER_ENGAGE_UNIT event fired for zoneId605#3#", -- [2919]
		"<110.08 12:46:29> [INSTANCE_ENCOUNTER_ENGAGE_UNIT] Fake Args:#boss1#nil#1#1#Саурфанг Смертоносный#37813#0xF1500093B500001C#worldboss#43926752#boss2#nil#nil#nil#??#1#nil#normal#0#boss3#nil#nil#nil#??#1#nil#normal#0#boss4#nil#nil#nil#??#1#nil#normal#0#boss5#nil#nil#nil#??#1#nil#normal#0#Real Args:#", -- [2982]
		"<110.08 12:46:29> [CHAT_MSG_MONSTER_YELL] ВО ИМЯ КОРОЛЯ-ЛИЧА!#Саурфанг Смертоносный#####0#0##0#274##0#", -- [2984]
		"<110.10 12:46:30> [PLAYER_REGEN_DISABLED] +Entering combat!", -- [2987]
		"<110.11 12:46:30> [UNIT_TARGET] -boss1:Саурфанг Смертоносный- [CanAttack:1#Exists:1#IsVisible:1#ID:37813#GUID:0xF1500093B500001C#Classification:worldboss#Health:43926752] - Target: Nglpriest#TargetOfTarget: Саурфанг Смертоносный", -- [2988]
]]