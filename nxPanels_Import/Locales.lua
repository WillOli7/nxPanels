-- Texts of the import module (added to the nxPanels translations)
local AceLocale = LibStub("AceLocale-3.0")

local L = AceLocale:NewLocale("nxPanels", "enUS", true)
if L then
	L["HELP_IMPORT"] = "import: import your kgPanels layouts again (as new layouts)"
	L["MIGRATED"] = "Imported %d layout(s) and %d panel(s) from %s."
	L["MIGRATE_NOTHING"] = "No kgPanels data found to import."
	L["LEGACY_NOT_LOADED"] = "kgPanels is installed but the game did not load it (%s): its layouts cannot be read. Tick \"Load out of date AddOns\" in the AddOns list, or (game closed) copy WTF/Account/<account>/SavedVariables/kgPanels.lua as kgPanels_Reloaded.lua in the same folder. Then type /nxp import."
	L["MIGRATE_POPUP"] = "nxPanels imported your kgPanels layouts.\n\nThe old addon has been disabled. Reload the interface to finish?"
	L["RELOAD"] = "Reload"
	L["LATER"] = "Later"
	L["WELCOME_TITLE"] = "%s is now nxPanels!"
	L["WELCOME_COUNT"] = "Your %d layout(s) and %d panel(s) have been imported."
	L["WELCOME_BODY"] = "Your old data was not modified.\n\nType /nxp to open the settings, /nxp edit for the edit mode."
	L["WELCOME_OPEN"] = "Open nxPanels"
	L["WELCOME_CLOSE"] = "OK"
	L["FORMAT_LEGACY"] = "kgPanels (old format)"
end

L = AceLocale:NewLocale("nxPanels", "frFR")
if L then
	L["HELP_IMPORT"] = "import : importe à nouveau vos layouts kgPanels (en nouveaux layouts)"
	L["MIGRATED"] = "%d layout(s) et %d panneau(x) importés depuis %s."
	L["MIGRATE_NOTHING"] = "Aucune donnée kgPanels à importer."
	L["LEGACY_NOT_LOADED"] = "kgPanels est installé mais le jeu ne l'a pas chargé (%s) : ses layouts ne peuvent pas être lus. Cochez « Charger les addons périmés » dans la liste des addons, ou (jeu fermé) copiez WTF/Account/<compte>/SavedVariables/kgPanels.lua sous le nom kgPanels_Reloaded.lua dans le même dossier. Tapez ensuite /nxp import."
	L["MIGRATE_POPUP"] = "nxPanels a importé vos layouts kgPanels.\n\nL'ancien addon a été désactivé. Recharger l'interface pour terminer ?"
	L["RELOAD"] = "Recharger"
	L["LATER"] = "Plus tard"
	L["WELCOME_TITLE"] = "%s devient nxPanels !"
	L["WELCOME_COUNT"] = "Vos %d layout(s) et %d panneau(x) ont été importés."
	L["WELCOME_BODY"] = "Vos anciennes données n'ont pas été modifiées.\n\nTapez /nxp pour ouvrir les réglages, /nxp edit pour le mode édition."
	L["WELCOME_OPEN"] = "Ouvrir nxPanels"
	L["WELCOME_CLOSE"] = "OK"
	L["FORMAT_LEGACY"] = "kgPanels (ancien format)"
end

-- 待母语玩家校对
L = AceLocale:NewLocale("nxPanels", "zhCN")
if L then
	L["HELP_IMPORT"] = "import：再次导入你的 kgPanels 布局（作为新布局）"
	L["MIGRATED"] = "已从 %3$s 导入 %1$d 个布局和 %2$d 个面板。"
	L["MIGRATE_NOTHING"] = "没有找到可导入的 kgPanels 数据。"
	L["LEGACY_NOT_LOADED"] = "已安装 kgPanels，但游戏没有加载它（%s），无法读取其布局。请在插件列表中勾选“加载过期插件”，或在关闭游戏后将 WTF/Account/<账号>/SavedVariables/kgPanels.lua 在同一文件夹中复制为 kgPanels_Reloaded.lua。然后输入 /nxp import。"
	L["MIGRATE_POPUP"] = "nxPanels 已导入你的 kgPanels 布局。\n\n旧插件已被禁用。现在重新加载界面以完成吗？"
	L["RELOAD"] = "重新加载"
	L["LATER"] = "稍后"
	L["WELCOME_TITLE"] = "%s 现已更名为 nxPanels！"
	L["WELCOME_COUNT"] = "已导入你的 %d 个布局和 %d 个面板。"
	L["WELCOME_BODY"] = "原有数据未被修改。\n\n输入 /nxp 打开设置，输入 /nxp edit 进入编辑模式。"
	L["WELCOME_OPEN"] = "打开 nxPanels"
	L["WELCOME_CLOSE"] = "确定"
	L["FORMAT_LEGACY"] = "kgPanels（旧格式）"
