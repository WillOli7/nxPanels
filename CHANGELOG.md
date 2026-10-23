# Changelog

All notable changes to nxPanels. Versions follow [Semantic Versioning](https://semver.org/).

## 1.1.1 — 2026-10-23

- Retail: compatible with patch 12.1.5 (interface 120105).

## 1.1.0 — 2026-10-23

New:
- **TBC Anniversary** support (interface 20505 and 20506): layouts per talent group, like on WoW Forever.
- **Every language of the game**: German, Spanish (Spain and Mexico), Italian, Brazilian Portuguese, Russian and Korean, in addition to English, French and Chinese. Reviews by native speakers welcome.
- **Library**: add all the files of a folder at once (paste the paths copied from the file explorer); the texture browser has a "My library" tab; your files work even when the game does not index them yet, and a full Windows path is reduced to the game path.
- **What's new window**, shown once at the first start of a new version; it can be turned off, and opened again from the settings.
- **Welcome window** after the import of your kgPanels / kgPanels Reloaded layouts, shown once: what changed, and how to open nxPanels. Players who already updated to 1.0.0 see it once too.
- The sidebar of the window shows the client and the exact version of the game, for troubleshooting.

Fixed:
- A script hiding its panel (`self:Hide()`) no longer sees it shown again by the addon (on target change, Shift, combat…).
- Borders are drawn exactly like the borders of the game (they were 1 pixel off).
- Import: a panel named like the frame it follows (for example "Minimap") follows that frame again; layouts already imported are repaired.
- A duplicated panel keeps the exact position of the original.
- No more Lua error from LibSharedMedia when a library file is not found by the game yet.
- When kgPanels is installed but not loaded by the game (made for another client), a message explains how to import its layouts.
- Clearer warning about scripts when importing a layout.
- Updated libraries: LibSharedMedia, LibSerialize, LibDBIcon.

## 1.0.0 — 2026-09-29

**kgPanels Reloaded is now nxPanels**, a complete rewrite. **Nothing to do:** your layouts, panels, folders, profiles and custom art are imported automatically on the first start. Your old data is never modified, and `/nxp import` imports it again at any time.

### New
- **Configuration window** (`/nxp`): layouts, panels in folders, library, import / export, profiles, settings. Every change is shown at once. Three styles (Workshop, Ink, Night) and an accent color.
- **Edit mode** (`/nxp edit`): move and resize with the mouse, snapping, alignment guides, multiple selection, arrow keys, undo.
- **Backgrounds:** Blizzard images and a texture browser with thumbnails; automatic class, faction or target colors.
- **Text variables** without code: `{zone}`, `{time}`, `{fps}`, `{latency}`, `{gold}`, `{currency:<id>}`, `{item:<id>}`… and every game icon.
- **Display conditions** without scripts (combat, group, place, mount, target, pet battles, macro conditions), opacity in combat or under the mouse, fades.
- **Templates**, layouts per specialization (talent group on WoW Forever), profiles per class or faction.
- **Sharing** of layouts, folders and single panels with a text string; old kgPanels export strings are read too.
- **Scripts** with a syntax check that shows the line of the error.
- **WoW Forever** support, and full support for Chinese clients: English, French, Simplified and Traditional Chinese.
- API for other addons and media packs (`nxPanels.RegisterMedia`).

### Good to know
- Old scripts keep working (`kgPanels` becomes `nxPanels`, same functions).
- The `kgPanels_Reloaded` and `kgPanelsConfig_Reloaded` folders only let nxPanels read your old data: keep them.
- Problem or question? Comments on CurseForge or [GitHub](https://github.com/WillOli7/nxPanels/issues).
