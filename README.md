# nxPanels

**nxPanels** adds artistic panels to your World of Warcraft interface: backgrounds, borders, text and scripts, placed anywhere and attached to any frame. Build an interface that is truly yours.

> 🚧 **Alpha.** The display engine, the import of older layouts, the configuration window and the edit mode are written; in-game testing is in progress.

## Supported clients

| Client | Interface |
|---|---|
| Retail (12.x) | 120000 – 120100 |
| WoW Forever | 16001 |

Every language is supported, including Simplified and Traditional Chinese: panel text uses the font of your client language by default.

## What is in the package

| Folder | Role |
|---|---|
| `nxPanels` | The addon: displays your panels. Light, always loaded. |
| `nxPanels_Options` | The configuration window, loaded only when you open it. |
| `nxPanels_Import` | Imports your kgPanels and kgPanels Reloaded layouts. Can be disabled once done. |
| `kgPanels_Reloaded`, `kgPanelsConfig_Reloaded` | Small placeholders that replace the old addon folders, so your old data can be read. |

## Coming from kgPanels or kgPanels Reloaded

Nothing to do: on the first start, your layouts, panels, folders, profiles and custom art are imported automatically, and the old addon is disabled. Your old data is never modified. Old scripts keep working: `kgPanels` becomes `nxPanels`, with the same functions.

Import again at any time with `/nxp import`. Old export strings can be pasted in the import window.

## Commands

`/nxpanels` or `/nxp` opens the nxPanels window. Other commands:

| Command | Action |
|---|---|
| `edit` | edit mode: move and resize the panels with the mouse |
| `layouts` | list your layouts |
| `layout <name>` | activate a layout |
| `enable` / `disable` / `toggle` | show or hide the panels |
| `minimap` | show or hide the minimap button |
| `status` | version and diagnostics |
| `help` | list of the commands |

## For script authors

Scripts use `self.bg`, `self.text`, `arg1`… of OnEvent and the `pressed` / `released` variables of OnClick. The API is available as `nxPanels`: `FetchFrame(name)`, `GetActiveLayout()`, `ActivateLayout(name)`, `Print(...)`. Every panel frame is also reachable as `nxPanel_<id>`.

A failing script is reported once and switched off until the next reload.

## Development

| Tool | Command |
|---|---|
| Offline tests (LuaJIT) | `bash tools/tests/run-all.sh path/to/luajit` |
| Library versions | `bash tools/check-libs.sh` |
| Local install (Retail + Forever beta) | `bash tools/deploy.sh all` |

See [CONTRIBUTING.md](CONTRIBUTING.md) for translations and pull requests, [Libs-VERSIONS.md](Libs-VERSIONS.md) for the embedded libraries and [docs/ROADMAP.md](docs/ROADMAP.md) for the roadmap.

## Origins

nxPanels exists thanks to **kgPanels** by **kagaro**, successor of **eePanels**. These addons showed how far an interface can go with a few well-placed panels, and made me want to carry the idea further: a more modern and practical interface for long-time users, and for new players who want an interface that belongs to them.

nxPanels is a complete rewrite and does not reuse their code, but it keeps their spirit. Thank you to their authors and to everyone who kept them alive.

## License

nxPanels is free software under the [GNU GPL v3 or later](LICENSE). It is and will stay free, in game and outside.
