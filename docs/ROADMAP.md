# nxPanels — Feuille de route & idées

Document vivant : les idées sont consignées ici pour être retravaillées, priorisées et étoffées au fil du projet.
Statuts : 💡 idée · 🔍 à étudier · 📐 spécifié · 🚧 en cours · ✅ livré · ❌ abandonné

État détaillé du projet : `docs/SUIVI.md`. Publication : `docs/publication/PUBLICATION.md`.

---

## Priorités

| # | Sujet | Statut | Notes |
|---|-------|--------|-------|
| P1 | **Support complet du client chinois (zhCN, et zhTW)** | 🚧 | Polices, clés neutres et traductions faits (scénario de test `zhcn`). Reste : relecture par un joueur natif. Voir section dédiée. |
| P2 | Correctif v0.4.1 (bugs bloquants du code actuel) | ❌ | Abandonné : remplacé par la réécriture nxPanels. |
| P3 | Compatibilité **WoW Forever** (Interface 16001) | 🚧 | Testé en jeu (démarrage, import, atlas, conditions). Reste : layout par groupe de talents. |
| P4 | Réécriture v1.0 (sortie de l'héritage eePanels) | 🚧 | nxPanels `1.0.0` publiée le 2026-09-29. Voir « Architecture v1.0 ». |
| P5 | Nouvelle interface de configuration (inspiration EllesmereUI) | ✅ | Fenêtre `nxPanels_Options` + mode édition, testés en jeu sur Retail. |
| P6 | **Publication** (remplace kgPanels Reloaded sur CurseForge) | ✅ | `1.0.0` en release le 2026-09-29 (phases A, B, C réussies). |

---

## Client chinois (zhCN / zhTW)

Constats sur l'ancien code (kgPanels Reloaded) :
- Police par défaut = `L["Blizzard"]` (« 暴雪 » en zhCN), inexistante dans LibSharedMedia → repli sur `FRIZQT__.TTF`, **sans glyphes chinois** → texte invisible / carrés.
- LibSharedMedia n'enregistre pas « Friz Quadrata TT » en zhCN → les layouts importés d'EU/US tombent aussi dans ce repli.
- Clés de données localisées (`"None"`, `"Blizzard Tooltip"`…) → incohérences entre locales et entre joueurs qui s'échangent des layouts.

À faire :
- ✅ Repli de police par locale : `STANDARD_TEXT_FONT` / police par défaut LSM ; jamais de police latine en dur.
- ✅ Clés de données **neutres** (jamais traduites), traduction uniquement à l'affichage.
- ✅ Import de layouts : remapper les polices absentes du client vers la police par défaut de la locale.
- 🚧 Traductions zhCN / zhTW écrites (mêmes clés que enUS / frFR, vérifié par les tests). Reste : relecture par un joueur natif.
- 💡 Tester l'affichage des noms de panneaux/calques en caractères CJK dans la config (largeurs, troncature).
- 💡 FAQ / guide traduits, captures d'écran pour la page CurseForge chinoise.
- 🔍 Récupérer le rapport d'erreur (BugSack) du joueur qui a signalé le problème.

---

## Identité du projet (décidé le 2026-09-27)

La v1.0 devient un addon à part entière, sans lien de code avec eePanels / kgPanels.

**Nom : nxPanels** (« next »), licence **Tous droits réservés** (GPL-3.0-or-later jusqu'au 2026-09-28).

| Sujet | Décision | Statut |
|---|---|---|
| Nom | **nxPanels** (slug CurseForge `nxpanels` libre au 2026-09-28) | ✅ |
| Base de sauvegarde | Nouvelle base avec son propre nom + import des anciennes données kgPanels / kgPanels_Reloaded | ✅ |
| Licence | Tous droits réservés (décidé le 2026-09-29, avant : GPL-3.0-or-later) | ✅ |
| Crédits | Une ligne de remerciement envers kgPanels (kagaro) et eePanels (section « Origins » du README) | ✅ |

Point technique : un addon ne peut lire que son propre fichier de sauvegarde (fichier nommé d'après son dossier).

**Plan de migration — indispensable** (✅ fait, invariants dans `docs/SUIVI.md` section 5) :
- **Depuis kgPanels_Reloaded** : livrer, avec le nouvel addon, un petit dossier « pont » `kgPanels_Reloaded` (chargé à la demande, `## SavedVariables: kgPanelsDB`). Il lit l'ancien fichier de sauvegarde, le nouvel addon importe les données automatiquement, sans action du joueur.
- **Depuis kgPanels (original)** : si l'addon d'origine est détecté, import de `kgPanelsDB` puis proposition de le désactiver. Sinon, import par chaîne d'export.
- Garder le **même projet CurseForge** (renommé) pour que les joueurs actuels reçoivent la mise à jour automatiquement.
- 🚧 Tester le comportement de l'app CurseForge quand les noms de dossiers changent (phases B et C de `PUBLICATION.md`).

## Phases

| Phase | Contenu | Statut |
|---|---|---|
| 1 | Librairies : mises à jour, suppressions, ajouts (`Libs-VERSIONS.md`, `tools/check-libs.sh`) | ✅ |
| 2a | Moteur nxPanels : données, migration, rendu, bordures, ancrages, scripts, commandes, minicarte, tests hors jeu | ✅ sur `main`, testé en jeu |
| 2b | Fenêtre de configuration (`nxPanels_Options`) + mode édition | ✅ sur `main` (PR #1), testée en jeu sur Retail |
| 2c | Nouvelles options (visibilité, animations, masques…) | 🚧 visibilité, opacité, couleurs dynamiques, variables faites ; masques et calques à venir |
| 3 | Publication `1.0.0` (après `1.0.0-alpha.2`) | ✅ |

---

## Soutien au projet

Règle Blizzard : addon 100 % gratuit, aucune fonction payante, aucun appel aux dons dans le jeu.

- 💡 Programme de récompenses auteurs CurseForge.
- 💡 Liens Ko-fi / Patreon / GitHub Sponsors sur CurseForge, Wago et le README (hors jeu uniquement).
- 💡 Avantages non payants pour les soutiens : crédits, accès anticipé aux versions de test, vote sur les fonctionnalités.
- ⚠️ Chine : NetEase sanctionne les addons payants et les profils vendus → rester strictement gratuit.

---

## Architecture v1.0 (réécriture)

**Critères de validation de la v1.0** (décidés le 2026-09-27) :
1. Code entièrement réécrit (plus aucun code hérité d'eePanels).
2. Intégration complète du client chinois (zhCN / zhTW).
3. Compatibilité totale avec WoW Forever.

Objectif : un runtime léger et robuste, une config chargée à la demande, et une compatibilité totale avec les layouts existants.

### Librairies

Principe retenu : les librairies restent **dans le dépôt** (versions dans `Libs-VERSIONS.md`, vérifiées par `tools/check-libs.sh`) ; Ace3 vient de sa branche master (support de WoW Forever par AceDB).

| Librairie | Rôle | Décision v1.0 |
|---|---|---|
| LibStub, CallbackHandler-1.0 | Chargement des librairies, callbacks | Garder (socle des autres) |
| AceDB-3.0 | Profils (perso / classe / royaume), valeurs par défaut | Garder (profils + migration de l'ancienne base) |
| LibSharedMedia-3.0 | Textures / polices partagées entre addons | Garder (indispensable pour un addon artistique) |
| AceSerializer-3.0 | Chaînes d'export | Garder (import des anciens exports kgPanels) |
| LibSerialize | Chaînes d'export nxPanels | ✅ Ajoutée (patchée contre la division par zéro de Forever) |
| LibDataBroker, LibDBIcon | Bouton de minicarte | ✅ Ajoutées |
| AceLocale-3.0 | Traductions | Garder (traduction collaborative via CurseForge) |
| LibDualSpec-1.0 | Profil par spécialisation | ✅ Retirée : remplacée par un layout par spécialisation |
| LibDeflate | Compression des exports | ✅ Ajoutée |
| AceAddon-3.0, AceConsole-3.0 | Cycle de vie, commande `/kgpanels` | ✅ Retirées : code maison, commande `/nxp` |
| LibBackdrop-1.0 | Bordures | ✅ Retirée : bordure maison (`Render/Border.lua`) |
| AceConfig / AceGUI / AceDBOptions / SharedMediaWidgets | Ancienne interface de config | ✅ Retirées : remplacées par la fenêtre maison (`nxPanels_Options`) |

- **Modèle de données versionné** : identifiants stables (GUID) pour les panneaux, noms = simples libellés ; migrations depuis le format kgPanels (version 6) ; clés neutres.
- **Rendu** : `KGPanelMixin` + pools Blizzard (`CreateFramePool`) ; calques : fond, masque, bordure maison en 9 parties (fin de LibBackdrop), ombre, texte.
- **Résolution des ancrages** : graphe de dépendances, détection de cycles, résolution sur événements (`ADDON_LOADED`, `PLAYER_ENTERING_WORLD`) plutôt que le hook global de `CreateFrame` + sondage `OnUpdate`.
- **Scripts** : compilés une fois, environnement isolé, gestion d'erreurs limitée (pas de spam), activation par panneau, **confirmation à l'import** (affichage du code).
- **Shim de compatibilité** : les anciens scripts (`self.bg`, `self.text`, `kgPanels:FetchFrame`…) continuent de fonctionner.
- **Couche de compatibilité par client** : Retail 12.x, Forever 16001, Classic éventuellement.
- **Outillage** : `.pkgmeta`, GitHub Actions (luacheck + packager), annotations LuaLS pour l'API WoW.

---

## Nouvelles options (backlog)

### Affichage & comportement
- ✅ **Conditions d'affichage sans script** : combat / hors combat, groupe / raid, type d'instance, monture, cible existante, combat de mascottes, conditions de macro (`[combat] show; hide`).
- ✅ **Animations** : fondu d'apparition/disparition, opacité au survol, opacité différente en combat.
- 🚧 Changement automatique de layout par spécialisation (fait, Retail) / groupe de talents (Forever, à tester en jeu) ; reste : par résolution d'écran.

### Rendu artistique
- ✅ **Couleurs dynamiques** : classe, faction, réaction de la cible (fond et bordure).
- 💡 **Masques** (`MaskTexture`) : coins arrondis, cercles, formes personnalisées.
- 💡 **Plusieurs calques de texture** par panneau.
- ✅ Support direct des **atlas Blizzard** (`C_Texture.GetAtlasInfo`).
- 💡 **Ombres / halos**, bordure intérieure + extérieure, bordures 1 px au pixel près (`PixelUtil`).
- 💡 Dégradés à 4 coins / multi-étapes ; dégradés de bordure.
- 💡 Désaturation, couleur de sommet (vertex color).

### Texte
- 💡 Contour et ombre du texte (options de police).
- ✅ **Variables sans Lua** : `{zone}`, `{time}`, `{fps}`, `{latency}`, `{gold}`, `{currency:<id>}`, `{item:<id>}`…, icônes du jeu.

### Création & édition
- ✅ **Mode édition visuel** : grille, aimantation (bords, centre, autres panneaux), guides d'alignement, flèches du clavier, sélection multiple, annuler/rétablir.
- ✅ **Navigateur de textures en vignettes** (au lieu d'une liste déroulante).
- ❌ **Sélecteur de frame au survol** : essayé puis retiré (frames protégées depuis Midnight, trop coûteux sur une grosse interface). Reste « Autre frame… » avec `/fstack`.
- 🚧 Éditeur de scripts : affichage de la ligne en erreur (fait). Reste : coloration syntaxique, bibliothèque d'extraits.

### Partage
- ✅ **Chaînes d'export compressées** (LibDeflate, préfixe versionné `!NXP1!`), et lecture des anciens exports kgPanels.
- ✅ **Galerie de modèles** prêts à l'emploi (menu « Nouveau panneau »).
- ✅ Avertissement de sécurité à l'import quand le layout contient des scripts.

### Intégration
- ✅ Bouton du menu des addons (`## AddonCompartmentFunc`).
- ✅ Catégorie dans les options Blizzard (API Settings).

---

## Recherche & inspiration
- 🔍 Parcourir r/WowUI, les UI Packs Wago et les commentaires CurseForge de kgPanels pour recenser des créations d'utilisateurs.
- 🔍 Étudier le mode édition d'EllesmereUI (aimantation, alignement au pixel près).
- 🔍 WeakAuras n'est plus développé pour Midnight / Forever : une partie de ses usages « décoratifs » pourrait se reporter sur nxPanels.
