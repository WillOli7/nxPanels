#!/usr/bin/env bash
# Runs the static check (tools/lint.sh) and every offline scenario.
# Usage: bash tools/tests/run-all.sh [path/to/luajit]
# LuaJIT is found on the PATH (Mac, CI) or in its install folder on the PC when no path is given.
# Without lua-language-server the static check is skipped locally, and fails in CI.
cd "$(dirname "$0")/../.." || exit 1
LJ="$1"
if [ -z "$LJ" ]; then
	LJ="$(command -v luajit 2>/dev/null)"
	[ -z "$LJ" ] && [ -x "$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe" ] && LJ="$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe"
	[ -z "$LJ" ] && { echo "run-all: luajit not found, give its path: bash tools/tests/run-all.sh <luajit>" >&2; exit 1; }
fi
status=0
bash tools/lint.sh
case $? in
	0) ;;
	2) [ -n "$CI" ] && status=1 || echo "run-all: static check skipped" ;;
	*) status=1 ;;
esac
for s in migrate original handinstall empty nolibs notloaded forever tbc zhcn options; do
	"$LJ" tools/tests/run.lua "$s" || status=1
done
for locale in enUS zhCN zhTW deDE esES esMX itIT koKR ptBR ruRU; do
	"$LJ" tools/tests/run.lua options "$locale" || status=1
done
if [ -n "$NXP_REAL_SV" ]; then
	"$LJ" tools/tests/run.lua real || status=1
fi
exit $status
