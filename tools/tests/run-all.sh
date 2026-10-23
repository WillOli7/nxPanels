#!/usr/bin/env bash
# Runs every offline scenario. Usage: bash tools/tests/run-all.sh [path/to/luajit]
cd "$(dirname "$0")/../.." || exit 1
LJ="${1:-luajit}"
status=0
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
