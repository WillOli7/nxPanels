# nxPanels — Fichier de suivi

Document de reprise : l'état exact du projet, pour continuer dans une nouvelle conversation sans rien réinventer.
À lire avec `CLAUDE.md` (règles du projet) et `docs/ROADMAP.md` (idées et backlog).
**Mettre ce fichier à jour à la fin de chaque session de travail.**

Dernière mise à jour : 2026-09-28

---

## 1. État actuel

| Élément | État |
|---|---|
| Version | `1.0.0-alpha.2` (tous les TOC alignés) |
| Branche de travail | `feature/logo` (depuis `main`), poussée sur GitHub |
| Pull request | PR #1, #2 (workflow de release) et #3 (feuille de route) **fusionnées** dans `main` le 2026-09-28. PR `feature/logo` ouverte (logo, bannières, icône en jeu) |
| `main` | alpha.2 complète : moteur, fenêtre de configuration, mode édition, import, workflow de release |
| Logo | ✅ 2026-09-28 : version stylisée (ChatGPT) pour GitHub / CurseForge dans `docs/media/`, version simplifiée (`docs/media/icon.svg` → `nxPanels/Media/icon.tga`) pour le jeu. Détails : `PUBLICATION.md` section 7 |
| Installé sur Mac | Retail (`/Applications/World of Warcraft/_retail_`, compte DARKICE7, aucune donnée kgPanels : test de première installation) via `WOW_DIR="/Applications/World of Warcraft" bash tools/deploy.sh retail`. Forever pas encore lancé sur ce Mac. Test en jeu à faire |
| Tests hors jeu | Tous verts : `bash tools/tests/run-all.sh <luajit>` (migrate, original, handinstall, empty, forever, zhcn, options ×4 langues) + `real` avec les vraies données |
| Installé en local | Oui, Retail (`_retail_`) et Forever (`_classic_beta_`) via `bash tools/deploy.sh all` |
| CurseForge | **Rien publié.** Projet existant à renommer : ID `1444518` (kgPanels_Reloaded, 1 095 téléchargements, licence « All Rights Reserved », v0.4.0 marquée 12.0.0 / 12.0.1). Slug `nxpanels` libre au 28/09 |
| Publication | Dossier prêt : `docs/publication/PUBLICATION.md` (étapes, test de mise à jour, message au modérateur, captures, brief du logo, GitHub) et `docs/publication/CURSEFORGE.md` (page CurseForge EN + FR / zhCN / zhTW). Workflow `.github/workflows/release.yml` (tag → release GitHub, CurseForge si secret `CF_API_KEY` ; lancement manuel = construction de test sans envoi) |
| Paquet (phase A) | ✅ 2026-09-28 : construction de test OK (run 36355822045). 5 dossiers, pont intact, TOC en 1.0.0-alpha.2, rien de `tools` / `docs` / `CLAUDE.md`. Versions détectées par le packager : 12.0.0 à 12.1.0 + Forever 1.60.1. Le zip se retélécharge depuis le run GitHub (artefact « nxPanels-package », 90 jours) |

## 2. Contenu du dépôt

| Dossier | Rôle |
|---|---|
| `nxPanels/` | Cœur : données (AceDB, schéma **3**), rendu, bordures, ancrages, scripts, conditions d'affichage, couleurs automatiques, variables de texte, spécialisations, partage, API, commandes, traductions |
| `nxPanels_Options/` | Fenêtre de configuration (chargée à la demande) + mode édition |
| `nxPanels_Import/` | Import des données kgPanels / kgPanels Reloaded (temporaire, voir section 5) |
| `kgPanels_Reloaded/` | **Pont de migration** : déclare `kgPanelsDB` pour que nxPanels puisse lire l'ancien fichier |
| `kgPanelsConfig_Reloaded/` | Dossier vide qui remplace l'ancien module de config |
| `tools/` | Tests hors jeu (`tests/`), `deploy.sh`, `check-libs.sh` |
| `docs/publication/` | Textes et procédure de la sortie publique (CurseForge, GitHub, logo) |