end

-- 待母語玩家校對
L = AceLocale:NewLocale("nxPanels", "zhTW")
if L then
	L["HELP_IMPORT"] = "import：再次匯入你的 kgPanels 版面（作為新版面）"
	L["MIGRATED"] = "已從 %3$s 匯入 %1$d 個版面和 %2$d 個面板。"
	L["MIGRATE_NOTHING"] = "找不到可匯入的 kgPanels 資料。"
	L["LEGACY_NOT_LOADED"] = "已安裝 kgPanels，但遊戲沒有載入它（%s），無法讀取其版面。請在插件列表中勾選「載入過期插件」，或在關閉遊戲後將 WTF/Account/<帳號>/SavedVariables/kgPanels.lua 在同一資料夾中複製為 kgPanels_Reloaded.lua。然後輸入 /nxp import。"
	L["MIGRATE_POPUP"] = "nxPanels 已匯入你的 kgPanels 版面。\n\n舊插件已被停用。現在重新載入介面以完成嗎？"
	L["RELOAD"] = "重新載入"
	L["LATER"] = "稍後"
	L["WELCOME_TITLE"] = "%s 現已更名為 nxPanels！"
	L["WELCOME_COUNT"] = "已匯入你的 %d 個版面和 %d 個面板。"
	L["WELCOME_BODY"] = "原本的資料沒有被修改。\n\n輸入 /nxp 開啟設定，輸入 /nxp edit 進入編輯模式。"
	L["WELCOME_OPEN"] = "開啟 nxPanels"
	L["WELCOME_CLOSE"] = "確定"
	L["FORMAT_LEGACY"] = "kgPanels（舊格式）"
end

-- To be reviewed by native players
L = AceLocale:NewLocale("nxPanels", "deDE")
if L then
	L["HELP_IMPORT"] = "import: deine kgPanels-Layouts erneut importieren (als neue Layouts)"
	L["MIGRATED"] = "%d Layout(s) und %d Panel(s) aus %s importiert."
	L["MIGRATE_NOTHING"] = "Keine kgPanels-Daten zum Importieren gefunden."
	L["LEGACY_NOT_LOADED"] = "kgPanels ist installiert, wurde aber vom Spiel nicht geladen (%s): Seine Layouts können nicht gelesen werden. Aktiviere „Veraltete AddOns laden“ in der AddOn-Liste oder kopiere (Spiel geschlossen) WTF/Account/<Konto>/SavedVariables/kgPanels.lua als kgPanels_Reloaded.lua in denselben Ordner. Gib dann /nxp import ein."
	L["MIGRATE_POPUP"] = "nxPanels hat deine kgPanels-Layouts importiert.\n\nDas alte Addon wurde deaktiviert. Die Oberfläche jetzt neu laden, um abzuschließen?"
	L["RELOAD"] = "Neu laden"
	L["LATER"] = "Später"
	L["WELCOME_TITLE"] = "%s ist jetzt nxPanels!"
	L["WELCOME_COUNT"] = "Deine %d Layout(s) und %d Panel(s) wurden importiert."
	L["WELCOME_BODY"] = "Deine alten Daten wurden nicht verändert.\n\nGib /nxp ein, um die Einstellungen zu öffnen, /nxp edit für den Bearbeitungsmodus."
	L["WELCOME_OPEN"] = "nxPanels öffnen"
	L["WELCOME_CLOSE"] = "OK"
	L["FORMAT_LEGACY"] = "kgPanels (altes Format)"
end

