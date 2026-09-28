<!--
CurseForge page of nxPanels (project 1444518). Paste everything below the line into
Description (editor set to Markdown). Images: upload them in the Images tab of the
project, then replace each IMAGE_URL_* with the link CurseForge gives:
BANNER = docs/media/banner-curseforge.png, BROWSER = screenshot-browser.jpg,
EDITMODE = screenshot-editmode.jpg. The other screenshots (window, display, text,
templates) go in the Images tab only.
Summary field (max 250 characters):
Artistic panels for your interface: backgrounds, borders, text and scripts, placed anywhere. Edit mode, display conditions, templates. Retail and WoW Forever. Continuation of kgPanels Reloaded: your layouts are imported automatically.
-->
---

![nxPanels](IMAGE_URL_BANNER)

**nxPanels** adds artistic panels to your World of Warcraft interface: backgrounds, borders, text and scripts, placed anywhere and attached to any frame. Build an interface that is truly yours.

> **Coming from kgPanels Reloaded?** This is the same project under its new name. **You have nothing to do**: the CurseForge app updates it like any other addon, and your layouts are imported on the first start. See *Migration* below.

> 🚧 **Alpha.** Works in game on Retail and WoW Forever. Please report problems in the comments or on [GitHub](https://github.com/WillOli7/nxPanels/issues).

## Features

### Panels
- **Backgrounds:** solid color, gradient, your own textures, SharedMedia textures and **Blizzard images (atlases)**, chosen in a browser with thumbnails.
- **Borders** from any border texture, with size, insets and color.
- **Automatic colors:** class, faction, reaction of the target.
- **Text** in the font of your client language, with live **variables without code**: `{zone}`, `{time}`, `{fps}`, `{latency}`, `{gold}`, `{currency:<id>}`, `{item:<id>}`… and every game icon.
- **Attach** a panel to any frame of the game or of another addon (Bartender, Details!, chat…): it follows it.

### Display without scripts
- Show or hide on **conditions**: combat, group or raid, instance type, mount, target, pet battles, or any macro condition (`[combat] show; hide`).
- **Opacity** at rest, in combat and under the mouse, with fades.

### Creation
- A modern **configuration window** (`/nxp`), loaded only when you open it. Every change is drawn at once.
- **Edit mode** (`/nxp edit`): move and resize with the mouse, snapping to the screen and to the other panels with guides, arrow keys, multiple selection, alignment, undo.
- **Templates** to start from: info bar, bar frame, chat background, combat glow, discreet frame, target bar.
- **Folders** to organize large layouts.
- **Scripts** for advanced users, with a syntax check that shows the line of the error.

### Layouts and profiles
- Several **layouts**, switched in one click or **automatically per specialization** (Retail) or talent group (WoW Forever).
- **Profiles** per character, class or faction.
- **Share** a layout, a folder or a single panel with a text string, with a warning when it contains scripts.
- Your own backgrounds and borders by file path, and an API for **media packs**.

### Light
The display engine is small and always loaded. The window and the import module are separate addons, loaded only when needed.

![The panel editor and the texture browser with Blizzard images](IMAGE_URL_BROWSER)

![The edit mode, with grid and alignment guides](IMAGE_URL_EDITMODE)

## Clients and languages

| Client | Version |
|---|---|
| Retail | 12.x |
| WoW Forever | 1.60 (interface 16001) |

| Language | State |
|---|---|
| English | complete |
| Français | complete |
| 简体中文 | complete, review by a native speaker welcome |
| 繁體中文 | complete, review by a native speaker welcome |

Panel text always uses the font of your client: Chinese, Korean and Russian text is readable. Want to translate or review a language? See [GitHub](https://github.com/WillOli7/nxPanels#translations).

## Migration from kgPanels and kgPanels Reloaded

- **kgPanels Reloaded:** nxPanels replaces it in the same CurseForge project. On the first start, your **layouts, panels, folders, profiles and custom art** are imported, and your profiles per specialization become layouts per specialization. Then the old addon is disabled.
- **kgPanels (original):** its data is imported too, then a window offers to reload the interface.
- **Your old data is never modified.** Import again at any time with `/nxp import`.
- Old scripts keep working: `kgPanels` becomes `nxPanels`, with the same functions.
- Old export strings can be pasted in **Import / Export**.

The folders `kgPanels_Reloaded` and `kgPanelsConfig_Reloaded` of the package are small placeholders that let nxPanels read your old data: keep them.

## Commands

| Command | Action |
|---|---|
| `/nxp` | open the window (`/nxpanels` works too) |
| `/nxp edit` | edit mode |
| `/nxp layouts` | list your layouts |
| `/nxp layout <name>` | activate a layout |
| `/nxp enable` / `disable` / `toggle` | show or hide the panels |
| `/nxp minimap` | show or hide the minimap button |
| `/nxp import` | import the kgPanels layouts again |
| `/nxp status` | version and diagnostics |
| `/nxp help` | every command |

## Credits

nxPanels exists thanks to **kgPanels** by **kagaro**, successor of **eePanels**. It is a complete rewrite that does not reuse their code, but it keeps their spirit. Thank you to their authors and to everyone who kept them alive.

Free software under the **GNU GPL v3 or later**. Free, and it will stay free. Source code, bugs and translations: [github.com/WillOli7/nxPanels](https://github.com/WillOli7/nxPanels).

---

## Français

**nxPanels** ajoute des panneaux artistiques à votre interface : fonds, bordures, texte et scripts, placés où vous voulez et attachés à n'importe quel cadre.
- Fenêtre de configuration (`/nxp`) et mode édition (`/nxp edit`) : déplacement et redimensionnement à la souris, aimantation, guides d'alignement.
- Conditions d'affichage sans script (combat, groupe, monture, cible…) et opacités avec fondu.
- Couleurs automatiques (classe, faction, réaction), images Blizzard, navigateur de textures, modèles prêts à l'emploi.
- Variables de texte (`{zone}`, `{time}`, `{fps}`…), layout par spécialisation, profils par classe ou faction, partage par chaîne de texte.
- Retail 12.x et WoW Forever. Interface en anglais, français, chinois simplifié et traditionnel.
- **Vous utilisiez kgPanels Reloaded ?** Rien à faire : vos layouts sont importés automatiquement au premier démarrage, vos anciennes données ne sont jamais modifiées.

## 简体中文

**nxPanels** 为你的魔兽世界界面添加艺术面板：背景、边框、文字与脚本，可放在任意位置，并附着到任意框体上。
- 设置窗口（`/nxp`）与编辑模式（`/nxp edit`）：用鼠标移动和调整大小，自动吸附，带对齐参考线。
- 无需脚本的显示条件（战斗、队伍、坐骑、目标……）以及带渐变的透明度。
- 按职业、阵营或目标反应自动着色，支持暴雪图集，材质缩略图浏览器，现成模板。
- 文字变量（`{zone}`、`{time}`、`{fps}`……），每个专精自动切换布局，按职业或阵营的配置文件，通过字符串分享。
- 文字始终使用客户端语言的字体，中文可以正常显示。
- 支持正式服 12.x 与 WoW Forever。
- **从 kgPanels Reloaded 升级？** 无需任何操作：首次启动时会自动导入你的布局，原有数据不会被修改。

简体中文翻译欢迎母语玩家校对，请在评论区或 GitHub 留言。

## 繁體中文

**nxPanels** 為你的魔獸世界介面加入藝術面板：背景、邊框、文字與腳本，可放在任何位置，並附加到任何框架上。
- 設定視窗（`/nxp`）與編輯模式（`/nxp edit`）：用滑鼠移動和調整大小，自動吸附，並有對齊參考線。
- 不需腳本的顯示條件（戰鬥、隊伍、坐騎、目標……）以及淡入淡出的透明度。
- 依職業、陣營或目標反應自動上色，支援暴雪圖集、材質縮圖瀏覽器與現成範本。
- 文字變數（`{zone}`、`{time}`、`{fps}`……），每個專精自動切換版面，依職業或陣營的設定檔，以字串分享。
- 文字一律使用用戶端語言的字型，中文可以正常顯示。
- 支援正式服 12.x 與 WoW Forever。
- **從 kgPanels Reloaded 升級？** 不需要任何操作：第一次啟動時會自動匯入你的版面，原本的資料不會被修改。

繁體中文翻譯歡迎母語玩家協助校對，請在留言區或 GitHub 告訴我們。
