# nxPanels — Fichier de suivi

Document de reprise : l'état exact du projet, pour continuer dans une nouvelle conversation sans rien réinventer.
À lire avec `CLAUDE.md` (règles du projet) et `docs/ROADMAP.md` (idées et backlog).
**Mettre ce fichier à jour à la fin de chaque session de travail.**

Dernière mise à jour : 2026-10-26 (1.2.0, suggestions d'interface d'Aur0r4)

---

## 1. État actuel

| Élément | État |
|---|---|
| Version | **`1.1.1` publiée en release le 2026-10-23** (PR #20, tag `1.1.1`, compatibilité Retail 12.1.5 seulement : interface 120105, pas de fenêtre des nouveautés ; envoyée sur CurseForge pour Retail 12.0.0–12.1.5, TBC Anniversary 2.5.5 / 2.5.6 et Forever 1.60.1). Avant : `1.1.0` (2026-10-23, PR #18), `1.0.0` (2026-09-29) |
| Branche de travail | **`feature/ui-aurora`** (version 1.2.0 : saisie du nom de frame, déplacement au pixel, barres de défilement déplaçables, section 7 septies ; poussée, PR pas encore ouverte). Avant : `feature/code-review` fusionnée (PR #28, 2026-10-26) |
| Pull request | PR #1 à #28 fusionnées dans `main` ; aucune ouverte. #28 (2026-10-26) : revue du code et sens de répétition (future 1.1.2). #24 (Dependabot, 2026-10-25) : `actions/checkout` v4 → v7 et `actions/upload-artifact` v4 → v7, vérifiées par une construction de test de la release (run 40201091009 : vert, zip produit) |
| `main` | **en avance sur le tag `1.1.1`** : contient les correctifs de l'audit (PR #22) et de la revue du code (PR #28), future **1.1.2** pas encore publiée, et les outils de contrôle (PR #23). Ne pas présenter `main` comme la version publiée |
| Logo | ✅ 2026-09-28 (PR #4) : version stylisée (ChatGPT) pour GitHub / CurseForge dans `docs/media/`, version simplifiée (`docs/media/icon.svg` → `nxPanels/Media/icon.tga`) pour le jeu. Détails : `PUBLICATION.md` section 7. Icône vérifiée en jeu (Retail et Forever) le 2026-09-29. Reste : image sociale à envoyer à la main (Settings → Social preview) |
| Installé sur Mac | Retail (`/Applications/World of Warcraft/_retail_`, compte DARKICE7, aucune donnée kgPanels : test de première installation) via `WOW_DIR="/Applications/World of Warcraft" bash tools/deploy.sh retail`. Forever pas encore lancé sur ce Mac. Test en jeu à faire |
| Tests hors jeu | Tous verts : `bash tools/tests/run-all.sh` (contrôle statique `tools/lint.sh`, puis migrate, original, handinstall, empty, nolibs, notloaded, forever, tbc, zhcn, options ×11 langues) + `real` avec les vraies données |
| Installé en local | Oui, Retail (`_retail_`), Forever (`_classic_beta_`, bêta fermée jusqu'au 5 novembre) et TBC Anniversary (`_anniversary_`) via `bash tools/deploy.sh all`. Fichiers de test de la bibliothèque dans `Interface\AddOns\nxTestMedia\` (Retail, Anniversary) |
| CurseForge | Projet `1444518` **renommé nxPanels** (slug `nxpanels`, logo, description courte, licence « All Rights Reserved », distribution tierce refusée). Secret GitHub `CF_API_KEY` en place, envoi automatique au tag. Fichiers : **`nxPanels-1.1.1` (release, 2026-10-23, 12.1.5 inclus)**, `nxPanels-1.1.0` (release, 2026-10-23), `1.0.0` (release, 2026-09-29) ; `1.0.0-alpha.2` archivé. Description et résumé mis à jour pour la 1.1.0 le 2026-10-23 (source : `docs/publication/CURSEFORGE.md`) |
| Publication | Dossier prêt : `docs/publication/PUBLICATION.md` (étapes, test de mise à jour, message au modérateur, captures, brief du logo, GitHub) et `docs/publication/CURSEFORGE.md` (page CurseForge EN + FR / zhCN / zhTW). Workflow `.github/workflows/release.yml` (tag → release GitHub, CurseForge si secret `CF_API_KEY` ; lancement manuel = construction de test sans envoi) |
| Phase B | ✅ 2026-09-29 avec le zip du run sur `a805446` (`tools/update-test.sh`) : v0.4.0 affichée, puis mise à jour → 3 layouts / 33 panneaux importés, panneaux identiques, `/nxp status` sans erreur, anciens addons désactivés, `/reload` et autre personnage OK, `kgPanelsDB` inchangé. Installation remise en état (`restore`) |
| Paquet (phase A) | ✅ 2026-09-28 : construction de test OK (run 36355822045). 5 dossiers, pont intact, TOC en 1.0.0-alpha.2, rien de `tools` / `docs` / `CLAUDE.md`. Versions détectées par le packager : 12.0.0 à 12.1.0 + Forever 1.60.1. Le zip se retélécharge depuis le run GitHub (artefact « nxPanels-package », 90 jours) |

## 2. Contenu du dépôt

| Dossier | Rôle |
|---|---|
| `nxPanels/` | Cœur : données (AceDB, schéma **3**), rendu, bordures, ancrages, scripts, conditions d'affichage, couleurs automatiques, variables de texte, spécialisations, partage, API, commandes, traductions |
| `nxPanels_Options/` | Fenêtre de configuration (chargée à la demande) + mode édition |
| `nxPanels_Import/` | Import des données kgPanels / kgPanels Reloaded (temporaire, voir section 5) |
| `kgPanels_Reloaded/` | **Pont de migration** : déclare `kgPanelsDB` pour que nxPanels puisse lire l'ancien fichier |
| `kgPanelsConfig_Reloaded/` | Dossier vide qui remplace l'ancien module de config |
| `tools/` | Tests hors jeu (`tests/`), contrôle statique (`lint.sh`), `deploy.sh`, `check-libs.sh` |
| `docs/publication/` | Textes et procédure de la sortie publique (CurseForge, GitHub, logo) |

Outils locaux (hors PATH de Bash) :
- LuaJIT : `C:\Users\Muse\AppData\Local\Programs\LuaJIT\bin\luajit.exe` (trouvé tout seul par `run-all.sh`)
- lua-language-server 3.19.1 (winget `LuaLS.lua-language-server`, trouvé tout seul par `tools/lint.sh`)
- GitHub CLI : `"/c/Program Files/GitHub CLI/gh.exe"` (connecté en `WillOli7`)
- Skill Claude Code `wow-addon-dev` (plugin `wow` du marketplace privé `WillOli7/claude-skills`, créé le 2026-10-25 sur le Mac) : vérifie l'API contre le build actuel, audite un addon, compare deux patchs, met à jour `## Interface`. Installation : `/plugin marketplace add WillOli7/claude-skills` puis `/plugin install wow@willoli7-skills` (après `gh auth setup-git`) ; mise à jour : `/plugin marketplace update willoli7-skills`. Dans Git Bash : `bash <skill>/scripts/setup.sh live forever classic_anniversary` (indique la commande Python à utiliser). Point de comparaison `baseline 12.1.0` créé sur le PC le 2026-10-25. Au prochain patch : `setup.sh`, puis `wowapi.py changes --addon nxPanels`
- Connecteur **Context7** (branché sur le compte Claude le 2026-10-25, donc aussi disponible sur le Mac, sans fichier dans le dépôt) : manuel Lua 5.1, Ace3, LuaJIT, outils. Répartition avec le skill : voir `CLAUDE.md` (Workflow, « Documentation sources »)

## 3. Fonctionnalités livrées (1.0.0)

Fenêtre de configuration (`/nxp`) :
- **Layouts** : créer, activer, renommer, dupliquer, exporter, supprimer.
- **Panneaux** : liste par dossiers (recherche, clic droit), éditeur à 6 onglets appliqué en direct :
  Général, Fond, Bordure, Texte, Affichage, Scripts.
  - « Nouveau panneau » : panneau vide ou un des 6 modèles (bandeau d'infos, cadre de barres, fond de discussion, lueur de combat, cadre discret, barre de cible).
  - Fond : navigateur de textures en vignettes + images Blizzard (atlas), couleur automatique (classe, faction, réaction de la cible).
  - Texte : variables `{zone}`, `{time}`, `{fps}`, `{latency}`, `{gold}`, `{currency:ID}`, `{item:ID}`… ; insertion d'icônes (liste rapide ou toutes les icônes du jeu) et de monnaies.
  - Affichage : conditions sans script (combat, groupe, lieu, monture, cible, mascottes, conditions de macro), opacités (normale, combat, survol) et fondu.
  - Scripts : brouillon, « Vérifier » (ligne de l'erreur), dernière erreur à l'exécution.
  - Export d'un panneau ou d'un dossier, à coller dans un autre layout.
- **Bibliothèque** : fonds et bordures personnels par chemin de fichier.
- **Import / Export** : chaînes `!NXP1!` (layout complet ou panneaux), anciennes chaînes kgPanels via le module d'import, avertissement et import sans scripts.
- **Profils** : profil par classe ou faction, profil des nouveaux personnages, layout par défaut, **layout par spécialisation** (Retail : spécialisations ; Forever : talents principaux / secondaires).
- **Réglages** : apparence (styles Atelier / Encre / Nuit, couleur d'accent), minicarte, échelle, mode édition.

Mode édition (`/nxp edit`) : déplacement fluide, redimensionnement, grille (aimant, désactivée par défaut), aimantation aux panneaux et à l'écran avec repères, flèches, Ctrl+Z, sélection multiple (Ctrl+clic), alignement, sortie automatique en combat.

API : `nxPanels.GetPanelFrame`, `ActivateLayout`, `GetActiveLayout`, `RegisterMedia` (packs de médias).

Langues : enUS, frFR, zhCN, zhTW, et depuis `release/1.0.1` deDE, esES (sert aussi à esMX), itIT, ptBR, ruRU, koKR (mêmes clés et mêmes `%s` / `%d` partout, vérifié par les tests). Toutes les traductions sauf le français sont à faire relire par des joueurs natifs.

## 4. Décisions prises (ne pas les rediscuter sans raison)

| Décision | Raison |
|---|---|
| Nom **nxPanels**, licence **Tous droits réservés** (depuis le 2026-09-29, comme EllesmereUI ; les versions déjà publiées restent en GPL, les librairies gardent leur licence), crédit « Origins » à kgPanels / eePanels dans le README | Choix du mainteneur |
| Aucune mention de kgPanels dans `nxPanels/` et `nxPanels_Options/` | Tout l'héritage vit dans `nxPanels_Import` |
| **Layout par spécialisation** au lieu de profils par spécialisation ; LibDualSpec retirée | Choix du mainteneur : les spés choisissent un layout, les profils servent par classe / faction |
| Anciennes librairies de config (AceGUI, AceConfig, AceDBOptions) retirées | Remplacées par la fenêtre maison |
| LibSerialize **v1.2.3 officielle**, sans patch | Le client Forever lève une erreur sur toute division par zéro ; notre correctif a été intégré par l'auteur dans la v1.2.3 (2026-10-23) |
| Fichiers de la bibliothèque transmis à LibSharedMedia **seulement s'ils sont connus du jeu** (`Media:Share`) | Les versions récentes de LibSharedMedia signalent un fichier inconnu par une erreur Lua ; un fichier inconnu reste utilisable dans nxPanels (`Media:Fetch` lit la bibliothèque) |
| Un panneau sans condition d'affichage n'est réaffiché par le moteur que s'il l'a lui-même caché | Sinon un `self:Hide()` de script était annulé à chaque événement (issue #16) |
| Bordures : coordonnées exactes du `BackdropTemplate` de Blizzard | Rendu identique au pixel près à kgPanels (issue #16) |
| Import : une frame du jeu passe avant un panneau du même nom, jamais d'auto-référence | Même ordre que kgPanels (panneau « Minimap » ancré à `Minimap`, issue #16) |
| Une copie de panneau garde la position exacte | Comme kgPanels (issue #17) |
| Pas de choix de dossier par fenêtre Windows | Impossible pour un addon (aucun accès au disque) : remplacé par le collage de chemins (« Copier en tant que chemin d'accès ») |
| Sélecteur de frame à la souris **retiré**, pas de retour prévu | Frames protégées depuis Midnight (« secret values ») et trop coûteux sur une grosse interface. Remplacé en 1.2.0 par la saisie directe du nom (+ `/fstack`), avec un voyant |
| Nom de frame tapé : une frame du jeu passe avant un panneau du même nom ; un nom inconnu reste un nom de frame (le panneau attend) ; seul Entrée valide | Même ordre que l'import ; un nom à moitié tapé n'est jamais appliqué |
| Galerie de modèles dans le menu « Nouveau panneau » | Plus logique que dans Import / Export (retour du mainteneur) |
| Style par défaut **Atelier + or** | Préféré par le mainteneur |
| Grille du mode édition = aimant, désactivée par défaut | Les déplacements saccadaient |
| Les cadres de panneaux recyclés sont nettoyés des valeurs posées par les scripts | Bug corrigé : `self.xxx` suivait le cadre vers un autre panneau |

## 5. Migration kgPanels_Reloaded → nxPanels (À NE PAS CASSER)

C'est le point le plus sensible du projet : les joueurs actuels de kgPanels Reloaded doivent retrouver leurs layouts sans rien faire.

Fonctionnement :
1. Un addon ne peut lire que **son propre** fichier de sauvegarde, nommé d'après son dossier. Le paquet livre donc un dossier **`kgPanels_Reloaded`** (le « pont ») : chargé à la demande, il déclare `## SavedVariables: kgPanelsDB` et ne contient aucune fonction.
2. Au premier démarrage de nxPanels (aucun layout et pas de `global.migration`), `nxPanels_Import` charge le pont, lit `kgPanelsDB` et convertit : layouts, dossiers, médias personnels, profils (noms, personnages, layout actif, panneaux masqués). Les anciens réglages de profil par spécialisation deviennent des layouts par spécialisation pour le personnage qui fait l'import.
3. Les données d'origine ne sont **jamais modifiées**. L'import est noté dans `global.migration` pour ne pas recommencer. Les anciens addons sont ensuite désactivés.
4. Avec le kgPanels **original** installé, ses données sont lues directement (sans le pont), puis une fenêtre propose de recharger l'interface.
5. `/nxp import` refait un import (en nouveaux layouts). Les anciennes chaînes d'export kgPanels sont lues dans Import / Export.

Invariants à garder :
- Le dossier du paquet doit s'appeler exactement `kgPanels_Reloaded` et son TOC garder `## SavedVariables: kgPanelsDB` et `## LoadOnDemand: 1`.
- Le dossier `kgPanelsConfig_Reloaded` doit rester (vide) : il remplace l'ancien module de config chez les joueurs.
- `.pkgmeta` doit continuer à livrer ces deux dossiers (`move-folders`).
- Ne jamais écrire dans `kgPanelsDB`.
- Tests à faire passer avant toute publication : scénarios `migrate`, `original`, `forever`, `zhcn`, et `real` avec `NXP_REAL_SV=.local/kgPanels_Reloaded.lua` (copie privée des vraies données, jamais commitée).
- Tests à faire passer aussi : `handinstall` (ancien kgPanels Reloaded complet chargé à côté de nxPanels : import, puis proposition de recharger).
- Appli CurseForge : le lien entre versions est le projet (1444518), pas les noms de dossiers. À la mise à jour, elle supprime les dossiers de l'ancien fichier et extrait ceux du nouveau ; `WTF` n'est pas touché. Un fichier **alpha** ne va qu'aux joueurs abonnés aux alphas : la migration de tous aura lieu au premier fichier « release ». Protocole de test (phases A, B, C) : `docs/publication/PUBLICATION.md` section 3.
- Vérifié le 2026-09-28 : après la migration faite en jeu, le contenu de `kgPanelsDB` dans `WTF` est identique à la copie `.local/` (fichier réécrit par le jeu, jamais modifié par nxPanels).
- Ancienne v0.4.0 sauvegardée dans `_retail_\Interface\AddOns-backup-kgPanels\20260927-135414\` (sert au test de mise à jour).

## 6. Tests en jeu (validation du mainteneur)

| # | Point | Retail | Forever |
|---|---|---|---|
| 1 | Démarrage sans erreur | ✅ | ✅ |
| 2 | Styles et couleur d'accent | ✅ (Atelier + or) | — |
| 3 | Chaîne d'import visible | ✅ | ✅ (export corrigé) |
| 4 | Navigateur de textures / atlas (72 images) | ✅ | ✅ |
| 5 | Couleurs classe / réaction | ✅ | — |
| 6 | Sélecteur à l'écran | retiré | retiré |
| 7 | Variables de texte | ✅ | — |
| 8 | Conditions d'affichage (combat) | ✅ | ✅ |
| 9 | Vérification de script | ✅ | — |
| 10-12 | Mode édition fluide, multi-sélection, panneaux masqués visibles | ✅ | — |
| 13 | Layout par spécialisation | ✅ | ⏳ talents pas encore débloqués (niveau 10) |
| 14 | Modèles | ✅ | — |
| 15 | Export / import d'un panneau | ✅ | — |
| 17-18 | Icônes du jeu, monnaies, polices des listes | ✅ | — |
| 19 | `{gold}` en icônes or / argent / cuivre, à la taille du texte (correctif de l'audit) | ✅ 2026-10-25 | ⏳ (TBC Anniversary ✅ 2026-10-25) |
| 20 | Spécialisation lue via `C_SpecializationInfo` (`{spec}` = « Maître brasseur ») | ✅ 2026-10-25 | ⏳ talents principaux / secondaires (TBC Anniversary : « Talents principaux » ✅) |

Reste à tester : layout par spécialisation sur Forever (talents principaux / secondaires) quand le personnage aura les talents ; points 19 et 20 sur les trois clients (détails section 7 ter).

## 7. Suite prévue

**Publication faite le 2026-09-29** : phases A, B et C réussies, `1.0.0-alpha.2` puis **`1.0.0` en release** (tous les joueurs de kgPanels Reloaded reçoivent la mise à jour par l'appli CurseForge).

À faire :
1. ~~CurseForge : `1.0.0` approuvé, `1.0.0-alpha.2` archivé, description sans « Alpha »~~ ✅ 2026-09-29.
2. Surveiller les premiers retours (commentaires CurseForge, issues GitHub) : c'est la première fois que la migration tourne sur des données d'autres joueurs.
3. ~~GitHub : image sociale, lien CurseForge et topics~~ ✅ 2026-09-29.
4. Anciens critères v1.0 restants : relecture des traductions zhCN / zhTW par un joueur natif ; layout par groupe de talents à tester en jeu sur Forever.
5. Tests en jeu en attente : première installation sur le Mac (Retail, sans données kgPanels).
6. Backlog (`docs/ROADMAP.md`) : masques (coins arrondis), plusieurs calques, ombres, coloration du code des scripts, layout par résolution d'écran.

Installation locale du PC de jeu : Retail = dossiers installés par l'appli CurseForge (`1.0.0-alpha.2`, l'appli propose `1.0.0`) avec les données nxPanels d'avant les tests ; Forever = copie de travail (`deploy.sh`). Copies des données des tests : `SavedVariables/nxPanels.lua.phaseB` / `.phaseC`, sauvegardes complètes dans `Interface/AddOns-backup-kgPanels/phaseB-*`. Pour une version suivante : même procédure (tests, construction de test, `tools/update-test.sh` si la migration change, tag `x.y.z`).

## 7 bis. Version 1.1.0 (publiée le 2026-10-23) : retours des joueurs

Retours traités, dans l'ordre chronologique (commentaires CurseForge et issues GitHub #16, #17) :

| Retour | Fait | Validé en jeu (Retail) |
|---|---|---|
| Liste des panneaux après suppression / renommage (ancien retour) | Vérifié + test | ✅ |
| Client zhCN (ancien retour) | Couvert par les tests | — |
| Panneau ancré à la Minimap après l'import (Cnas, #16) | Import corrigé + réparation au démarrage des layouts importés en 1.0.0 | — (pas de donnée concernée) |
| Script `self:Hide()` annulé (#16) | Corrigé (`Visibility.lua`) | ✅ |
| Bordures décalées d'1 px (#16) | Coordonnées du BackdropTemplate | ✅ (bordure de test) |
| Copie décalée de 20 px (#17) | Corrigé | — |
| kgPanels copié depuis BCC Anniversary (moosetraxftw) | Message quand kgPanels n'est pas chargé + solution par le pont | — |
| Bibliothèque introuvable (Shailay) | Entrées utilisables même refusées par LibSharedMedia, chemin Windows complet accepté, onglet « Ma bibliothèque » dans le navigateur, ajout de plusieurs fichiers par collage des chemins | ✅ |

Autres nouveautés : support **TBC Anniversary** (interfaces 20505, 20506 ; ✅ chargé en jeu), **7 langues** de plus, client et version du jeu dans le panneau latéral, fenêtre de bienvenue après l'import (une fois), icône et groupe des dossiers de pont, librairies à jour (LibSharedMedia r185, LibSerialize v1.2.3, LibDBIcon 57), avertissement des scripts sur deux lignes, `/nxp status` sans double point.

Fenêtre des nouveautés (`Core/News.lua`, cadre partagé avec la bienvenue dans `Core/Splash.lua`) : une fois au premier démarrage d'une nouvelle version (`global.newsSeen`), pas pour un nouveau joueur ni juste après un import, après la fenêtre de bienvenue si elle est ouverte ; case « Ne plus afficher » (`global.showNews`). Page « Nouveautés » dans le menu de gauche (après Mode édition) : bannière, réglage d'affichage au démarrage, notes de toutes les versions, la plus récente d'abord (`Pages/News.lua`). **À chaque nouvelle version** : ajouter ses notes dans `News.NOTES` et la clé `NEWS_x_y_z` dans les 10 langues (sinon pas de fenêtre).

Publication (2026-10-23) :
1. ~~Version 1.1.0~~ ✅ TOC, CHANGELOG, PR #18, tag `1.1.0`, release GitHub, fichier CurseForge.
2. ~~Tests de migration~~ ✅ `migrate`, `original`, `real` verts. Test de mise à jour (`tools/update-test.sh`) non refait.
3. Forever : **exception décidée par le mainteneur le 2026-10-23** à la règle « rien sur CurseForge sans test en jeu sur Retail et Forever » : la 1.1.0 est publiée après les tests Retail et TBC Anniversary seulement (bêta de Forever fermée). **Tests en jeu sur Forever à faire dès la réouverture (5 novembre)** ; correctif 1.1.2 si besoin.
4. ~~Réponses~~ ✅ CurseForge (Shailay, moosetraxftw, Cnas) et GitHub (#16, #17, Aur0r4). **Fermer #16 et #17 à la main quand Aur0r4 confirme** (la PR ne les ferme pas). Suggestions d'interface d'Aur0r4 (déplacement au pixel, barre de défilement déplaçable, saisie du nom de frame) : faites en 1.2.0, branche `feature/ui-aurora` (section 7 septies).
5. ~~Description CurseForge~~ ✅ résumé et description à jour (TBC Anniversary, 10 langues, bibliothèque).

Reste à faire :
0. ~~1.1.1~~ ✅ PR #20 fusionnée, tag `1.1.1` (tag simple, `1.1.0` était annoté), workflow vert, `nxPanels-1.1.1.zip` envoyé sur CurseForge avec 12.1.5. Reste : vérifier son approbation dans l'onglet Files.
1. Forever : tests en jeu le 5 novembre (point 3).
2. Import réel depuis TBC Anniversary : créer quelques panneaux avec kgPanels sur ce client, puis importer (le fichier peut aussi servir au scénario `real`).
3. Surveiller les commentaires CurseForge (32 le 2026-10-23, un nouveau après les réponses) et les issues GitHub.
4. ~~Supprimer les branches fusionnées~~ ✅ 2026-10-25 : 21 branches distantes et 16 locales supprimées (toutes contenues dans `main` ; les versions publiées restent sur leurs tags `1.0.0`, `1.1.0`, `1.1.1`).
5. Version **1.1.2** (correctifs de l'audit, section 7 ter, fusionnés ; nouvelles variables `{specicon}` et `{talents}`, branche `feature/spec-icon`) : `CHANGELOG.md` (« Retail: layouts per specialization and the {gold} variable no longer depend on deprecated game functions »), fenêtre des nouveautés (notes dans `News.NOTES` + clé `NEWS_1_1_2` dans les 10 langues, ou décider qu'une version de correction n'en a pas). Idéalement regroupée avec les correctifs des tests Forever du 5 novembre. Rien sur CurseForge avant les tests en jeu.
6. Relecture des traductions par des joueurs natifs (toutes sauf le français).

## 7 ter. Audit de l'API (2026-10-25, branche `feature/api-audit`)

Même audit fait le même jour sur le Mac (sur `main` = `1.1.1`, sans modification) puis refait sur le PC : mêmes conclusions. Audit avec le skill `wow-addon-dev` (`wowapi.py audit` sur les 3 addons, `changes` depuis 12.1.0.69933) contre live **12.1.5.70575**, Forever **1.60.1.70532** et TBC Anniversary **2.5.6.70006**. Les interfaces du TOC (120105, 16001, 20506) sont à jour : pas de changement d'Interface.

| Point | Verdict | Fait |
|---|---|---|
| API supprimées / inconnues, événements inconnus | Aucun sur les 3 clients | — |
| `{gold}` : `GetCoinTextureString` (`Engine/TextVars.lua`) | **Vrai problème** : le nom global n'a plus d'alias dans FrameXML sur Retail et Forever (seul TBC Anniversary le garde). `{gold}` affichait sans doute `123g` au lieu des pièces, sans erreur | `C_CurrencyInfo.GetCoinTextureString(money, 0)` d'abord (hauteur 0 = taille du texte, comme les autres icônes ; la doc donne 14 par défaut), ancien nom en secours. La passation du Mac disait l'ancien nom encore présent sur Forever : faux, aucun alias dans le FrameXML de Forever 1.60.1.70532 |
| `GetSpecializationInfo` (`Core/Specs.lua`) | **Vrai problème latent** : appel protégé sans préférence pour `C_`, ne marche que par l'alias `Blizzard_DeprecatedSpecialization`, chargé seulement si le CVar `loadDeprecationFallbacks` est actif (vérifié dans les sources 12.1.5) ; s'il disparaît, le layout par spécialisation s'arrête en silence | `C_SpecializationInfo.GetSpecializationInfo` d'abord (même fonction que l'alias, même appel avec le seul index) |
| `GetNumSpecializationsForClassID` (`Core/Specs.lua`) | Faux positif : le `C_` est déjà préféré | — |
| `UnitClass` / `UnitName` (valeurs secrètes) | Faux positifs : seulement `"player"`. Couleur de réaction : `UnitExists` / `UnitCanAttack` / `UnitIsFriend` sur `"target"` sans restriction en 12.1.5 | — |
| `C_ClassColor.GetClassColor` (12.1.5 : 2e argument optionnel `tintColor`) | Sans effet, appelé avec un seul argument | — |

Tests : mock sans les noms globaux (`GetSpecializationInfo` seulement dans `C_SpecializationInfo`, `GetCoinTextureString` seulement dans `C_CurrencyInfo`), vérifications de `{gold}` (fonction `C_` avec la hauteur 0, et ancien nom en secours) et de la spécialisation courante. `run-all.sh` vert, `real` vert.

À tester en jeu avant de fusionner (`/console scriptErrors 1` ou BugSack) :
- **Retail** : `/dump GetCoinTextureString` (attendu : `nil`, ce qui confirme le bug) ; un panneau avec `{gold}` affiche les pièces en icônes, à la taille du texte (essayer deux tailles de police) ; changer de spécialisation change le layout choisi ; `{spec}` affiche le nom de la spé ; `/reload` sans erreur.
- **Forever** (dès la réouverture du 5 novembre) : mêmes points pour `{gold}` ; layout par groupe de talents (principal / secondaire) ; `/reload`.
- **TBC Anniversary** : `{gold}` toujours en icônes ; changement de groupe de talents ; `/reload`.

Résultat (2026-10-25, captures du mainteneur) : Retail ✅ (`{gold}` = « 257475 or 79 argent 49 cuivre » en icônes, `{spec}` = « Maître brasseur », pas d'erreur) ; TBC Anniversary ✅ (`{gold}` en icônes, « Talents principaux ») ; Forever ⏳ 5 novembre. Fusion dans `main` validée par le mainteneur ; la publication 1.1.2 attend le test Forever.

## 7 quater. Outils de développement (2026-10-25, branche `feature/dev-tooling`)

But : des contrôles automatiques, les mêmes sur le Mac, le PC et GitHub, et une reprise d'une machine à l'autre par `git pull` seulement.

| Élément | Rôle |
|---|---|
| `tools/lint.sh` | lua-language-server avec `.luarc.json` : Lua 5.1 seulement, API WoW (annotations de Ketho, dans `~/.cache/wow-addon-dev`, le même dossier que le skill ; téléchargées si absentes, `--update` pour les rafraîchir), `Libs/` ignoré. Repère les fautes de frappe dans les fonctions WoW, les mauvais arguments, les fonctions dépréciées et la syntaxe 5.2+ (`goto`, `//`). Premier passage : 50 remarques, toutes du bruit ou des secours voulus, marqués ligne par ligne (`---@diagnostic disable-next-line`) ou déclarés dans `diagnostics.globals` |
| `tools/tests/run-all.sh` | Trouve LuaJIT tout seul, lance le contrôle statique puis tous les scénarios |
| `.github/workflows/tests.yml` | À chaque push et PR : syntaxe, contrôle statique, scénarios (droits en lecture seule) |
| `.github/actions/setup-lua` | Installe LuaJIT et lua-language-server (version figée, empreinte SHA-256 vérifiée) pour les tests et la publication |
| `.github/dependabot.yml` | Une PR par mois pour mettre à jour les actions GitHub, figées par commit (packager BigWigs v2.6.1, checkout v4.4.0, upload-artifact v4.6.2) |
| `CLAUDE.md` | Règles : fin de session = suivi + commit + push de la branche ; section « Two computers » (installation par machine) |

Reste à faire :
1. ~~Vérifier la publication~~ ✅ 2026-10-25 : Tests verts sur GitHub (empreinte de lua-language-server OK, lint sans remarque, tous les scénarios) et construction de test du workflow Release sur la branche (run 40194588046 : zip construit, rien envoyé).
2. ~~Check « Tests » obligatoire~~ ✅ 2026-10-25 (accord du mainteneur) : ruleset « Protect main » = pas de suppression, pas de réécriture, PR obligatoire, et check `offline-tests` (workflow Tests) vert obligatoire pour fusionner. Pas de contournement possible.
3. ~~Mac : `brew install lua-language-server`~~ ✅ 2026-10-25 (installé par le mainteneur). Plugin `wow` mis à jour sur le PC en `8665677` (correctif Windows, plus besoin de `PYTHONIOENCODING`) via `~/.local/bin/claude.exe plugin update wow@willoli7-skills`.

## 7 quinquies. Variables `{specicon}` et `{talents}` (2026-10-25, branche `feature/spec-icon`)

Demandes du mainteneur : l'icône de la spécialisation, puis le nom des talents actifs. `Specs:CurrentTalents()` (nom et icône) : Retail = icône de la spé active (`C_SpecializationInfo.GetSpecializationInfo`, 4e valeur) ; WoW Forever et TBC Anniversary = icône de l'arbre de talents qui a le plus de points dans le groupe actif (même fonction, avec `groupIndex`, comme le module de compatibilité de Blizzard), rien sans points. Rendu `|T<icône>:0|t` (taille du texte), à combiner : `{specicon} {spec}`. `{talents}` = nom de l'arbre avec le plus de points (Retail : nom de la spé, comme `{spec}` ; sur Classic, `{spec}` reste le groupe « Talents principaux / secondaires »). Ajoutées à « Insérer une variable » (clés `VAR_SPECICON` et `VAR_TALENTS` dans les 10 langues). Tests : Retail, arbre avec le plus de points, aucun point.

Tests en jeu : `{specicon}` ✅ Retail et TBC Anniversary (2026-10-25). `{talents}` fusionné sans test en jeu (même calcul que `{specicon}`, accord du mainteneur) : **à vérifier avec le test Forever du 5 novembre, avant la publication 1.1.2**, aussi sur TBC Anniversary et Retail.

## 7 sexies. Revue du code (2026-10-25, branche `feature/code-review`)

Rapport complet : `docs/REVUE-CODE.md` (vrais problèmes, faux positifs écartés, remarques sur les outils). Aucun problème critique ; migration et `kgPanelsDB` intacts. Points 5 et 8 : d'abord annulés (c'était le comportement de kgPanels Reloaded v0.4.0), puis **refaits par choix du mainteneur** (2026-10-25) : le fonctionnement logique passe avant la copie de kgPanels, sans conversion des données ; on attend la réaction des joueurs (Aur0r4, issue #16). Un commit par correctif, chacun avec sa vérification dans `tools/tests/run.lua` (le test échoue sans le correctif) ; `run-all.sh` vert à chaque commit, `real` vert.

| # | Correctif | Fichiers |
|---|---|---|
| 1 | Le minuteur des nouvelles tentatives (panneau qui attend sa frame) peut repartir après son 60e essai | `Engine/Layouts.lua` |
| 2 | Un cadre où les scripts ont créé des textures ou des frames n'est plus réutilisé pour un autre panneau ; déplaçable / glisser / limité à l'écran / désaturation remis à zéro | `Render/Panel.lua` |
| 3 | `/nxp layout <nom>` avec les panneaux désactivés : plus d'erreur Lua. Les tests refusent maintenant `nil` pour `%s`, comme Lua 5.1 | `Core/Commands.lua`, `tools/tests/run.lua` |
| 4 | Chaîne d'import abîmée ou piégée : valeurs du mauvais type ignorées (valeurs par défaut), plus d'erreur ni de layout vide | `Core/Share.lua` |
| 5 | Taille en % = part du parent à l'écran, quelle que soit l'échelle (aussi en mode édition). **Change l'affichage** des panneaux en % avec une échelle ≠ 1 (aucun dans les vraies données) ; kgPanels appliquait l'échelle par-dessus | `Render/Panel.lua`, `EditMode/EditMode.lua` |
| 6 | Une erreur dans un gestionnaire d'événement n'empêche plus les suivants | `Core/Init.lua` |
| 7 | Import : ancienne ancre écrite `panel:...` sans erreur | `nxPanels_Import/Convert.lua` |
| 8 | Fond répété : suit le style et l'opacité comme les autres fonds. **Change l'affichage** des fonds répétés en style « Aucun » / « Dégradé » ou avec une couleur plus opaque que l'opacité (aucun dans les vraies données) | `Render/Panel.lua` |
| + | Nouveauté : **sens de répétition** (les deux, horizontal, vertical), importé de kgPanels (`horz_tile` / `vert_tile`) ; rotation, miroirs et coordonnées masqués pendant la répétition. **Schéma 4** (valeur ajoutée par `NormalizeLayout`). Clés `TILE_DIRECTION`, `TILE_DIR_*` dans les 10 langues | `Render/Panel.lua`, `Pages/Panels.lua`, `Convert.lua`, `Locales/` |

Résultats en jeu, Retail, 2026-10-25 (captures du mainteneur) : démarrage sans erreur Lua ; texture créée par un script ✅ (un seul rectangle, sur le bon panneau, après changement de layout et `/reload`) ; taille en % avec l'échelle ✅ et redimensionnement à la souris ✅ (le mainteneur n'aime pas beaucoup le %) ; `/nxp off` / `layout Test` / `on` ✅. Deux défauts d'ergonomie trouvés, corrigés le même jour :
- passer une taille de px à % gardait le nombre (350 px → 350 %, panneau plus grand que l'écran) : la valeur est maintenant convertie pour garder la taille à l'écran (`setUnit`, `Pages/Panels.lua`) ;
- avec une image Blizzard (atlas « QuestBG-Horde »), « Répéter la texture » ne faisait rien (un atlas ne se répète pas) mais masquait la rotation : options de répétition masquées et phrase d'explication (`TILE_ATLAS`, 10 langues).

Deuxième passage en jeu (Retail, 2026-10-25) : répétition « Horizontal seulement » ✅, atlas sans option de répétition ✅ mais phrase tronquée ; conversion px → % faite mais la valeur « sautait » : les curseurs de taille avançaient par pas de 1 et affichaient des entiers (7,98 % → « 8 », puis 8 dès la validation ; plus de 40 px par pas sur l'écran très large du mainteneur). Corrigé : en %, pas de 0,01 et décimales affichées (`SliderRow` accepte un pas variable) ; phrases d'explication sur deux lignes.

Troisième passage en jeu (Retail, 2026-10-25) : conversion px ↔ % avec décimales ✅ (« Details - Gauche ») ; phrase de l'atlas lisible sur deux lignes ✅. Reste : démarrage sans erreur sur TBC Anniversary, puis PR.

À refaire en jeu après réinstallation : changer l'unité d'un panneau en px vers % puis vers px (même taille à l'écran) ; fond en atlas (pas d'option de répétition, phrase affichée) ; fond en fichier (« Répéter » avec « Horizontal seulement » / « Vertical seulement » : le motif ne se répète que dans un sens) ; TBC Anniversary : démarrage sans erreur.

Tests en jeu à faire avant de fusionner (`/console scriptErrors 1` ou BugSack), sur Retail, Forever (dès le 5 novembre) et TBC Anniversary :
1. `/reload` sans erreur ; `/nxp status`.
2. Point 1 : panneau ancré à une frame qui n'existe pas encore (ex. `Autre frame…` → `DetailsBaseFrame1` avant d'ouvrir Details, ou un nom inventé), attendre plus d'une minute, changer son ancrage vers une autre frame absente puis la créer (ouvrir l'addon) : il doit apparaître dans la seconde.
3. Point 2 : script `LOAD` `self.t = self:CreateTexture() self.t:SetAllPoints() self.t:SetColorTexture(1,0,0,0.5)` sur un panneau ; changer de layout puis revenir, ou changer de spé : aucun carré rouge sur un autre panneau, un seul sur le bon.
4. Point 3 : `/nxp off`, `/nxp layout <nom>` (message sans erreur), `/nxp on`.
5. Point 4 : importer une chaîne `!NXP1!` normale (exportée d'un layout) : identique à avant.
6. Point 5 : panneau 100 % de largeur, échelle 0,5 puis 2 : toujours toute la largeur de l'écran ; bordure et texte suivent l'échelle ; le redimensionner en % dans le mode édition suit la souris.
7. Point 8 : fond répété en style « Aucun » (texture sans teinte), « Uni », « Dégradé », opacité 0,5.
8. Sens de répétition : « Horizontal seulement » puis « Vertical seulement », avec une taille de motif à 0 puis à 32 ; rotation et miroirs masqués quand « Répéter » est coché.
9. Démarrage : aucune erreur Lua au lancement sur les 3 clients (avant la 1.1.2, choix du mainteneur).
10. Migration : scénarios `migrate`, `original`, `real` verts (fait le 2026-10-25) ; import changé seulement par le point 7 et le sens de répétition.

À faire pour la 1.1.2 : `CHANGELOG.md` (section « Unreleased » prête), version dans les TOC, notes de la fenêtre des nouveautés (`News.NOTES` + clé `NEWS_1_1_2` dans les 10 langues, ou décider de ne pas en avoir) ; surveiller la réaction d'Aur0r4 aux points 5 et 8.

Incident 2026-10-25 : les brouillons `docs/publication/REDDIT.md` et `REPLIES-1.1.0.md` (non suivis, à garder hors du dépôt) avaient été ajoutés par erreur à un commit poussé ; l'historique de `feature/code-review` a été réécrit pour les retirer (force-push accepté par le mainteneur). Les fichiers restent sur le disque, non suivis. Ne jamais faire `git add docs` : ajouter les fichiers un par un.

## 7 septies. Version 1.2.0 : suggestions d'interface d'Aur0r4 (2026-10-26, branche `feature/ui-aurora`)

Fin de l'issue #16 (Aur0r4, 126 panneaux, rendu au pixel près). Branche partie de `main` après la PR #28. Un commit par idée, chacun avec ses vérifications dans `tools/tests/run.lua` (vérifiées en cassant le code : les tests échouent). `run-all.sh` vert à chaque commit, `real` vert, `wowapi.py audit` de `nxPanels_Options` : 0 API supprimée / dépréciée, 0 événement inconnu (live 12.1.5.70575, forever, classic_anniversary).

| # | Fonction | Fichiers |
|---|---|---|
| 1 | **Nom de frame tapé** : « Ancré à » et « Parent » ont un champ (validé par Entrée ; Échap ou perte du focus remettent la valeur enregistrée) et la liste à côté (écran, autres panneaux). Voyant vert si `Anchors:Resolve` trouve la frame, orange sinon (le panneau attend). Le champ affiche « Écran », le nom du panneau ou le nom de la frame. « Autre frame… » et sa fenêtre supprimés (clés `OTHER_FRAME`, `PROMPT_FRAME_NAME` retirées ; `FRAME_NAME_HINT`, `FRAME_FOUND`, `FRAME_MISSING` ajoutées). Pas d'autocomplétion | nouveau widget `W.ComboRow` (`UI/Dropdown.lua`), `Pages/Panels.lua` |
| 2 | **Déplacement au pixel** : 4 boutons flèches dans la barre du mode édition (texture `Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up` tournée par ses coordonnées, présente sur les 3 clients) → `EditMode:Nudge` (1 px, Maj = `bigStep`, Ctrl+Z annule), infobulle qui rappelle les flèches du clavier ; visibles avec un panneau sélectionné, à gauche de « Réglages du panneau » ou des boutons d'alignement. Boutons - / + à côté de X / Y dans l'éditeur (option `stepper` de `W.SliderRow`, Maj = `bigStep` du mode édition). Clés `NUDGE_*`, `STEP_MINUS`, `STEP_PLUS` | `EditMode/EditMode.lua`, `UI/Widgets.lua`, `Pages/Panels.lua` |
| 3 | **Barres de défilement déplaçables** (`W.Scroll` et `W.TextArea`, construction commune `scrollBar`) : poignée saisie à la souris (zone de 14 px pour un trait de 4 px, `SetHitRectInsets`), plus large (8 px) et couleur d'accent au survol et pendant le glissement ; clic sur la piste = une page ; curseur converti avec l'échelle effective de la barre ; arrêt si le bouton est relâché hors du jeu (`IsMouseButtonDown`, utilisé aussi par Blizzard sur TBC Anniversary). Tout défilement passe par `scroll:ScrollTo` puis `scroll.onScroll` : la grille d'icônes du navigateur (`FillIcons`) suit pendant le glissement. 19 zones de défilement vérifiées (pages, listes, menus, zones de texte) | `UI/Widgets.lua`, `UI/Browser.lua` |
| + | Version 1.2.0 dans les 5 TOC, `CHANGELOG.md` (section 1.2.0 ; la section des correctifs devient « 1.1.2 — Unreleased »), notes `NEWS_1_2_0` dans les 10 langues (test : notes de chaque version traduites) | |

Remarque : si cette branche est fusionnée avant la publication de la 1.1.2, la 1.2.0 contiendra aussi ses correctifs (décider alors : publier 1.1.2 d'abord, ou tout regrouper en 1.2.0 et fusionner les deux sections du CHANGELOG).

Tests en jeu à faire (`/console scriptErrors 1` ou BugSack), Retail d'abord puis TBC Anniversary et Forever (5 novembre) :
1. `/reload` sans erreur ; la fenêtre des nouveautés montre 1.2.0 une fois.
2. Éditeur, onglet Général : taper un nom inventé dans « Ancré à » puis Entrée → voyant orange, panneau masqué ; taper `UIParent` ou choisir « Écran » dans la liste → vert. Taper un nom qui existe (`Minimap`, `PlayerFrame`) → vert, panneau attaché. Taper le nom d'un autre panneau → attaché au panneau. Taper sans Entrée puis cliquer ailleurs → rien ne change. Même chose pour « Parent ».
3. Cas des raid frames (#17) : dupliquer un panneau ancré à `CompactRaidFrame1` (en groupe), remplacer le 1 par 2 → même position sur la deuxième frame.
4. Voyant : survol → infobulle ; ouvrir l'addon attendu (Details) → le voyant passe au vert à la prochaine actualisation de l'éditeur.
5. Mode édition : sélectionner un panneau → 4 flèches à droite de l'info ; clic = 1 px, Maj+clic = grand pas ; Ctrl+Z annule ; infobulle ; sélection multiple (Ctrl+clic) : flèches à gauche de « Aligner », le groupe bouge ensemble ; flèches cachées sans sélection. Vérifier que les flèches pointent dans le bon sens sur les 3 clients.
6. Éditeur : - / + à côté des décalages horizontal et vertical (1 px, Maj = grand pas), ligne non coupée (libellés longs en allemand).
7. Barres de défilement : liste des panneaux, éditeur (page longue), page Layouts, Bibliothèque, menus déroulants longs (polices), zones de texte (texte, scripts, import / export) : saisir la poignée (aussi un peu à gauche du trait), glisser, relâcher hors de la barre ; clic sur la piste au-dessus / au-dessous = une page ; la poignée s'élargit au survol. Avec une autre échelle d'interface : la poignée suit exactement la souris.
8. Navigateur d'icônes (« Insérer une icône » → toutes les icônes) : glisser la barre → la grille se redessine pendant le glissement, sans trou.
9. Aucune erreur Lua au démarrage sur les 3 clients.

À faire ensuite : tests en jeu, puis PR `feature/ui-aurora` (accord du mainteneur), réponse à Aur0r4 sur l'issue #16.

## 8. Reprendre le travail

Dans une nouvelle conversation, commencer par :
> Lis `CLAUDE.md`, `docs/SUIVI.md`, `docs/ROADMAP.md` et `docs/publication/PUBLICATION.md` du dépôt nxPanels (`D:\_CLAUDE\WoW - nxPanels`), puis vérifie l'état avec `git status` et `git log --oneline -10`.

Reprise sur un autre ordinateur (Mac) : tout le travail est sur GitHub (`git pull`), dépôt cloné dans `~/Desktop/nxPanels`. Ne sont **pas** dans le dépôt : `.local/kgPanels_Reloaded.lua` (vraies données, scénario `real` impossible ailleurs que sur le PC de jeu), l'installation du jeu (`tools/deploy.sh`, test de mise à jour phase B) et les chemins d'outils du PC. Sur Mac (Homebrew installé, avec `luajit`, `librsvg`, `imagemagick`) : `brew install lua-language-server` une fois (sinon le contrôle statique est sauté en local, mais GitHub le fait), puis `bash tools/tests/run-all.sh`. Le dossier `img/` (brouillons du logo) est ignoré par git.
