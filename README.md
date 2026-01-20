<div align="center">

# DBM-Wowcircle [![Game Version](https://img.shields.io/badge/wow-3.3.5-blue.svg)](https://github.com/nogoodlife/DBM-Wowcircle)
</div>

**Здесь вы можете наблюдать за моими попытками поправить таймеры для серверов wowcircle.**

*Да, я тоже в шоке, что никто до сих пор даже не пытался, а если и пытался - не выложил в общий доступ.*

За основу взят https://github.com/Zidras/DBM-Warmane  
В первую очередь будут исправлены таймера ЦЛК и РС.  
По поводу остальных инстов и рейдов - пишите письма...  
Накс ХМ и Санвел ХМ? Незнаю, не видел =_=

> [!NOTE]
> Вердикт на 2026.01.20 : с цлк закончил, проверить бы еще, чтобы нигде не наложал xD
> оставил несколько лишних принтов в чат для теста


# ПЕРВАЯ УСТАНОВКА
> [!WARNING]  
> Если вы хотите сохранить ваши старые профили, сделайте бэкап папки WTF.  
> **Эта версия аддона НЕСОВМЕСТИМА со старыми настройками, вам нужно произвести чистую установку.**

1. В папке аддонов `Interface/Addons` **удалите каждую папку DBM** (все, что начинается с **DBM-**).
2. В папке `WTF/Account/[AccountName]/SavedVariables` **удалите каждый файл DBM** (все, что начинается с **DBM-**).
3. В **каждой** папке `WTF/Account/[AccountName]/[ServerName]/[CharacterName]/SavedVariables` **удалите каждый файл DBM** (все, что начинается с **DBM-**).

> [!CAUTION]  
> **Только удалив все файлы и настройки старого DBM можно приступать к установке.**

