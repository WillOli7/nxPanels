#!/usr/bin/env bash
# Static check of the addon code with lua-language-server, configured by .luarc.json:
# Lua 5.1 only (the game's version), WoW API from Ketho's annotations, embedded Libs skipped.
# Usage: bash tools/lint.sh [--update]
#   --update   refresh the WoW API annotations (also refreshed by the wow-addon-dev skill's setup.sh)
# Exit: 0 clean, 1 problems found, 2 lua-language-server missing.
# An intended exception is marked on the line above it, with the reason:
#   ---@diagnostic disable-next-line: deprecated -- fallback for clients without the C_ function
cd "$(dirname "$0")/.." || exit 1

ANNOTATIONS_REPO=https://github.com/Ketho/vscode-wow-api
ANNOTATIONS_DIR="$HOME/.cache/wow-addon-dev/vscode-wow-api"   # same path as in .luarc.json

# lua-language-server: $LUALS, the PATH (Homebrew on the Mac, CI), then the winget install of the PC
LS="${LUALS:-$(command -v lua-language-server 2>/dev/null)}"
if [ -z "$LS" ]; then
	for f in "$LOCALAPPDATA"/Microsoft/WinGet/Packages/LuaLS.lua-language-server_*/bin/lua-language-server.exe; do
		[ -x "$f" ] && LS="$f"
	done
fi
if [ -z "$LS" ]; then
	echo "lint: lua-language-server not found (Mac: brew install lua-language-server, PC: winget install LuaLS.lua-language-server)" >&2
	exit 2
fi

# WoW API annotations (MIT), shared with the wow-addon-dev skill
if [ ! -d "$ANNOTATIONS_DIR/Annotations" ]; then
	echo "lint: downloading the WoW API annotations"
	mkdir -p "$(dirname "$ANNOTATIONS_DIR")"
	git clone --quiet --depth 1 "$ANNOTATIONS_REPO" "$ANNOTATIONS_DIR" || exit 1
elif [ "$1" = "--update" ]; then
	git -C "$ANNOTATIONS_DIR" pull --quiet --ff-only || exit 1
fi

# Windows: lua-language-server wants native paths
root="$PWD"
command -v cygpath > /dev/null && root="$(cygpath -w "$PWD")"

out="$("$LS" --check="$root" --checklevel=Warning 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tr '\r' '\n')"
if printf '%s\n' "$out" | grep -q "no problems found"; then
	echo "lint: no problems ($("$LS" --version 2>/dev/null), annotations $(git -C "$ANNOTATIONS_DIR" log -1 --format=%cs 2>/dev/null))"
	exit 0
fi
printf '%s\n' "$out" | grep -E "\.lua:[0-9]+:[0-9]+ |problems found" | awk '!seen[$0]++'
exit 1
