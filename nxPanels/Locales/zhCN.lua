local L = LibStub("AceLocale-3.0"):NewLocale("nxPanels", "zhCN")
if not L then return end

-- 待母语玩家校对
L["LIB_MISSING"] = "缺少库 %s。请重新安装 nxPanels。"
L["ENABLED"] = "面板已启用。"
L["DISABLED"] = "面板已禁用。"
L["LAYOUT_ACTIVE"] = "当前布局：%s"
L["LAYOUT_NONE"] = "没有启用的布局。"
L["LAYOUT_NOT_FOUND"] = "未找到布局：%s"
L["LAYOUT_LIST"] = "布局列表："
L["LAYOUT_LIST_ITEM"] = "%s（%d 个面板）"
L["NO_LAYOUTS"] = "暂无布局。"
L["STATUS"] = "版本 %s，%s 客户端。当前布局：%s。已显示面板：%d，等待框体：%d。"
L["CLIENT_RETAIL"] = "正式服"
L["CLIENT_FOREVER"] = "魔兽世界：永恒"
L["CLIENT_OTHER"] = "不支持的"
L["MENU_SHOW"] = "显示面板"

L["HELP_TITLE"] = "命令（/nxpanels 或 /nxp）："
L["HELP_LAYOUTS"] = "layouts：列出你的布局"
L["HELP_LAYOUT"] = "layout <名称>：启用一个布局"
L["HELP_TOGGLE"] = "enable / disable：显示或隐藏所有面板"
L["HELP_MINIMAP"] = "minimap：显示或隐藏小地图按钮"
L["HELP_STATUS"] = "status：版本与诊断信息"


L["SCRIPT_ERROR"] = "面板 |cffffd100%s|r（%s）的脚本出错：%s。该脚本在下次重新加载前已被禁用。"
L["SCRIPT_COMPILE_ERROR"] = "面板 |cffffd100%s|r（%s）的脚本无法编译：%s"
L["ANCHOR_CYCLE"] = "面板 |cffffd100%s|r：检测到循环锚点，已改为锚定到屏幕。"

L["HELP_OPEN"] = "（无参数）：打开 nxPanels 窗口"
L["HELP_EDIT"] = "edit：编辑模式，用鼠标移动和调整面板大小"
L["OPTIONS_LOAD_FAILED"] = "无法加载 nxPanels_Options 模块（%s）。请确认它已安装并启用。"
L["SETTINGS_DESC"] = "创建并排列艺术面板：背景、边框、文字与脚本。所有设置都在 nxPanels 窗口中完成。"
L["OPEN_OPTIONS"] = "打开 nxPanels"
L["IMPORT_INVALID"] = "这段文字不是有效的布局字符串。"
L["IMPORT_NEWER"] = "此布局由更新版本的 nxPanels 创建。请更新插件后再导入。"
L["IMPORT_EMPTY"] = "请先粘贴布局字符串。"
L["IMPORTED_LAYOUT"] = "导入的布局"
L["MINIMAP_TOOLTIP_LEFT"] = "|cffffd100左键：|r打开 nxPanels"
L["MINIMAP_TOOLTIP_RIGHT"] = "|cffffd100右键：|r布局菜单"
