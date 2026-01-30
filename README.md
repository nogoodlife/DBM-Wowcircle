<div align="center">

# DBM-Wowcircle [![Game Version](https://img.shields.io/badge/wow-3.3.5-blue.svg)](https://github.com/nogoodlife/DBM-Wowcircle)
</div>

**Здесь вы можете наблюдать за моими попытками поправить таймеры для серверов wowcircle.**

*Да, я тоже в шоке, что никто до сих пор даже не пытался, а если и пытался - не выложил в общий доступ.*

За основу взят https://github.com/Zidras/DBM-Warmane  
В первую очередь будут исправлены таймера ЦЛК и РС.  
По поводу остальных инстов и рейдов - пишите письма...  

> [!NOTE]
> Вердикт на 2026.01.30 : цлк/рс готовы, дальше ивк, ульда/накс/санвел - незнаюневидел, логов нет


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