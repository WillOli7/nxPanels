# nxPanels — project guide

Artistic panels addon for World of Warcraft (Retail 12.x, WoW Forever and TBC Anniversary), a full rewrite, all rights reserved (see `LICENSE`; the embedded libraries keep their own licenses). The maintainer writes in French: answer in French.

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
- **One TOC per addon** lists every interface number (Retail 1200xx, Forever 16001, TBC Anniversary 20505 and 20506).
- **Embedded libraries** stay in the repository; versions in `Libs-VERSIONS.md`, checked with `bash tools/check-libs.sh`. Ace3 comes from its master branch (AceDB WoW Forever support).
- **Never break the migration from kgPanels_Reloaded** (invariants in `docs/SUIVI.md` section 5): keep the `kgPanels_Reloaded` bridge folder with `## SavedVariables: kgPanelsDB`, never write to `kgPanelsDB`, run the `migrate`, `original` and `real` scenarios before any release.
- **WoW Forever raises an error on division by zero**: never divide by a value that can be 0. LibSerialize handles it since v1.2.3 (official fix, no local patch any more).
- Lua 5.1, tabs, comments in English, one module per file (`local _, ns = ...`).

## Workflow
- Start of a session: `git pull`, then read `docs/SUIVI.md`. End of a session: update `docs/SUIVI.md`, commit and **push the working branch** (never `main`), so the other computer can resume with `git pull` alone. Opening or merging a pull request still needs the maintainer's go-ahead.
- Documentation sources: WoW API signatures, events, restrictions and Interface numbers come only from the `wow-addon-dev` skill (`wowapi.py lookup` / `event` / `audit`, Blizzard's docs for the exact client build). Context7 (account connector) is for the language and tools: Lua 5.1 manual `/websites/lua_manual_5_1` (never the 5.3 / 5.4 manuals: no `goto`, `//`, `utf8` in WoW), Ace3 `/hurricup/wow-ace3`, LuaJIT, Python, bash, GitHub Actions. Its WoW API pages (wiki copies) have no build or flavor and can be stale: use them for explanations only, then check with `lookup`.
- Before every commit: `bash tools/tests/run-all.sh` (finds LuaJIT itself; add checks for new behavior in `tools/tests/run.lua`). It starts with the static check `bash tools/lint.sh`: lua-language-server with `.luarc.json` (Lua 5.1, WoW API annotations by Ketho, `Libs/` skipped) must report no problem. An intended exception gets the line `---@diagnostic disable-next-line: <code> -- <reason>` above it; a Blizzard FrameXML global missing from the annotations goes into `diagnostics.globals` of `.luarc.json`. GitHub runs the same checks on every push (`.github/workflows/tests.yml`).
- Local game install for the maintainer's tests: `bash tools/deploy.sh all` (game closed; a restart is needed for TOC changes).
- Branches: `main` stable, `feature/<name>` then pull request. Commit messages in English.
- Nothing is published to CurseForge until it works in game on Retail, Forever and TBC Anniversary.
- GitHub Actions are pinned by commit; Dependabot opens a monthly pull request to update them (merge it when Tests pass). lua-language-server in CI is pinned with its checksum in `.github/actions/setup-lua/action.yml`.
- 1.0.0 released on 2026-09-29 (maintainer's choice). Still to do from the original v1.0 criteria: native review of the Chinese translations, layout per talent group tested in game on WoW Forever.

## Two computers (Mac and gaming PC)
Everything shared lives in this repository (GitHub): rules here, state in `docs/SUIVI.md`. No hand-off files outside the repository. Set up once per computer:
- `git`, `gh` (logged in), LuaJIT and lua-language-server (Mac: `brew install luajit lua-language-server`; PC: winget, see `docs/SUIVI.md` section 2).
- Claude Code plugin `wow@willoli7-skills` (skill `wow-addon-dev`), then `bash <skill>/scripts/setup.sh live forever classic_anniversary`. Context7 is an account connector: nothing to install.
- Only on the gaming PC: the game (`tools/deploy.sh`) and `.local/` (real kgPanels data for the `real` scenario, never committed).
