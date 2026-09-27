# Changelog

All notable changes to nxPanels. Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## 1.0.0-alpha.2 — in progress
- Legacy import moved to the separate `nxPanels_Import` module; the core has no dependency on older addons.
- Old scripts are rewritten on import (`kgPanels` becomes `nxPanels`, same functions).
- Layout export / import (`!NXP1!` strings); old export strings are read by the import module.
- `/nxp` opens the nxPanels window; entry in Options > AddOns.
- Configuration window (`nxPanels_Options`, loaded on demand): Layouts, Panels (list by folders, editor General / Background / Border / Text / Scripts, changes drawn at once), Library, Import / Export, Profiles, Settings.
- Edit mode (`/nxp edit`): move and resize the panels with the mouse, grid, snapping to the screen and the other panels with alignment guides, arrow keys, Ctrl+Z.
- Adding or deleting a panel no longer restarts the scripts of the other panels.
- Translations of the window: English, French, Simplified and Traditional Chinese.
- Layout per specialization (Retail specializations, WoW Forever primary / secondary talents), replacing the profiles per specialization (LibDualSpec removed; schema 2).
- Profiles: one-click profile per class or faction, and a profile choice for new characters.
- Window appearance: "Workshop" (warm, default), "Ink" or "Night" style, and an accent color (gold, cyan, violet, jade, rose or class color).
- Edit mode moves smoothly: the grid is a magnet near its lines (off by default) instead of steps.
- Fixed: pasted text was invisible in the multi-line text boxes (import, panel text, scripts).
- Display conditions without scripts (combat, group, place, mount, target, pet battles, macro conditions) and opacity (base, in combat, under the mouse) with fades. Schema 3.
- Automatic colors for backgrounds and borders: class, faction, reaction of the target.
- Blizzard images (atlases) as backgrounds, and a texture browser with thumbnails.
- Text variables: {zone}, {time}, {fps}, {latency}, {gold}...
- Edit mode: several panels selected with Ctrl+click, moved together and aligned.
- Scripts: syntax check with the line number, last error shown in the editor.
- Export of one panel or one folder, pasted into another layout; gallery of templates; `nxPanels.RegisterMedia` for media packs.
- Fixed: values stored by scripts on a panel followed its frame to another panel after a layout switch.
- Fixed: export error on WoW Forever (division by zero in LibSerialize, patched); anchoring to protected frames of other addons (Retail 12 secret values).
- New panel menu: empty panel or a template (the gallery moved there); icons for the panel text.
- Text: every icon of the game (browser), currencies and items with {currency:<id>} and {item:<id>}, "Insert a currency" menu.
- Fixed: list rows kept the font of the font list (capitals, missing accents), icons were stretched.
- Import: a reload is also offered when the old kgPanels Reloaded was still running next to nxPanels (installed by hand), so its panels are not shown twice.

## 1.0.0-alpha.1 — 2026-09-27
- First version of nxPanels, a full rewrite: panels, backgrounds, borders, text, scripts.
- Retail 12.x and WoW Forever (16001) from one TOC.
- Language default font (Chinese and Korean text readable).
- Automatic import of kgPanels and kgPanels Reloaded layouts.
