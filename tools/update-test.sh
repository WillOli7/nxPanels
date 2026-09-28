#!/usr/bin/env bash
# Update test (phase B of docs/publication/PUBLICATION.md): simulates, on the local Retail
# client, what the CurseForge app does when a kgPanels_Reloaded v0.4.0 user gets nxPanels.
# Game closed for every step.
#
#   bash tools/update-test.sh prepare        backup, then back to the state of a v0.4.0 user
#   bash tools/update-test.sh update <zip>   what the app does: old folders out, zip folders in
#   bash tools/update-test.sh check          kgPanelsDB unchanged? (compared with .local/)
#   bash tools/update-test.sh restore        nxPanels data back, working copy installed again
#
# Nothing is ever deleted without a copy: the backup goes to
# _retail_/Interface/AddOns-backup-kgPanels/phaseB-<date>/.

cd "$(dirname "$0")/.." || exit 1

WOW_DIR="${WOW_DIR:-/c/Program Files (x86)/World of Warcraft}"
ACCOUNT="${ACCOUNT:-DARKICE7}"
OLD_VERSION="${OLD_VERSION:-20260927-135414}"
LUAJIT="${LUAJIT:-/c/Users/Muse/AppData/Local/Programs/LuaJIT/bin/luajit.exe}"

BASE="$WOW_DIR/_retail_"
ADDONS="$BASE/Interface/AddOns"
BACKUPS="$BASE/Interface/AddOns-backup-kgPanels"
SV="$BASE/WTF/Account/$ACCOUNT/SavedVariables"
FOLDERS="nxPanels nxPanels_Options nxPanels_Import kgPanels_Reloaded kgPanelsConfig_Reloaded"

die() { echo "ERROR: $*"; exit 1; }
latest_backup() { ls -d "$BACKUPS"/phaseB-* 2>/dev/null | tail -1; }

game_closed() { tasklist 2>/dev/null | grep -qi "^Wow" && die "the game is running, close it first"; }
[ -d "$SV" ] || die "saved variables not found: $SV"

case "$1" in
prepare)
	game_closed
	old="$BACKUPS/$OLD_VERSION"
	[ -f "$old/kgPanels_Reloaded/kgPanels_Reloaded.lua" ] || die "v0.4.0 not found in $old"
	backup="$BACKUPS/phaseB-$(date +%Y%m%d-%H%M%S)"
	mkdir -p "$backup/AddOns" "$backup/SavedVariables"
	echo "Backup of WTF (about 100 MB)..."
	cp -rp "$BASE/WTF" "$backup/WTF" || die "WTF backup failed"
	for folder in $FOLDERS; do
		[ -d "$ADDONS/$folder" ] && mv "$ADDONS/$folder" "$backup/AddOns/"
	done
	for f in nxPanels.lua nxPanels.lua.bak; do
		[ -f "$SV/$f" ] && mv "$SV/$f" "$backup/SavedVariables/"
	done
	cp -r "$old/kgPanels_Reloaded" "$old/kgPanelsConfig_Reloaded" "$ADDONS/"
	echo "Backup: $backup"
	echo "v0.4.0 installed, nxPanels removed and its data set aside."
	echo "Next: start the game (tick 'Load out of date AddOns'), check the v0.4.0 panels, quit."
	;;
update)
	game_closed
	zip="$2"
	[ -f "$zip" ] || die "usage: bash tools/update-test.sh update <path to the nxPanels zip>"
	[ -f "$ADDONS/kgPanels_Reloaded/kgPanels_Reloaded.lua" ] || die "v0.4.0 is not installed: run 'prepare' first"
	rm -rf "${ADDONS:?}/kgPanels_Reloaded" "${ADDONS:?}/kgPanelsConfig_Reloaded"
	unzip -q -o "$zip" -d "$ADDONS" || die "unzip failed"
	for folder in $FOLDERS; do
		[ -d "$ADDONS/$folder" ] || die "missing folder after unzip: $folder"
	done
	grep -q "^## SavedVariables: kgPanelsDB" "$ADDONS/kgPanels_Reloaded/kgPanels_Reloaded.toc" || die "bridge TOC without kgPanelsDB"
	[ -f "$ADDONS/kgPanels_Reloaded/kgPanels_Reloaded.lua" ] && die "old kgPanels_Reloaded.lua still there"
	echo "Update done: $FOLDERS"
	echo "Next: start the game and check the import message, the panels, /nxp status, /reload, another character."
	;;
check)
	[ -f .local/kgPanels_Reloaded.lua ] || die ".local/kgPanels_Reloaded.lua not found"
	"$LUAJIT" - "$SV/kgPanels_Reloaded.lua" .local/kgPanels_Reloaded.lua <<'EOF'
local function load(path)
	local env = {}
	local chunk = assert(loadfile(path))
	setfenv(chunk, env)()
	return env.kgPanelsDB
end
local function same(a, b, path)
	if type(a) ~= type(b) then return false, path end
	if type(a) ~= "table" then return a == b, path end
	for k, v in pairs(a) do
		local ok, where = same(v, b[k], path .. "." .. tostring(k))
		if not ok then return false, where end
	end
	for k in pairs(b) do
		if a[k] == nil then return false, path .. "." .. tostring(k) end
	end
	return true
end
local ok, where = same(load(arg[1]), load(arg[2]), "kgPanelsDB")
print(ok and "kgPanelsDB unchanged: OK" or ("kgPanelsDB CHANGED at " .. where))
os.exit(ok and 0 or 1)
EOF
	;;
restore)
	game_closed
	backup="$(latest_backup)"
	[ -n "$backup" ] || die "no phaseB backup found"
	for f in nxPanels.lua nxPanels.lua.bak; do
		[ -f "$SV/$f" ] && mv "$SV/$f" "$SV/$f.phaseB"
		[ -f "$backup/SavedVariables/$f" ] && cp -p "$backup/SavedVariables/$f" "$SV/"
	done
	bash tools/deploy.sh retail
	echo "nxPanels data restored from $backup (the phase B data is kept as nxPanels.lua.phaseB)."
	;;
*)
	sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
	exit 1
	;;
esac
