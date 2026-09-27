local L = LibStub("AceLocale-3.0"):NewLocale("nxPanels", "zhTW")
if not L then return end

-- 待母語玩家校對
L["LIB_MISSING"] = "缺少函式庫 %s。請重新安裝 nxPanels。"
L["ENABLED"] = "面板已啟用。"
L["DISABLED"] = "面板已停用。"
L["LAYOUT_ACTIVE"] = "目前版面：%s"
L["LAYOUT_NONE"] = "沒有啟用的版面。"
L["LAYOUT_NOT_FOUND"] = "找不到版面：%s"
L["LAYOUT_LIST"] = "版面列表："
L["LAYOUT_LIST_ITEM"] = "%s（%d 個面板）"
L["NO_LAYOUTS"] = "目前沒有版面。"
L["STATUS"] = "版本 %s，%s 用戶端。目前版面：%s。已顯示面板：%d，等待框架：%d。"
L["CLIENT_RETAIL"] = "正式服"
L["CLIENT_FOREVER"] = "魔獸世界：永恆"
L["CLIENT_OTHER"] = "不支援的"
L["MENU_SHOW"] = "顯示面板"

L["HELP_TITLE"] = "指令（/nxpanels 或 /nxp）："
L["HELP_LAYOUTS"] = "layouts：列出你的版面"
L["HELP_LAYOUT"] = "layout <名稱>：啟用一個版面"
L["HELP_TOGGLE"] = "enable / disable：顯示或隱藏所有面板"
L["HELP_MINIMAP"] = "minimap：顯示或隱藏小地圖按鈕"
L["HELP_STATUS"] = "status：版本與診斷資訊"


L["SCRIPT_ERROR"] = "面板 |cffffd100%s|r（%s）的腳本發生錯誤：%s。此腳本在下次重新載入前已停用。"
L["SCRIPT_COMPILE_ERROR"] = "面板 |cffffd100%s|r（%s）的腳本無法編譯：%s"
L["ANCHOR_CYCLE"] = "面板 |cffffd100%s|r：偵測到循環錨點，已改為錨定到螢幕。"

L["HELP_OPEN"] = "（無參數）：開啟 nxPanels 視窗"
L["HELP_EDIT"] = "edit：編輯模式，用滑鼠移動和調整面板大小"
L["OPTIONS_LOAD_FAILED"] = "無法載入 nxPanels_Options 模組（%s）。請確認它已安裝並啟用。"
L["SETTINGS_DESC"] = "建立並排列藝術面板：背景、邊框、文字與腳本。所有設定都在 nxPanels 視窗中完成。"
L["OPEN_OPTIONS"] = "開啟 nxPanels"
L["IMPORT_INVALID"] = "這段文字不是有效的版面字串。"
L["IMPORT_NEWER"] = "此版面由較新版本的 nxPanels 建立。請更新插件後再匯入。"
L["IMPORT_EMPTY"] = "請先貼上版面字串。"
L["IMPORTED_LAYOUT"] = "匯入的版面"
L["MINIMAP_TOOLTIP_LEFT"] = "|cffffd100左鍵：|r開啟 nxPanels"
L["MINIMAP_TOOLTIP_RIGHT"] = "|cffffd100右鍵：|r版面選單"