L = AceLocale:NewLocale("nxPanels", "esES") or AceLocale:NewLocale("nxPanels", "esMX")
if L then
	L["HELP_IMPORT"] = "import: vuelve a importar tus diseños de kgPanels (como diseños nuevos)"
	L["MIGRATED"] = "Importados %d diseño(s) y %d panel(es) desde %s."
	L["MIGRATE_NOTHING"] = "No se encontraron datos de kgPanels para importar."
	L["LEGACY_NOT_LOADED"] = "kgPanels está instalado, pero el juego no lo ha cargado (%s): no se pueden leer sus diseños. Marca «Cargar accesorios desactualizados» en la lista de accesorios o (con el juego cerrado) copia WTF/Account/<cuenta>/SavedVariables/kgPanels.lua como kgPanels_Reloaded.lua en la misma carpeta. Luego escribe /nxp import."
	L["MIGRATE_POPUP"] = "nxPanels ha importado tus diseños de kgPanels.\n\nEl addon antiguo se ha desactivado. ¿Recargar la interfaz para terminar?"
	L["RELOAD"] = "Recargar"
	L["LATER"] = "Más tarde"
	L["WELCOME_TITLE"] = "¡%s ahora es nxPanels!"
	L["WELCOME_COUNT"] = "Se han importado tus %d diseño(s) y %d panel(es)."
	L["WELCOME_BODY"] = "Tus datos antiguos no se han modificado.\n\nEscribe /nxp para abrir los ajustes y /nxp edit para el modo de edición."
	L["WELCOME_OPEN"] = "Abrir nxPanels"
	L["WELCOME_CLOSE"] = "Aceptar"
	L["FORMAT_LEGACY"] = "kgPanels (formato antiguo)"
end

L = AceLocale:NewLocale("nxPanels", "itIT")
if L then
	L["HELP_IMPORT"] = "import: importa di nuovo i tuoi layout di kgPanels (come nuovi layout)"
	L["MIGRATED"] = "Importati %d layout e %d pannello/i da %s."
	L["MIGRATE_NOTHING"] = "Nessun dato di kgPanels da importare."
	L["LEGACY_NOT_LOADED"] = "kgPanels è installato ma il gioco non lo ha caricato (%s): i suoi layout non possono essere letti. Spunta \"Carica AddOn non aggiornati\" nell'elenco degli AddOn oppure (a gioco chiuso) copia WTF/Account/<account>/SavedVariables/kgPanels.lua come kgPanels_Reloaded.lua nella stessa cartella. Poi digita /nxp import."
	L["MIGRATE_POPUP"] = "nxPanels ha importato i tuoi layout di kgPanels.\n\nIl vecchio addon è stato disattivato. Ricaricare l'interfaccia per completare?"
	L["RELOAD"] = "Ricarica"
	L["LATER"] = "Più tardi"
	L["WELCOME_TITLE"] = "%s ora è nxPanels!"
	L["WELCOME_COUNT"] = "I tuoi %d layout e %d pannello/i sono stati importati."
	L["WELCOME_BODY"] = "I tuoi vecchi dati non sono stati modificati.\n\nDigita /nxp per aprire le impostazioni, /nxp edit per la modalità modifica."
	L["WELCOME_OPEN"] = "Apri nxPanels"
	L["WELCOME_CLOSE"] = "OK"
	L["FORMAT_LEGACY"] = "kgPanels (vecchio formato)"
end

L = AceLocale:NewLocale("nxPanels", "ptBR")
if L then
	L["HELP_IMPORT"] = "import: importa de novo seus layouts do kgPanels (como novos layouts)"
	L["MIGRATED"] = "%d layout(s) e %d painel(éis) importados de %s."
	L["MIGRATE_NOTHING"] = "Nenhum dado do kgPanels encontrado para importar."
	L["LEGACY_NOT_LOADED"] = "O kgPanels está instalado, mas o jogo não o carregou (%s): seus layouts não podem ser lidos. Marque \"Carregar AddOns desatualizados\" na lista de AddOns ou (com o jogo fechado) copie WTF/Account/<conta>/SavedVariables/kgPanels.lua como kgPanels_Reloaded.lua na mesma pasta. Depois digite /nxp import."
	L["MIGRATE_POPUP"] = "O nxPanels importou seus layouts do kgPanels.\n\nO addon antigo foi desativado. Recarregar a interface para concluir?"
	L["RELOAD"] = "Recarregar"
	L["LATER"] = "Mais tarde"
	L["WELCOME_TITLE"] = "%s agora é nxPanels!"
	L["WELCOME_COUNT"] = "Seus %d layout(s) e %d painel(éis) foram importados."
	L["WELCOME_BODY"] = "Seus dados antigos não foram modificados.\n\nDigite /nxp para abrir as configurações, /nxp edit para o modo de edição."
	L["WELCOME_OPEN"] = "Abrir o nxPanels"
	L["WELCOME_CLOSE"] = "OK"
	L["FORMAT_LEGACY"] = "kgPanels (formato antigo)"
