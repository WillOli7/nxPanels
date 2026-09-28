# Contributing to nxPanels

Thanks for helping! nxPanels is free to use, but its code is not open source (see [LICENSE](LICENSE)). By sending a contribution (code, translation, image), you agree that it may be distributed with nxPanels under its license.

## Report a bug
Open an issue with the "Bug report" template. Please include the error text from BugSack / BugGrabber and the output of `/nxp status`.

## Translations
Texts live in `nxPanels/Locales/<locale>.lua` (and `nxPanels_Import/Locales.lua`). Copy the keys of `enUS.lua` and translate the values. Native speakers are very welcome, especially for Simplified and Traditional Chinese (`zhCN`, `zhTW`), whose current texts still need a review.

Never translate data keys (texture names, anchor points...): only the displayed texts.

## Code
- Lua 5.1, the language of the game client. One module per file, `local _, ns = ...` namespace.
- Match the style of the surrounding code (tabs, comments in English, readable names).
- Run the offline tests before a pull request: `bash tools/tests/run-all.sh path/to/luajit`.
- Embedded libraries: see `Libs-VERSIONS.md`, check them with `bash tools/check-libs.sh`.

## Branches
- `main`: stable, what is released.
- `feature/<name>`: work in progress, merged through a pull request.