1. Скачайте аддон из основного репозитория **main** (https://github.com/nogoodlife/DBM-Wowcircle/archive/refs/heads/main.zip).
2. Внутри .zip файла откройте папку DBM-Circle-main, и скопируйте все папки (DBM-Core, DBM-GUI, и т.д.) в папку аддонов (Interface/Addons).
3. Запустите игровой клиент, зайдите на экран выбора персонажа, нажмите кнопку AddOns внизу слева, и включите аддон DBM со всеми его модулями:
![image](https://user-images.githubusercontent.com/10605951/127546459-1dd1eb99-8360-40c2-9ffa-093e365cd01b.png)
![image](https://user-images.githubusercontent.com/10605951/127546757-e086103a-34bd-48c5-8555-a734031e1ecc.png)

# HOW TO KEEP THE ADDON UPDATED
Updating DBM follows the standard procedure that applies to any addon installation. Everytime there are new changes*, do these steps:
1. Download the addon from the **main** repository (https://github.com/nogoodlife/DBM-Wowcircle/archive/refs/heads/main.zip).
2. Inside the zip file, open DBM-Wowcircle-main. Select all the folders (DBM-Core, DBM-GUI, etc) and press Copy (Ctrl+C).
3. (**Advisable**) On your addons folder (Interface/Addons), before pasting, select the DBM folders that are there and delete them (you will not lose your profiles doing this, don't worry - those are on WTF folder and there is no need to touch that anymore). This ensures that there is no remnant file that could potentially conflict with latest releases.
4. On your addons folder (Interface/Addons), Paste (Ctrl+V) the previously copied folders here. DO NOT put the DBM-Wowcircle-main folder directly into the addon folder, it will not work.

*To know when there are changes, you can Star/Watch this repository on GitHub (this requires a GitHub account) to receive notifications.

# SETTINGS
Чтобы открыть окно настроек, введите в чат `/dbm` и нажмите ентер, или кликните по иконке DBM у миникарты. Для просмотра дополнительных комманд введите `/dbm help`

# CREDITS
Первый бэкпорт, и предыдущая Wowcircle версия от Barsoomx:  
https://github.com/Barsoomx/DBM-wowcircle

Неповторимое продолжение, и версия для Warmane серверов от Zidras:  
https://github.com/Zidras/DBM-Warmane

# ФРОНТ РАБОТ

## Icecrown Citadel  

- ### LordMarrowgar
  - [x] BoneSpike: pull+15, cd=18
    - [ ] add +3sec to cd after whirlwind cast start or how tf this sht works ?
  - [x] Whirlwind: pull+45nm, cd=90 ?
    - I've never seen 2 Whirlwinds, so... plz report CD
- ### LadyDeathwhisper
  - [x] Adds: pull+9, cd=45 always, no restart on phase2
    - check adds cd on normals ?
  - [x] DominateMind: pull+30, cd=40 always, no restart on phase2
    - [ ] add 3s prewarning when people should use their fears, ams, etc. ?
  - [ ] TouchInsignificance: phase2+[6.5-...], cd=[6.38-9.85] - need var timer?
  - [x] SummonSpirit: phase2+13 /13.5-15.0/, cd=13.5 /13.5-15.7/ 
      - [x] missing UNIT_SPELLCAST_SUCCEEDED, use SPELL_SUMMON
      - missing first phase2 SPELL_SUMMON event
  - [x] FrostboltVolley: phase2+20, cd=20
  - [x] Frostbolt
    - [x] filter specWarnFrostbolt when interrupt on cd
    - [ ] filter players without interrupts - dbm-core.lua/CheckInterruptFilter
      - [x] full ignore for PRIEST, WARLOCK, PALADIN, DRUID for now
- ### GunshipBattle
  - [X] Adds: pull+12, cd = 60 ?
  - [x] BelowZero: pull+39(Alliance)/+37(Horde) ? < it autocorrects itself later
- ### DeathbringerSaurfang
  - [ ] CombatStart: Alliance=100.3, Horde=100.3 ?
  - [x] CallBloodBeast: pull+40, cd=40
    - [ ] fix prewarning ? 10 rnow, but 5s much better ?
    - missing SPELL_SUMMON events for full 1rst pack
  - [x] RuneofBlood: pull+19.1 /19.177/ ? cd=19.5
  - [x] BoilingBlood: pull+19, cd=15.5  /15.7-19.6/ - need var timer?
  - [x] BloodNova: pull+20, cd=20
- ### Rotface - right side
  - [x] WallSlime
  - [x] SlimeSpray
  - [x] VileGas
    - куда прикрутить отображение ренжи до боя ?
- ### Festergut - left side
  - Goo
    - check cd for 10/25 hc
  - GasSpore
  - GastricBloat
  - InhaledBlight
  - VileGas
    - no timers ?
    - куда прикрутить отображение ренжи до боя ?
- ### Putricide
  - [x] SlimePuddle: pull+10, phase2+10.5, phase3+23.5, cd=35
  - [x] UnboundPlague: pull+10, phase2+55.5, phase3+58.5 ? cd= ?
  - [x] UnstableExperiment: pull+ ? phase2+25.5, cd=38
  - [x] ChokingGasBomb: phase2+10.5, phase3+20.5, cd=36
  - [x] MalleableGoo: phase2+10.5, phase3+17.5, cd=20
  - [x] MutatedPlague: cd=10
- ### BPCouncil - ой ляяяяя...
  - check everything =_=
  - EmpoweredFlames
    - [x] added SendSync, no idea if it works xD
      - bcz its missing CHAT_MSG_RAID_BOSS_EMOTE sometimes
- ### Lanathel
  - [x] FirstBite: pull+15
  - [x] PactDarkfallen: pull+15, InciteTerror+25.5, cd=30.5
  - [x] SwarmingShadows: pull+30.5, InciteTerror+30.5, cd=30.5
  - [x] InciteTerror: pull+100, cd=100
    - check pull/cd timers for 10nm/10hc/25nm, cd timer for 25hc
- ### Valithria
  - [x] Suppressers: pull+70 > 61 > 61 > 61 > ?
  - [x] BlazingSkeleton: pull+30 > 61 > 62 > 63 ?
  - [x] Abom: pull+5 > 60 > 60 > 60 ?
  - [] Portal
- ### Sindragosa +-
  - [x] Airphase: pull+50, cd=120
  - [ ] Groundphase: Airphase+45.2
    - Airphase+45.24
    - 45.2 for now, check it proper grounding works or it fires from workaround only
  - [ ] UnchainedMagic: pull+9.2 ? SindragosaLanded+11 ? cd=33.5 ?
    - pull 11.18 | SindragosaLanded+13.84 OR stage1.5+59.08 ?
    - cd 34.64 32.48
    - Stage2+23.47 OR just cd 30.47 ???
    - need keep arg for cd ? cuz it can be delayed by other casts
  - [x] FrostBreath: SPELL_CAST_START varCD=20-25
    - pull+11.52, SindragosaLanded+12.28, no reset on phase2
      - add pull and groundphase timers ?
    - cd 21.72 21.60 21.25 22.91
      - need keep arg for cd ? and it can be delayed by other casts
  - [ ] IcyGrip
    - missing SPELL_CAST_SUCCESS event
    - it can be delayed by other casts
  - [ ] BlisteringCold: SPELL_CAST_START pull+33.5 ? SindragosaLanded+v34 ? Phase2+v35, cd= ?
    - pull+36.42 | -1.5=34.92
    - SindragosaLanded+38.74 | -1.5=37.24
    - phase2+36.60 | -1.5=35.1
      - -1.5 cuz ~1.5s between IcyGrip and BlisteringCold
    - it can be delayed by delayed IcyGrip
  - [ ] TailSmash: SPELL_CAST_START pull+20, SindragosaLanded+20 ? Phase2+ ? cd=29
    - pull+19.97 | SindragosaLanded+20.09 | stage2+27.59 OR just 31.64 cd
    - cd 29.19 29.18 | phase2 cd 32.00
      - var timer v29-32 ?
- ### LichKing - *более лимение*
  - [ ] Infest: SPELL_CAST_START pull+5, phase2+14 ?? cd="v21-24"
    - pull 5.04 | phase2 17.45
    - cd stage1 23.88, 23.35, 23.71, 21.66 | cd stage2 22.61, 22.05, 23.89, 21.05
  - [x] DrudgeGhouls: pull+10, cd=30
    - pull:10.58
  - [x] Trap: SPELL_CAST_START pull+15, cd=15
    - pull:15.08
    - cd 16.03, 15.08, 15.09, 16.81, 15.02
      - cd var timer "v15-17" or nah ?
  - [x] ShamblingHorror: pull+20, cd=60
    - Enrage check when ?
  - [x] NecroticPlague: pull+30, cd=30
    - hc pull+31.02
      - check if normal and heroic have different pull timers
  - [x] RagingSpirit: phase1.5+3, phase1.5cd=22, phase2.5+5, phase2.5cd=17
    - phase1.5 3.14 | phase2.5 4.91
    - cd phase1.5 22.02, 22.12 | cd phase2.5 17.06, 17.10, 17.03
  - [x] SoulShriek: RagingSpirit spell_cast_success+"v21-23.5", cd=12
    - after RagingSpirit spell_cast_success 21.41 23.44 21.66; 22.28 22.48 21.98
    - cd 12.24
    - no idea how it behaves after phase3 frostmourne room
  - [X] Soulreaper: SPELL_CAST_SUCCESS phase2+32, phase3 ? leftFrostmourne+12.4, cd=34
    - phase2+31.46 | phase3 - | leftFrostmoure 12.71 | 12.44
    - cd phase2 34.25, 34.18, cd phase3/leftFrostmourne 36.27
    - 10hc logs where ?
  - [X] Defile: SPELL_CAST_START phase2+37, phase3 ? leftFrostmourne+1.4, cd=32
    - phase2+36.96 | phase3 - | leftFrostmourne+1.40 | 1.39
    - cd phase2 32.83, 34.99 | cd leftFrostmourne 35.03 | 33.99
      - make var timer "v32-35" ?
    - 10hc logs where
  - [x] SummonValkyr: SPELL_SUMMON phase2+16.50, cd=48.5
    - cd 49.5 between 1st valks in a pack, but 1 sometimes missing, soo... cd = 48.5 +keep ?
    - missing UNIT_SPELLCAST_SUCCEEDED, use SPELL_SUMMON
    - missing first phase2 SPELL_SUMMON event
  - [x] VileSpirit: SPELL_CAST_START phase3 ? leftFrostmourne+12, cd=30.5
    - phase3 ? leftFrostmourne+ 12.73 | 12.56
    - cd 30.71 30.99
    - 10hc/25nm logs where
  - [ ] HarvestSoul:
    - no idea
  - [x] HarvestSoul(Heroic): SPELL_CAST_SUCCESS phase3+11, leftFrostmourne+56
    - phase3+11.17 | leftFrostmourne 56.47

## Ruby Sanctum
- ### Балтар
  - изменить аннос разделения (specwarning ибо отброс в мили это ВАЖНО)
  - кд BladeTempest +- чекнуть
- ### Савиана +- ?
- ### Генерал ?
  - фир ?
  - адды ?
- ### Халион
  - фазы +
  - метеор +
  - лезвия +
  - FieryBreath +-
    - when 1st FieryBreath on phase3 ? SendSync from outside tank+heal should fix that anyway ?
  - ShadowBreath +-
    - when 1st ShadowBreath on phase2 ? SendSync from inside tank should fix that anyway ?
  - метки свет +- чекнуть
  - метки тьма +- чекнуть
