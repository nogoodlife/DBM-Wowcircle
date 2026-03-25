local mod = DBM:NewMod("PortalTimers", "DBM-Party-WotLK", 12)
local L = mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(30658)

mod:RegisterEvents(
	"UPDATE_WORLD_STATES",
	"UNIT_DIED",
	"CHAT_MSG_MONSTER_YELL"
)
mod.noStatistics = true

local warningPortalNow	= mod:NewAnnounce("WarningPortalNow", 2, 57687)
local warningPortalSoon	= mod:NewAnnounce("WarningPortalSoon", 1, 57687)
local warningBossNow	= mod:NewAnnounce("WarningBossNow", 4, 33341)

local timerPortalIn	= mod:NewTimer(4.9, "TimerPortalIn", 57687, nil, nil, 1)
local timerAddsIn	= mod:NewTimer(15, "TimerAddsIn", 57687, nil, nil, 2)


--mod:AddBoolOption("ShowAllPortalTimers", false, "timer")--rate they spawn seems to accelerate slowly over time. thus making timers inaccurate by end of fight
mod:RemoveOption("HealthFrame")

local lastWave = 0
local killcount = 0

function mod:UPDATE_WORLD_STATES()
	local text = select(3, GetWorldStateUIInfo(2))
	if not text then return end
	local _, _, wave = string.find(text, L.WavePortal)
	if not wave then
		wave = 0
	end
	wave = tonumber(wave)
	lastWave = tonumber(lastWave)
	if wave < lastWave then
		lastWave = 0
		killcount = 0
	end
	if wave > lastWave then
		warningPortalSoon:Cancel()
		timerPortalIn:Cancel()
		if wave == 6 or wave == 12 or wave == 18 then
			warningBossNow:Show()
		else
			warningPortalNow:Show(wave)
			timerAddsIn:Start()
			--if self.Options.ShowAllPortalTimers then
			--	timerPortalIn:Start(122, wave + 1)
			--	warningPortalSoon:Schedule(112)
			--end
		end
		lastWave = wave
		killcount = 0
	end
end

function mod:UNIT_DIED(args)
	if bit.band(args.destGUID:sub(0, 5), 0x00F) == 3 then
		local z = mod:GetCIDFromGUID(args.destGUID)
		if z == 29266 or z == 29312 or z == 29313 or z == 29314 or z == 29315 or z == 29316 		-- bosses
		or z == 32226 or z == 32230 or z == 32231 or z == 32234 or z == 32235 or z == 32237 then	-- boss spirits (in case you wipe)
			timerPortalIn:Start(44.9, lastWave + 1)
			warningPortalSoon:Schedule(40)
		elseif z == 30695 or z == 30660 then
			timerPortalIn:Start(4.9, lastWave + 1)
			--warningPortalSoon:Schedule(2)
		elseif z == 30666 or z == 30667 or z == 30668 or z == 32191 then
			killcount = killcount + 1
			if (lastWave <= 12 and killcount == 3) or killcount == 4 then 
				timerPortalIn:Start(4.9, lastWave + 1)
				--warningPortalSoon:Schedule(2)
				killcount = 0
			end
		end
	end
end

-- 5hc: next portal 5s after prev guard/pack UNIT_DIED
-- 30695 Хранитель портала
-- 30660 Страж портала
-- волны 1-12	= 3 моба: 30666 Лазурный капитан + 30667 Лазурная колдунья + 30668 Лазурный налетчик + 32191 Лазурный ловец 
-- волны 13-17	= 4 моба

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Sealbroken or msg:find(L.Sealbroken) then
		self:SendSync("Wipe")
	end
end

function mod:OnSync(msg)
	if msg == "Wipe" then
		warningPortalSoon:Cancel()
		timerPortalIn:Cancel()
		killcount = 0
	end
end