Outils locaux (hors PATH de Bash) :
- LuaJIT : `C:\Users\Muse\AppData\Local\Programs\LuaJIT\bin\luajit.exe`
- GitHub CLI : `"/c/Program Files/GitHub CLI/gh.exe"` (connecté en `WillOli7`)

## 3. Fonctionnalités livrées (alpha.2)

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

Langues : enUS, frFR, zhCN, zhTW (mêmes clés partout, vérifié par les tests). Traductions chinoises à faire relire par un joueur natif.

## 4. Décisions prises (ne pas les rediscuter sans raison)

| Décision | Raison |
|---|---|
| Nom **nxPanels**, licence **GPL-3.0-or-later**, crédit « Origins » à kgPanels / eePanels dans le README | Choix du mainteneur |
| Aucune mention de kgPanels dans `nxPanels/` et `nxPanels_Options/` | Tout l'héritage vit dans `nxPanels_Import` |
| **Layout par spécialisation** au lieu de profils par spécialisation ; LibDualSpec retirée | Choix du mainteneur : les spés choisissent un layout, les profils servent par classe / faction |
| Anciennes librairies de config (AceGUI, AceConfig, AceDBOptions) retirées | Remplacées par la fenêtre maison |
| **LibSerialize patchée** (lignes « nxPanels patch ») | Le client Forever lève une erreur sur toute division par zéro. Garder le patch à chaque mise à jour de la librairie |
| Sélecteur de frame à la souris **retiré** | Frames protégées depuis Midnight (« secret values ») et trop coûteux sur une grosse interface. Reste « Autre frame… » + `/fstack` |
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

Reste à tester : layout par spécialisation sur Forever (talents principaux / secondaires) quand le personnage aura les talents.

## 7. Suite prévue

1. Fait le 2026-09-28 : préparation de la publication validée par le mainteneur, commitée et poussée sur `feature/options-window` (PR #1, tests GitHub verts).
2. Suivre l'ordre des opérations de `docs/publication/PUBLICATION.md` section 1 : ~~fusion de la PR #1~~ ✅ → ~~construction de test (phase A)~~ ✅ → test de mise à jour local (phase B, sur le PC de jeu, avec le zip du run) → captures + ~~logo~~ ✅ → renommage CurseForge + message au modérateur → métadonnées GitHub → tag `1.0.0-alpha.2` → test avec l'appli CurseForge (phase C).
   - Le README référence 4 captures dans `docs/media/` : tant qu'elles manquent, la page GitHub affiche des images cassées.
   - Image sociale GitHub (Settings → Social preview) : `docs/media/social-preview.png`, à envoyer à la main. Bannière CurseForge : `docs/media/banner-curseforge.png`.
3. Faire relire les traductions zhCN / zhTW par un joueur natif.
4. Backlog restant (`docs/ROADMAP.md`) : masques (coins arrondis), plusieurs calques, ombres, coloration du code des scripts, layout par résolution d'écran.

## 8. Reprendre le travail

Dans une nouvelle conversation, commencer par :
> Lis `CLAUDE.md`, `docs/SUIVI.md`, `docs/ROADMAP.md` et `docs/publication/PUBLICATION.md` du dépôt nxPanels (`D:\_CLAUDE\WoW - nxPanels`), puis vérifie l'état avec `git status` et `git log --oneline -10`.

Reprise sur un autre ordinateur (Mac) : tout le travail est sur GitHub (`git pull`), dépôt cloné dans `~/Desktop/nxPanels`. Ne sont **pas** dans le dépôt : `.local/kgPanels_Reloaded.lua` (vraies données, scénario `real` impossible ailleurs que sur le PC de jeu), l'installation du jeu (`tools/deploy.sh`, test de mise à jour phase B) et les chemins d'outils du PC. Sur Mac (Homebrew installé, avec `luajit`, `librsvg`, `imagemagick`) : `bash tools/tests/run-all.sh luajit`. Le dossier `img/` (brouillons du logo) est ignoré par git.
