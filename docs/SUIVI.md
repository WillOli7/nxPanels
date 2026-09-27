# nxPanels — Fichier de suivi

Document de reprise : l'état exact du projet, pour continuer dans une nouvelle conversation sans rien réinventer.
À lire avec `CLAUDE.md` (règles du projet) et `docs/ROADMAP.md` (idées et backlog).
**Mettre ce fichier à jour à la fin de chaque session de travail.**

Dernière mise à jour : 2026-09-27

---

## 1. État actuel

| Élément | État |
|---|---|
| Version | `1.0.0-alpha.2` (tous les TOC alignés) |
| Branche de travail | `feature/options-window`, poussée sur GitHub |
| Pull request | https://github.com/WillOli7/nxPanels/pull/1 (`feature/options-window` → `main`), tests GitHub verts, à relire et fusionner par le mainteneur |
| `main` | Moteur alpha.1 + import ; ne contient pas encore la fenêtre de configuration |
| Tests hors jeu | Tous verts : `bash tools/tests/run-all.sh <luajit>` (migrate, original, empty, forever, zhcn, options ×4 langues) + `real` avec les vraies données |
| Installé en local | Oui, Retail (`_retail_`) et Forever (`_classic_beta_`) via `bash tools/deploy.sh all` |
| CurseForge | **Rien publié.** Projet existant à renommer : ID `1444518` (voir section 7) |

## 2. Contenu du dépôt

| Dossier | Rôle |
|---|---|
| `nxPanels/` | Cœur : données (AceDB, schéma **3**), rendu, bordures, ancrages, scripts, conditions d'affichage, couleurs automatiques, variables de texte, spécialisations, partage, API, commandes, traductions |
| `nxPanels_Options/` | Fenêtre de configuration (chargée à la demande) + mode édition |
| `nxPanels_Import/` | Import des données kgPanels / kgPanels Reloaded (temporaire, voir section 5) |
| `kgPanels_Reloaded/` | **Pont de migration** : déclare `kgPanelsDB` pour que nxPanels puisse lire l'ancien fichier |
| `kgPanelsConfig_Reloaded/` | Dossier vide qui remplace l'ancien module de config |
| `tools/` | Tests hors jeu (`tests/`), `deploy.sh`, `check-libs.sh` |

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
- Question ouverte : comment l'appli CurseForge gère un paquet dont les noms de dossiers changent (à tester avant la publication, voir section 7).

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

1. Relire et fusionner la pull request `feature/options-window` → `main`.
2. **CurseForge et GitHub** (nouvelle conversation, prompt prêt ci-dessous) :
   - renommer le projet CurseForge 1444518 en nxPanels et passer la modération ;
   - mettre à jour la page CurseForge et le README / la page GitHub (description, captures, langues prises en charge) ;
   - nouveau logo (à faire avec un générateur d'images) ;
   - vérifier que la mise à jour automatique ne casse pas la migration (section 5).
3. Faire relire les traductions zhCN / zhTW par un joueur natif.
4. Backlog restant (`docs/ROADMAP.md`) : masques (coins arrondis), plusieurs calques, ombres, coloration du code des scripts, layout par résolution d'écran.

## 8. Reprendre le travail

Dans une nouvelle conversation, commencer par :
> Lis `CLAUDE.md`, `docs/SUIVI.md` et `docs/ROADMAP.md` du dépôt nxPanels (`D:\_CLAUDE\WoW - nxPanels`), puis vérifie l'état avec `git status` et `git log --oneline -10`.
