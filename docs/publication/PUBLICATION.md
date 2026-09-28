# Publication de nxPanels (remplace kgPanels Reloaded)

Dossier de travail de la sortie publique. Rien n'est publié sans l'accord du mainteneur à chaque étape.
Textes prêts à coller : `CURSEFORGE.md` (page CurseForge, en anglais + résumés FR / zhCN / zhTW).

---

## 1. Ordre des opérations

| # | Étape | Qui | Publie quelque chose ? |
|---|---|---|---|
| 1 | Relire les fichiers de ce dossier, le README, le workflow `release.yml` | mainteneur | non |
| 2 | Commit + push sur `feature/options-window` (la PR #1 s'enrichit) | Claude, après accord | GitHub (branche) |
| 3 | Fusionner la PR #1 dans `main` (GitHub ne lance un workflow à la main que s'il existe sur `main`) | mainteneur | GitHub |
| 4 | Construction de test (Actions → Release → « Run workflow » sur `main`, aucun envoi), puis test de mise à jour local (section 3, phases A et B) | Claude + mainteneur | non |
| 5 | Captures d'écran (section 6) et logo (section 7) | mainteneur | non |
| 6 | Ajouter logo et captures dans `docs/media/` (le README les affiche) | Claude, après accord | GitHub |
| 7 | Renommer le projet CurseForge, coller la description, message au modérateur (sections 4 et 5) | mainteneur | CurseForge |
| 8 | Description, topics et image sociale du dépôt GitHub (section 8) | Claude, après accord | GitHub |
| 9 | Tag `1.0.0-alpha.2` sur `main` → release GitHub (pré-version) ; fichier CurseForge **alpha** seulement si le secret `CF_API_KEY` existe | Claude, après accord | GitHub (+ CurseForge) |
| 10 | Test réel avec l'appli CurseForge (section 3, phase C) | mainteneur | — |
| 11 | Plus tard : première version `release` (1.0.0) = migration de tous les joueurs | mainteneur | CurseForge |

## 2. Comment l'appli CurseForge gère le changement de noms de dossiers

**Le lien entre l'ancienne et la nouvelle version, c'est le projet (ID 1444518), pas les noms de dossiers.**

- L'appli garde, pour chaque addon installé, le projet et le fichier installés, avec la liste des dossiers (« modules ») que contenait ce fichier et leurs empreintes.
- À la mise à jour, elle télécharge le nouveau zip, **supprime les dossiers de l'ancien fichier** (`kgPanels_Reloaded`, `kgPanelsConfig_Reloaded`), puis **extrait tous les dossiers du nouveau** : les deux anciens noms reviennent sous forme de pont / dossier vide, et `nxPanels`, `nxPanels_Options`, `nxPanels_Import` sont ajoutés. Dans l'appli, l'addon apparaît ensuite sous le nouveau nom du projet.
- **Les données du joueur ne sont pas touchées** : elles sont dans `WTF\...\SavedVariables\kgPanels_Reloaded.lua`, que l'appli ne gère pas. Le pont (dossier `kgPanels_Reloaded`, `## SavedVariables: kgPanelsDB`) permet à nxPanels de relire ce fichier.
- Côté jeu : les nouveaux dossiers sont des addons nouveaux, **activés par défaut**. `kgPanels_Reloaded` était déjà activé ; s'il ne l'est pas, `nxPanels_Import` l'active pour le charger.
- WowUp et l'appli Wago suivent le même principe (suivi par projet CurseForge / Wago).

Points d'attention :
- **Type de fichier.** Par défaut l'appli ne propose que les fichiers **Release** (réglable par addon : Release / Beta / Alpha). Un fichier `1.0.0-alpha.2` (tag contenant « alpha » → fichier alpha) n'atteint donc **que les joueurs abonnés aux alphas**. La migration de tout le monde aura lieu au premier fichier « release ». C'est une sécurité pour la phase de test.
- **Versions de jeu.** L'appli ne propose un fichier que s'il est marqué pour la version du jeu installée. L'ancien fichier était marqué 12.0.0 / 12.0.1 ; le nouveau sera marqué d'après le TOC (Retail 12.x et Forever 1.60). À vérifier dans la console auteur après l'envoi ; corriger à la main si une version manque.
- **Installation à la main** (sans appli) : extraire le zip écrase le TOC de l'ancien `kgPanels_Reloaded` par celui du pont ; les anciens fichiers restés dans le dossier ne sont plus chargés (le TOC ne liste que `Bridge.lua`). Si l'ancien addon complet tourne encore à côté de nxPanels, l'import propose maintenant de recharger l'interface (scénario de test `handinstall`).
- Vérifié sur tes vraies données : après la migration faite en jeu le 27/09, le contenu de `kgPanelsDB` dans `WTF` est **identique** à la copie d'origine (`.local/`) — le fichier a été réécrit par le jeu (formatage), jamais modifié par nxPanels.

## 3. Protocole de test avant la mise en ligne

### Phase A — contenu du paquet (sans rien publier)
1. Après la fusion dans `main`, GitHub → Actions → **Release** → « Run workflow » (branche `main`). Ce mode lance les tests puis le packager avec `-d` : **aucun envoi**, le zip est joint au run (« nxPanels-package »).
2. Vérifier le zip : exactement 5 dossiers à la racine (`nxPanels`, `nxPanels_Options`, `nxPanels_Import`, `kgPanels_Reloaded`, `kgPanelsConfig_Reloaded`) ; pas de `tools`, `docs`, `CLAUDE.md`, `.local` ; TOC en `1.0.0-alpha.2` ; `kgPanels_Reloaded.toc` avec `## SavedVariables: kgPanelsDB` et `## LoadOnDemand: 1`.

### Phase B — mise à jour simulée sur Retail (ce que fait l'appli)
Jeu fermé.
1. **Sauvegarde** : copier `_retail_\WTF` en entier et les 5 dossiers actuels de `_retail_\Interface\AddOns` dans un dossier daté.
2. **Revenir à l'état d'un joueur actuel** :
   - supprimer `nxPanels`, `nxPanels_Options`, `nxPanels_Import`, `kgPanels_Reloaded`, `kgPanelsConfig_Reloaded` de `AddOns` ;
   - remettre l'ancienne v0.4.0 depuis `Interface\AddOns-backup-kgPanels\20260927-135414\` (dossiers `kgPanels_Reloaded` et `kgPanelsConfig_Reloaded`) ;
   - déplacer `WTF\Account\DARKICE7\SavedVariables\nxPanels.lua` (et `.bak`) dans la sauvegarde : nxPanels doit repartir de zéro.
3. Lancer le jeu (cocher « Charger les addons périmés » si besoin : la v0.4.0 ne déclare que 120000 / 120001) : vérifier que les panneaux de la v0.4.0 s'affichent. Quitter.
4. **Faire ce que fait l'appli** : supprimer `kgPanels_Reloaded` et `kgPanelsConfig_Reloaded`, extraire les 5 dossiers du zip de la phase A.
5. Lancer le jeu et vérifier :
   - message « 3 layout(s) et 33 panneau(x) importés depuis kgPanels_Reloaded » ;
   - panneaux identiques à l'étape 3, `/nxp status` sans erreur ;
   - liste des addons : kgPanels Reloaded (pont) et kgPanelsConfig Reloaded désactivés ;
   - `/reload`, puis un autre personnage (profil Horde / Alliance) : bon layout, pas de nouvel import ;
   - après déconnexion : contenu de `kgPanels_Reloaded.lua` inchangé (je peux le comparer avec `.local/`).
6. Remettre la sauvegarde si besoin (ou `bash tools/deploy.sh all`).

Script (jeu fermé) : `bash tools/update-test.sh prepare` (étapes 1-2), `update <zip>` (étape 4), `check` (données `kgPanelsDB` comparées à `.local/`), `restore` (étape 6).

### Phase C — vraie mise à jour par l'appli CurseForge (après l'étape 9)
1. Refaire les étapes B1-B2, puis dans l'appli CurseForge : installer « kgPanels_Reloaded » v0.4.0 (projet 1444518) pour qu'elle soit suivie par l'appli.
2. Clic droit sur l'addon → type de version **Alpha**. L'appli propose 1.0.0-alpha.2 → **Mettre à jour**.
3. Contrôler les dossiers (5, anciens fichiers supprimés) puis refaire la vérification B5.
4. En cas de problème : archiver le fichier alpha sur CurseForge (il disparaît des mises à jour proposées) et corriger.

WoW Forever : l'ancien addon n'existait pas pour Forever, il n'y a pas de migration par l'appli à tester ; le scénario `forever` hors jeu couvre l'import.

## 4. Renommer le projet CurseForge 1444518

Dans la console auteur (authors.curseforge.com → Projects → kgPanels_Reloaded) :

| Champ | Actuel | Nouveau |
|---|---|---|
| Nom | kgPanels_Reloaded | **nxPanels** |
| Slug (URL) | `kgpanels-reloaded` | **`nxpanels`** (libre au 28/09/2026). Si le champ est verrouillé, le demander dans le message au modérateur. |
| Résumé | … | voir l'en-tête de `CURSEFORGE.md` (moins de 250 caractères) |
| Catégorie principale | Artwork | **Artwork** |
| Autres catégories | HUDs | **HUDs** (éventuellement « Miscellaneous ») |
| Licence | All Rights Reserved | **GNU General Public License version 3 (GPLv3)** ; le « or later » est précisé dans le fichier `LICENSE` du paquet |
| Source | GitHub (ancien dépôt) | `https://github.com/WillOli7/nxPanels` |
| Issues | — | `https://github.com/WillOli7/nxPanels/issues` |
| Avatar | ancien | logo 400×400 minimum (section 7) |
| Description | ancienne | `CURSEFORGE.md`, éditeur en **Markdown** |

Versions de jeu : elles viennent de chaque fichier envoyé (le packager les lit dans le TOC : Retail 12.0.0 à 12.1.0 et WoW Forever 1.60.1). Les vérifier sur le fichier dans l'onglet Files.

Envoi automatique des fichiers : console auteur → **API tokens** → créer un jeton, puis GitHub → dépôt → Settings → Secrets and variables → Actions → nouveau secret **`CF_API_KEY`**. Sans ce secret, un tag ne crée que la release GitHub.

Modération : un changement de nom et de licence d'un projet déjà approuvé peut repasser en revue. Envoyer le message ci-dessous par le canal indiqué dans la console (commentaire de revue si le projet passe « Under review ») ou, sinon, par un ticket au support CurseForge (section auteurs). Faire le renommage **avant** l'envoi du premier fichier nxPanels, pour que le modérateur voie le projet cohérent.

## 5. Message au modérateur (anglais)

> Hello,
>
> I am the author of **kgPanels_Reloaded** (project ID **1444518**). I have renamed it to **nxPanels** and I would like to ask for your review of the change. It is the same project and the same author, continuing under a new name.
>
> **Why a new name.** kgPanels_Reloaded was an update of the old kgPanels addon. nxPanels is a **complete rewrite**: new engine, new saved data format, new configuration window and edit mode, full support for Simplified and Traditional Chinese clients, and support for both Retail 12.x and WoW Forever. It does not reuse any code of kgPanels or eePanels, so it deserves its own name, and it is now free software under **GPL-3.0-or-later** (the previous "All Rights Reserved" label no longer applies to this code).
>
> **Credit.** The description and the README credit **kgPanels by kagaro** and its predecessor **eePanels**, which inspired this project.
>
> **Why the same project.** Keeping project 1444518 lets the current users receive nxPanels as a normal update. Their layouts are then **imported automatically** on the first start; their old data is never modified.
>
> **About the folders in the package.** Besides `nxPanels`, `nxPanels_Options` and `nxPanels_Import`, the package contains two folders with the old names, `kgPanels_Reloaded` and `kgPanelsConfig_Reloaded`. They contain no features and no old code: WoW links saved data to the folder name, so the `kgPanels_Reloaded` folder only declares the old saved variable, which lets nxPanels read and import the user's existing layouts. The second one is an empty placeholder that replaces the old configuration folder. Both are explained on the project page.
>
> Could you also change the project slug from `kgpanels-reloaded` to `nxpanels`, if I cannot do it myself?
>
> Source code: https://github.com/WillOli7/nxPanels
>
> Thank you for your time!
> Adna

## 6. Captures d'écran à prévoir

Format : PNG ou JPG, **1920×1080** (interface à 100 %), sans nom de personnage / guilde / serveur visibles (ou floutés), style Atelier + or. Fichiers à déposer dans `docs/media/` (noms utilisés par le README) et dans l'onglet Images de CurseForge.

| # | Fichier | Écran | Détails |
|---|---|---|---|
| 1 | ~~`screenshot-interface.jpg`~~ | ~~Interface complète~~ | ❌ Abandonnée (choix du mainteneur) ; le README n'en a plus besoin |
| 2 | `screenshot-window.jpg` | **Fenêtre de configuration**, page Layouts | ✅ 2026-09-29 |
| 3 | `screenshot-browser.jpg` | **Éditeur (onglet Fond) + navigateur de textures** | ✅ 2026-09-29, image principale du README |
| 4 | `screenshot-editmode.jpg` | **Mode édition** | ✅ 2026-09-29, noms du personnage floutés |
| 5 | `screenshot-display.jpg` | Onglet **Affichage** | ✅ 2026-09-29 |
| 6 | `screenshot-text.jpg` | Onglet **Texte** | ✅ 2026-09-29, avec le rendu en jeu (FPS, monnaies) à côté |
| 7 | `screenshot-templates.jpg` | Menu **Nouveau panneau** | ✅ 2026-09-29 |
| 8 | ~~`screenshot-zhcn.jpg`~~ | ~~Fenêtre en chinois simplifié~~ | ❌ Abandonnée (choix du mainteneur) |
| 9 | ~~`screenshot-forever.jpg`~~ | ~~Layout sur WoW Forever~~ | ❌ Abandonnée (choix du mainteneur) |
| 10 | `screenshot-migration.jpg` | Message d'import dans le chat | « 3 layout(s)… importés depuis kgPanels_Reloaded » (phase B du test) |

Optionnel : un GIF court (5-10 s, < 10 Mo) du mode édition avec l'aimantation.

## 7. Logo — brief pour ChatGPT

> ✅ **Fait le 2026-09-28.** Deux versions :
> - **Stylisée** (ChatGPT, or brillant et losanges) pour les grandes tailles : `docs/media/logo-1024.png`, `logo-512.png` (transparents), `social-preview.png` (1280×640) et `banner-curseforge.png` (1200×400, à envoyer dans l'onglet Images de CurseForge pour `IMAGE_URL_BANNER`).
> - **Simplifiée** (dessin vectoriel `docs/media/icon.svg`, couleurs unies, lisible en 16 px) pour le jeu : `nxPanels/Media/icon.tga` (64×64, 32 bits avec alpha), utilisée par les 3 TOC nxPanels et le bouton de minicarte.
> - Le carré « nx » de la fenêtre de configuration reste en texte : il suit la couleur d'accent choisie par le joueur.
> - Régénérer le TGA après une retouche du SVG : `rsvg-convert -w 64 -h 64 docs/media/icon.svg -o /tmp/icon.png && magick /tmp/icon.png -compress none -type TrueColorAlpha nxPanels/Media/icon.tga` (Homebrew : `librsvg`, `imagemagick`).

**Idée.** Des *panneaux* superposés : deux ou trois rectangles aux coins légèrement arrondis, décalés comme des cadres posés sur un plan de travail, dont un seul est cerclé d'une **bordure or**. Évoque « des cadres qui habillent une interface », sans texte dans l'icône. Variante possible : un « n » stylisé formé par deux panneaux.

**Couleurs (style Atelier de la fenêtre).**
| Rôle | Couleur |
|---|---|
| Fond | charbon chaud `#12100F` → `#1A1815` |
| Panneaux | brun-gris `#221F1B`, crème `#F5EDDE` |
| Accent | **or `#FFC254`** (bordure, un seul élément) |
| Détails | beige doux `#BAAD9B` |

**Contraintes.**
- Formes simples et épaisses, **lisibles à 16×16 px** (liste des addons) ; pas de dégradés fins, pas de petits détails, pas de texte dans l'icône.
- L'essentiel dans le **cercle central (80 %)** : le bouton de la minicarte recadre en rond.
- Style plat ou légèrement « peint », cohérent avec l'univers WoW, **sans** logo ni élément graphique de Blizzard (droits d'auteur).
- Deux déclinaisons : **icône** (carré, sans texte) et **logo + nom** « nxPanels » pour les bannières.

**Prompt de départ proposé :**
> Flat vector app icon, square, dark warm charcoal background (#12100F). Three overlapping rounded rectangles like UI panels on a workbench, slightly offset, in muted brown-grey (#221F1B) and cream (#F5EDDE); the front panel has a thick gold border (#FFC254). Bold simple shapes, readable at 16 pixels, no text, no gradients, centered with generous margin, fantasy game UI mood.

**Tailles et formats.**
| Usage | Taille | Format |
|---|---|---|
| Original | 1024×1024 | PNG, fond transparent + une version fond charbon |
| Avatar CurseForge | carré, **400×400 minimum** (envoyer 1024×1024) | PNG, fond opaque |
| Bannière de la page CurseForge (`IMAGE_URL_BANNER`) | 1200×400 | PNG / JPG, logo + nom |
| README GitHub (`docs/media/logo-512.png`) | 512×512 | PNG transparent |
| Image sociale GitHub (Settings → Social preview) | **1280×640**, < 1 Mo | PNG, logo + nom + « Artistic panels for WoW » |
| Icône en jeu (`## IconTexture`) | **64×64** (puissance de 2) | **TGA 32 bits avec alpha** (ou BLP), pas de PNG |

**Intégration (je m'en charge quand tu me donnes l'image).**
1. `docs/media/logo-1024.png`, `logo-512.png`, `social-preview.png` pour GitHub.
2. `nxPanels/Media/icon.tga` (64×64), conversion avec ImageMagick si disponible.
3. `## IconTexture: Interface\AddOns\nxPanels\Media\icon` dans les 3 TOC nxPanels (le pont et le dossier vide gardent un nom neutre), icône du bouton de minicarte (`ICON` dans `nxPanels/Core/Commands.lua`) et éventuellement le carré du logo de la fenêtre (`nxPanels_Options/UI/Window.lua`).
4. Tests hors jeu, `bash tools/deploy.sh all` (redémarrage du jeu : changement de TOC), vérification dans la liste des addons, le compartiment d'addons et la minicarte.

## 8. GitHub

**Description du dépôt (proposée) :**
> Artistic panels for your World of Warcraft interface: backgrounds, borders, text, display conditions and a visual edit mode. Retail 12.x and WoW Forever. Continuation of kgPanels Reloaded.

**Site :** `https://www.curseforge.com/wow/addons/nxpanels` (après le renommage).

**Topics (proposés) :** `world-of-warcraft`, `wow-addon`, `warcraft`, `wow`, `addon`, `lua`, `ui`, `ui-customization`, `curseforge`, `kgpanels`, `wow-forever`, `wow-retail`.

**Release `1.0.0-alpha.2`** : créée par le workflow `release.yml` au push du tag (pré-version, zip du packager, notes tirées de `CHANGELOG.md`). Avant le tag : remplacer « in progress » par la date dans `CHANGELOG.md`. Résumé à mettre en tête de la release :

> **nxPanels 1.0.0-alpha.2** — first public alpha.
> New configuration window (`/nxp`) and visual edit mode (`/nxp edit`), display conditions without scripts, automatic colors, Blizzard atlases and a texture browser, text variables, templates, layouts per specialization, profiles per class or faction, sharing of layouts, folders and panels. English, French, Simplified and Traditional Chinese. Retail 12.x and WoW Forever.
> **Coming from kgPanels Reloaded?** Your layouts are imported automatically on the first start; your old data is never modified.
