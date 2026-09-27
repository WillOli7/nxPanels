#!/usr/bin/env bash
# Installs the working copy of nxPanels into the local game, for testing.
# Usage: bash tools/deploy.sh [retail|forever|all] [--forever-testdata]
#
# - The legacy kgPanels_Reloaded / kgPanelsConfig_Reloaded folders are MOVED (never deleted)
#   to <flavor>/Interface/AddOns-backup-kgPanels/<date>/ and replaced by the migration bridge.
# - The legacy saved variables are COPIED to the same backup folder.
# - --forever-testdata copies your Retail kgPanels_Reloaded.lua saved variables into the
#   Forever client (only if Forever has none), to test the migration there too.

cd "$(dirname "$0")/.." || exit 1

WOW_DIR="${WOW_DIR:-/c/Program Files (x86)/World of Warcraft}"
TARGET="${1:-all}"
TESTDATA=0
[ "$2" = "--forever-testdata" ] && TESTDATA=1

FOLDERS="nxPanels nxPanels_Options nxPanels_Import kgPanels_Reloaded kgPanelsConfig_Reloaded"
STAMP="$(date +%Y%m%d-%H%M%S)"

deploy() {
	local flavor="$1"
	local base="$WOW_DIR/$flavor"
	local addons="$base/Interface/AddOns"
	if [ ! -d "$base" ]; then
		echo "[$flavor] client not found: $base"
		return
	fi
	mkdir -p "$addons"
	local backup="$base/Interface/AddOns-backup-kgPanels/$STAMP"

	# Legacy addon folders (the bridge has Bridge.lua, the placeholder has no .lua file)
	if [ -f "$addons/kgPanels_Reloaded/kgPanels_Reloaded.lua" ]; then
		mkdir -p "$backup"
		mv "$addons/kgPanels_Reloaded" "$backup/" && echo "[$flavor] legacy kgPanels_Reloaded moved to $backup"
	fi
	if [ -f "$addons/kgPanelsConfig_Reloaded/kgPanelsConfig_Reloaded.lua" ]; then
		mkdir -p "$backup"
		mv "$addons/kgPanelsConfig_Reloaded" "$backup/" && echo "[$flavor] legacy kgPanelsConfig_Reloaded moved to $backup"
	fi

	# Legacy saved variables: copied, the originals stay in place
	for sv in "$base"/WTF/Account/*/SavedVariables/kgPanels_Reloaded.lua "$base"/WTF/Account/*/SavedVariables/kgPanels.lua; do
		[ -f "$sv" ] || continue
		local account
		account="$(basename "$(dirname "$(dirname "$sv")")")"
		mkdir -p "$backup/SavedVariables/$account"
		cp -p "$sv" "$backup/SavedVariables/$account/" && echo "[$flavor] saved variables backed up: $account/$(basename "$sv")"
	done

	for folder in $FOLDERS; do
		rm -rf "${addons:?}/${folder:?}"
		cp -r "$folder" "$addons/$folder"
	done
	echo "[$flavor] installed: $FOLDERS"
}

forever_testdata() {
	local retail_sv
	retail_sv="$(ls "$WOW_DIR"/_retail_/WTF/Account/*/SavedVariables/kgPanels_Reloaded.lua 2>/dev/null | head -1)"
	[ -f "$retail_sv" ] || { echo "[forever] no Retail kgPanels_Reloaded.lua to copy"; return; }
	for account in "$WOW_DIR"/_classic_beta_/WTF/Account/*/; do
		[ -d "$account" ] || continue
		[ "$(basename "$account")" = "SavedVariables" ] && continue
		mkdir -p "$account/SavedVariables"
		if [ -f "$account/SavedVariables/kgPanels_Reloaded.lua" ]; then
			echo "[forever] $(basename "$account") already has kgPanels data, not overwritten"
		else
			cp -p "$retail_sv" "$account/SavedVariables/" && echo "[forever] test data copied to $(basename "$account")"
		fi
	done
}

case "$TARGET" in
	retail) deploy _retail_ ;;
	forever) deploy _classic_beta_ ;;
	all) deploy _retail_; deploy _classic_beta_ ;;
	*) echo "Usage: bash tools/deploy.sh [retail|forever|all] [--forever-testdata]"; exit 1 ;;
esac
[ "$TESTDATA" = 1 ] && forever_testdata
echo "Done. Restart the game (a /reload is not enough for new or changed .toc files)."