end

L = AceLocale:NewLocale("nxPanels", "ruRU")
if L then
	L["HELP_IMPORT"] = "import: заново импортировать макеты kgPanels (как новые макеты)"
	L["MIGRATED"] = "Импортировано макетов: %d, панелей: %d, из %s."
	L["MIGRATE_NOTHING"] = "Данные kgPanels для импорта не найдены."
	L["LEGACY_NOT_LOADED"] = "kgPanels установлен, но игра его не загрузила (%s): его макеты нельзя прочитать. Включите «Загружать устаревшие модификации» в списке модификаций или (при закрытой игре) скопируйте WTF/Account/<учётная запись>/SavedVariables/kgPanels.lua под именем kgPanels_Reloaded.lua в ту же папку. Затем введите /nxp import."
	L["MIGRATE_POPUP"] = "nxPanels импортировал ваши макеты kgPanels.\n\nСтарый аддон отключён. Перезагрузить интерфейс, чтобы завершить?"
	L["RELOAD"] = "Перезагрузить"
	L["LATER"] = "Позже"
	L["WELCOME_TITLE"] = "%s теперь называется nxPanels!"
	L["WELCOME_COUNT"] = "Импортировано макетов: %d, панелей: %d."
	L["WELCOME_BODY"] = "Ваши старые данные не изменены.\n\nВведите /nxp, чтобы открыть настройки, /nxp edit для режима редактирования."
	L["WELCOME_OPEN"] = "Открыть nxPanels"
	L["WELCOME_CLOSE"] = "ОК"
	L["FORMAT_LEGACY"] = "kgPanels (старый формат)"
end

L = AceLocale:NewLocale("nxPanels", "koKR")
if L then
	L["HELP_IMPORT"] = "import: kgPanels 레이아웃을 다시 가져오기 (새 레이아웃으로)"
	L["MIGRATED"] = "레이아웃 %d개와 패널 %d개를 %s에서 가져왔습니다."
	L["MIGRATE_NOTHING"] = "가져올 kgPanels 데이터가 없습니다."
	L["LEGACY_NOT_LOADED"] = "kgPanels가 설치되어 있지만 게임이 불러오지 않았습니다 (%s): 레이아웃을 읽을 수 없습니다. 애드온 목록에서 \"구버전 애드온 불러오기\"를 켜거나, (게임을 끈 상태에서) WTF/Account/<계정>/SavedVariables/kgPanels.lua를 같은 폴더에 kgPanels_Reloaded.lua라는 이름으로 복사하세요. 그런 다음 /nxp import를 입력하세요."
	L["MIGRATE_POPUP"] = "nxPanels가 kgPanels 레이아웃을 가져왔습니다.\n\n이전 애드온은 비활성화되었습니다. 마무리하려면 인터페이스를 리로드할까요?"
	L["RELOAD"] = "리로드"
	L["LATER"] = "나중에"
	L["WELCOME_TITLE"] = "%s은(는) 이제 nxPanels입니다!"
	L["WELCOME_COUNT"] = "레이아웃 %d개와 패널 %d개를 가져왔습니다."
	L["WELCOME_BODY"] = "이전 데이터는 수정되지 않았습니다.\n\n/nxp로 설정을 열고, /nxp edit로 편집 모드를 시작하세요."
	L["WELCOME_OPEN"] = "nxPanels 열기"
	L["WELCOME_CLOSE"] = "확인"
	L["FORMAT_LEGACY"] = "kgPanels (이전 형식)"
end
