# Librairies embarquées

Les librairies sont intégrées directement dans l'addon. Avant chaque release, lancer `tools/check-libs.sh` pour comparer ces versions aux dernières disponibles.

Dernière mise à jour : 2026-10-23

## Socle — `nxPanels/Libs`

| Librairie | Version (MINOR) | Source | Révision |
|---|---|---|---|
| LibStub | 2 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| CallbackHandler-1.0 | 8 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceDB-3.0 | 39 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` (compatibilité WoW Forever, absente de la release r1403) |
| AceLocale-3.0 | 6 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceSerializer-3.0 | 5 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| LibSharedMedia-3.0 | 12000005 | [WowAce SVN](https://repos.wowace.com/wow/libsharedmedia-3-0/trunk/) | trunk r185. Signale un fichier inconnu du jeu ou hors du dossier Interface par une erreur Lua (`geterrorhandler`) : nxPanels ne lui transmet que les fichiers connus (`Media:Share`) |
| LibSerialize | 7 (v1.2.3) | [rossnichols/LibSerialize](https://github.com/rossnichols/LibSerialize) | tag `v1.2.3`, sans modification : la correction de la division par zéro (WoW Forever) est désormais dans la version officielle |
| LibDeflate | 3 (1.0.2-release) | [SafeteeWoW/LibDeflate](https://github.com/SafeteeWoW/LibDeflate) | tag `1.0.2-release` |
| LibDataBroker-1.1 | 4 | [WowAce SVN (libdbicon)](https://repos.wowace.com/wow/libdbicon-1-0/trunk/) | trunk r162 |
| LibDBIcon-1.0 | 57 | [WowAce SVN](https://repos.wowace.com/wow/libdbicon-1-0/trunk/) | trunk r168 (compartiment d'addons détecté par sa présence, utile pour TBC Anniversary) |

`nxPanels_Options` n'embarque aucune librairie : il utilise celles du socle.

## Retirées

| Librairie | Raison |
|---|---|
| AceAddon-3.0, AceConsole-3.0 | Remplacées par du code maison (v1.0) |
| LibBackdrop-1.0 | Abandonnée depuis 2018 → bordure maison |
| LibStub dans LibDualSpec-1.0 | Doublon |
| LibDualSpec-1.0 | Profils par spécialisation remplacés par un layout par spécialisation (code maison, Retail et Forever) |
| AceGUI-3.0, AceConfig-3.0 (Dialog, Registry, Cmd), AceDBOptions-3.0, AceGUI-3.0-SharedMediaWidgets | Remplacées par la fenêtre de configuration maison (phase 2b) |
