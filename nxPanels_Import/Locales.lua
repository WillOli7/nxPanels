-- Texts of the import module (added to the nxPanels translations)
local AceLocale = LibStub("AceLocale-3.0")

local L = AceLocale:NewLocale("nxPanels", "enUS", true)
if L then
	L["HELP_IMPORT"] = "import: import your kgPanels layouts again (as new layouts)"
	L["MIGRATED"] = "Imported %d layout(s) and %d panel(s) from %s."
	L["MIGRATE_NOTHING"] = "No kgPanels data found to import."
	L["MIGRATE_POPUP"] = "nxPanels imported your kgPanels layouts.\n\nThe old addon has been disabled. Reload the interface to finish?"
	L["RELOAD"] = "Reload"
	L["LATER"] = "Later"
	L["FORMAT_LEGACY"] = "kgPanels (old format)"
end

L = AceLocale:NewLocale("nxPanels", "frFR")
if L then
	L["HELP_IMPORT"] = "import : importe à nouveau vos layouts kgPanels (en nouveaux layouts)"
	L["MIGRATED"] = "%d layout(s) et %d panneau(x) importés depuis %s."
	L["MIGRATE_NOTHING"] = "Aucune donnée kgPanels à importer."
	L["MIGRATE_POPUP"] = "nxPanels a importé vos layouts kgPanels.\n\nL'ancien addon a été désactivé. Recharger l'interface pour terminer ?"
	L["RELOAD"] = "Recharger"
	L["LATER"] = "Plus tard"
	L["FORMAT_LEGACY"] = "kgPanels (ancien format)"
end

-- 待母语玩家校对
L = AceLocale:NewLocale("nxPanels", "zhCN")
if L then
	L["HELP_IMPORT"] = "import：再次导入你的 kgPanels 布局（作为新布局）"
	L["MIGRATED"] = "已从 %3$s 导入 %1$d 个布局和 %2$d 个面板。"
	L["MIGRATE_NOTHING"] = "没有找到可导入的 kgPanels 数据。"
	L["MIGRATE_POPUP"] = "nxPanels 已导入你的 kgPanels 布局。\n\n旧插件已被禁用。现在重新加载界面以完成吗？"
	L["RELOAD"] = "重新加载"
	L["LATER"] = "稍后"
	L["FORMAT_LEGACY"] = "kgPanels（旧格式）"
end

-- 待母語玩家校對
L = AceLocale:NewLocale("nxPanels", "zhTW")
if L then
	L["HELP_IMPORT"] = "import：再次匯入你的 kgPanels 版面（作為新版面）"
	L["MIGRATED"] = "已從 %3$s 匯入 %1$d 個版面和 %2$d 個面板。"
	L["MIGRATE_NOTHING"] = "找不到可匯入的 kgPanels 資料。"
	L["MIGRATE_POPUP"] = "nxPanels 已匯入你的 kgPanels 版面。\n\n舊插件已被停用。現在重新載入介面以完成嗎？"
	L["RELOAD"] = "重新載入"
	L["LATER"] = "稍後"
	L["FORMAT_LEGACY"] = "kgPanels（舊格式）"
end
