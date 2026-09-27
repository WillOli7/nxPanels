# nxPanels

**nxPanels** adds artistic panels to your World of Warcraft interface: backgrounds, borders, text and scripts, placed anywhere and attached to any frame.

It is the next generation of kgPanels: a full rewrite with its own code, built for today's clients.

> 🚧 **Alpha.** The display engine and the migration are ready; the configuration window comes in the next milestone.

## Supported clients

| Client | Interface |
|---|---|
| Retail (The War Within / Midnight, 12.x) | 120000 – 120100 |
| WoW Forever | 16001 |

Every language is supported, including Simplified and Traditional Chinese: text uses the font of your client language by default.

## Coming from kgPanels or kgPanels Reloaded

Nothing to do: on the first start, nxPanels imports your layouts, panels, folders, profiles and custom art automatically, then disables the old addon. Your old data is never modified.

- **kgPanels Reloaded**: install nxPanels over it. The package replaces the old folders with a small `kgPanels_Reloaded` bridge used for the import.
- **Original kgPanels**: keep it enabled for the first start of nxPanels, it is detected and imported.
- Import again at any time with `/nxp import` (added as new layouts).

## Commands

`/nxpanels` or `/nxp`:

| Command | Action |
|---|---|
| `layouts` | list your layouts |
| `layout <name>` | activate a layout |
| `enable` / `disable` / `toggle` | show or hide the panels |
| `import` | import kgPanels data again |
| `minimap` | show or hide the minimap button |
| `status` | version and diagnostics |

The minimap button and the addon compartment open a layout menu (left-click) and toggle the panels (right-click).

## For script authors

Panel scripts keep working: `self.bg`, `self.text`, `kgPanels:FetchFrame(name)`, `arg1`… and the `pressed` / `released` variables of OnClick. The new API is available as `nxPanels` (`GetPanelFrame`, `GetActiveLayout`, `ActivateLayout`). Every panel frame is also reachable as `nxPanel_<id>`.

A failing script is reported once and switched off until the next reload.

## Development

| Tool | Command |
|---|---|
| Offline tests (LuaJIT) | `bash tools/tests/run-all.sh path/to/luajit` |
| Library versions | `bash tools/check-libs.sh` |
| Local install (Retail + Forever beta) | `bash tools/deploy.sh all` |

Embedded libraries and their versions: [Libs-VERSIONS.md](Libs-VERSIONS.md). Roadmap and ideas: [docs/ROADMAP.md](docs/ROADMAP.md).

## License and credits

nxPanels is free software under the [GNU GPL v3 or later](LICENSE). It will always be free, in game and outside.

Thanks to **kagaro** (kgPanels) and to the authors of **eePanels**, whose addons inspired this project. nxPanels does not reuse their code.
