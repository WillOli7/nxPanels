# Changelog

All notable changes to nxPanels. Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## 1.0.0-alpha.2 — in progress
- Legacy import moved to the separate `nxPanels_Import` module; the core has no dependency on older addons.
- Old scripts are rewritten on import (`kgPanels` becomes `nxPanels`, same functions).
- Layout export / import (`!NXP1!` strings); old export strings are read by the import module.
- `/nxp` opens the nxPanels window; entry in Options > AddOns.
- Configuration window (`nxPanels_Options`, loaded on demand): Layouts, Panels (list by folders, editor General / Background / Border / Text / Scripts, changes drawn at once), Library, Import / Export, Profiles (with profiles per specialization), Settings.
- Edit mode (`/nxp edit`): move and resize the panels with the mouse, grid, snapping to the screen and the other panels with alignment guides, arrow keys, Ctrl+Z.
- Adding or deleting a panel no longer restarts the scripts of the other panels.
- Translations of the window: English, French, Simplified and Traditional Chinese.

## 1.0.0-alpha.1 — 2026-09-27
- First version of nxPanels, a full rewrite: panels, backgrounds, borders, text, scripts.
- Retail 12.x and WoW Forever (16001) from one TOC.
- Language default font (Chinese and Korean text readable).
- Automatic import of kgPanels and kgPanels Reloaded layouts.
