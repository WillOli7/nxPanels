# nxPanels — project guide

Artistic panels addon for World of Warcraft (Retail 12.x and WoW Forever), a full rewrite released under GPL-3.0-or-later. The maintainer writes in French: answer in French.

## Layout of the repository
| Folder | Role |
|---|---|
| `nxPanels/` | Core addon, always loaded: `Core/` (init, database, share, API, commands), `Engine/` (layouts, anchors, scripts), `Render/` (panel, border), `Media/`, `Locales/`, `Libs/` |
| `nxPanels_Options/` | Configuration window, load on demand: `UI/` (theme, widgets, dropdown, window), `Pages/`, `EditMode/` |
| `nxPanels_Import/` | Temporary import of kgPanels / kgPanels Reloaded data |
| `kgPanels_Reloaded/`, `kgPanelsConfig_Reloaded/` | Placeholders: the folder name is required to read the old SavedVariables file |
| `tools/` | `tests/` (offline tests with a WoW API mock), `check-libs.sh`, `deploy.sh` |
| `docs/ROADMAP.md` | Roadmap and idea backlog, in French |
| `docs/SUIVI.md` | Tracking file, in French: current state, decisions, migration invariants, in-game tests. Read it first, update it at the end of each session |

## Rules
- **No mention of kgPanels or eePanels in `nxPanels/` or `nxPanels_Options/`.** Everything about the old addons lives in `nxPanels_Import/` and plugs into the core (`Commands:Register`, `Share:RegisterDecoder`). The README "Origins" credit stays.
- **Never translate data keys** (texture names, points, styles): translate only displayed texts. Texts live in `nxPanels/Locales/`.
- **Chinese clients:** fonts always fall back to `STANDARD_TEXT_FONT`; never hard-code a latin font.
- **Data schema:** stable ids (`L<n>` layouts, `P<n>` panels), references `panel:<id>`, texture "none" is `false` (nil is replaced by defaults). Bump `ns.SCHEMA` and add an upgrade step for any schema change.
- **One TOC per addon** lists every interface number (Retail 1200xx and Forever 16001).
- **Embedded libraries** stay in the repository; versions in `Libs-VERSIONS.md`, checked with `bash tools/check-libs.sh`. Ace3 comes from its master branch (AceDB WoW Forever support).
- **Never break the migration from kgPanels_Reloaded** (invariants in `docs/SUIVI.md` section 5): keep the `kgPanels_Reloaded` bridge folder with `## SavedVariables: kgPanelsDB`, never write to `kgPanelsDB`, run the `migrate`, `original` and `real` scenarios before any release.
- **WoW Forever raises an error on division by zero**: never divide by a value that can be 0. LibSerialize is patched for this (keep the "nxPanels patch" lines when updating it).
- Lua 5.1, tabs, comments in English, one module per file (`local _, ns = ...`).

## Workflow
- Start of a session: read `docs/SUIVI.md`; end of a session: update it.
- Offline tests before every commit: `bash tools/tests/run-all.sh <path to luajit>` (add checks for new behavior in `tools/tests/run.lua`).
- Local game install for the maintainer's tests: `bash tools/deploy.sh all` (game closed; a restart is needed for TOC changes).
- Branches: `main` stable, `feature/<name>` then pull request. Commit messages in English.
- Nothing is published to CurseForge until it works in game on Retail and Forever.
- v1.0 is validated when: code fully rewritten, Chinese clients fully supported, WoW Forever fully compatible.
