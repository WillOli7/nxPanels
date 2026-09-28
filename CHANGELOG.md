# Changelog

All notable changes to nxPanels. Versions follow [Semantic Versioning](https://semver.org/).

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
