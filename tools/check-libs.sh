#!/usr/bin/env bash
# Compare les versions (MINOR) des librairies embarquées avec les dernières versions en ligne.
# Usage : bash tools/check-libs.sh   (depuis la racine du dépôt)

cd "$(dirname "$0")/.." || exit 1

CORE=nxPanels/Libs
CONF=nxPanels_Options/Libs
ACE=https://raw.githubusercontent.com/WoWUIDev/Ace3/master
SVN=https://repos.wowace.com/wow

# nom | fichier local | URL distante
LIBS="
LibStub|$CORE/LibStub/LibStub.lua|$ACE/LibStub/LibStub.lua
CallbackHandler-1.0|$CORE/CallbackHandler-1.0/CallbackHandler-1.0.lua|$ACE/CallbackHandler-1.0/CallbackHandler-1.0.lua
AceDB-3.0|$CORE/AceDB-3.0/AceDB-3.0.lua|$ACE/AceDB-3.0/AceDB-3.0.lua
AceLocale-3.0|$CORE/AceLocale-3.0/AceLocale-3.0.lua|$ACE/AceLocale-3.0/AceLocale-3.0.lua
AceSerializer-3.0|$CORE/AceSerializer-3.0/AceSerializer-3.0.lua|$ACE/AceSerializer-3.0/AceSerializer-3.0.lua
LibSharedMedia-3.0|$CORE/LibSharedMedia-3.0/LibSharedMedia-3.0.lua|$SVN/libsharedmedia-3-0/trunk/LibSharedMedia-3.0/LibSharedMedia-3.0.lua
LibDualSpec-1.0|$CORE/LibDualSpec-1.0/LibDualSpec-1.0.lua|https://raw.githubusercontent.com/AdiAddons/LibDualSpec-1.0/master/LibDualSpec-1.0.lua
LibSerialize|$CORE/LibSerialize/LibSerialize.lua|https://raw.githubusercontent.com/rossnichols/LibSerialize/master/LibSerialize.lua
LibDeflate|$CORE/LibDeflate/LibDeflate.lua|https://raw.githubusercontent.com/SafeteeWoW/LibDeflate/main/LibDeflate.lua
LibDataBroker-1.1|$CORE/LibDataBroker-1.1/LibDataBroker-1.1.lua|$SVN/libdbicon-1-0/trunk/LibDataBroker-1.1/LibDataBroker-1.1.lua
LibDBIcon-1.0|$CORE/LibDBIcon-1.0/LibDBIcon-1.0.lua|$SVN/libdbicon-1-0/trunk/LibDBIcon-1.0/LibDBIcon-1.0.lua
AceGUI-3.0|$CONF/AceGUI-3.0/AceGUI-3.0.lua|$ACE/AceGUI-3.0/AceGUI-3.0.lua
AceConfig-3.0|$CONF/AceConfig-3.0/AceConfig-3.0.lua|$ACE/AceConfig-3.0/AceConfig-3.0.lua
AceConfigDialog-3.0|$CONF/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua|$ACE/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua
AceConfigRegistry-3.0|$CONF/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua|$ACE/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua
AceConfigCmd-3.0|$CONF/AceConfig-3.0/AceConfigCmd-3.0/AceConfigCmd-3.0.lua|$ACE/AceConfig-3.0/AceConfigCmd-3.0/AceConfigCmd-3.0.lua
AceDBOptions-3.0|$CONF/AceDBOptions-3.0/AceDBOptions-3.0.lua|$ACE/AceDBOptions-3.0/AceDBOptions-3.0.lua
"

# Première déclaration de version trouvée dans le fichier (formats LibStub, LibDeflate, LibDBIcon)
minor() {
	grep -m1 -oE '(MINOR|_MINOR) *= *"[^"]+", *[0-9]+|DBICON10_MINOR *= *[0-9]+|local _MINOR *= *[0-9]+|NewLibrary\("[^"]+", *[0-9]+' \
		| grep -oE '[0-9]+$'
}

outdated=0
printf "%-24s %12s %12s  %s\n" "Librairie" "Embarquée" "En ligne" "État"
while IFS='|' read -r name file url; do
	[ -z "$name" ] && continue
	local_v=$(minor < "$file" 2>/dev/null)
	remote_v=$(curl -fsL "$url" 2>/dev/null | minor)
	if [ -z "$remote_v" ]; then
		state="source injoignable"
	elif [ -z "$local_v" ]; then
		state="MANQUANTE"; outdated=1
	elif [ "$remote_v" -gt "$local_v" ]; then
		state="À METTRE À JOUR"; outdated=1
	else
		state="ok"
	fi
	printf "%-24s %12s %12s  %s\n" "$name" "${local_v:--}" "${remote_v:--}" "$state"
done <<< "$LIBS"

exit $outdated
