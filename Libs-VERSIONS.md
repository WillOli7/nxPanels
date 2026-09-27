# Librairies embarquées

Les librairies sont intégrées directement dans l'addon. Avant chaque release, lancer `tools/check-libs.sh` pour comparer ces versions aux dernières disponibles.

Dernière mise à jour : 2026-09-27

## Socle — `nxPanels/Libs`

| Librairie | Version (MINOR) | Source | Révision |
|---|---|---|---|
| LibStub | 2 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| CallbackHandler-1.0 | 8 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceDB-3.0 | 39 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` (compatibilité WoW Forever, absente de la release r1403) |
| AceLocale-3.0 | 6 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceSerializer-3.0 | 5 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| LibSharedMedia-3.0 | 12000002 | [WowAce SVN](https://repos.wowace.com/wow/libsharedmedia-3-0/trunk/) | trunk r177 |
| LibDualSpec-1.0 | 35 | [AdiAddons/LibDualSpec-1.0](https://github.com/AdiAddons/LibDualSpec-1.0) | master `71dcd66` |
| LibSerialize | 6 (v1.2.2) | [rossnichols/LibSerialize](https://github.com/rossnichols/LibSerialize) | tag `v1.2.2` |
| LibDeflate | 3 (1.0.2-release) | [SafeteeWoW/LibDeflate](https://github.com/SafeteeWoW/LibDeflate) | tag `1.0.2-release` |
| LibDataBroker-1.1 | 4 | [WowAce SVN (libdbicon)](https://repos.wowace.com/wow/libdbicon-1-0/trunk/) | trunk r162 |
| LibDBIcon-1.0 | 56 | [WowAce SVN](https://repos.wowace.com/wow/libdbicon-1-0/trunk/) | trunk r162 |

## Configuration — `nxPanels_Options/Libs`

Conservées pendant la transition, jusqu'à la nouvelle interface de configuration.

| Librairie | Version (MINOR) | Source | Révision |
|---|---|---|---|
| AceGUI-3.0 | 41 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceConfig-3.0 | 3 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceConfigDialog-3.0 | 93 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceConfigRegistry-3.0 | 22 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceConfigCmd-3.0 | 14 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceDBOptions-3.0 | 17 | [WoWUIDev/Ace3](https://github.com/WoWUIDev/Ace3) | master `a360495` |
| AceGUI-3.0-SharedMediaWidgets | 9004 (r65) | [WowAce](https://www.wowace.com/projects/ace-gui-3-0-shared-media-widgets) | r65 (2020, plus maintenue) |

## Retirées (phase 1)

| Librairie | Raison |
|---|---|
| AceAddon-3.0, AceConsole-3.0 | Remplacées par du code maison (v1.0) |
| LibBackdrop-1.0 | Abandonnée depuis 2018 → bordure maison |
| LibStub dans LibDualSpec-1.0 | Doublon |
