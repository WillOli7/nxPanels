# kgPanels_Reloaded — Feuille de route & idées

Document vivant : les idées sont consignées ici pour être retravaillées, priorisées et étoffées au fil du projet.
Statuts : 💡 idée · 🔍 à étudier · 📐 spécifié · 🚧 en cours · ✅ livré

---

## Priorités

| # | Sujet | Statut | Notes |
|---|-------|--------|-------|
| P1 | **Support complet du client chinois (zhCN, et zhTW)** | 🔍 | Priorité forte : communauté chinoise très présente en jeu. Voir section dédiée. |
| P2 | Correctif v0.4.1 (bugs bloquants du code actuel) | 📐 | `L` nil, `IsAddOnLoaded`, `SetColorTexture`, compteur `checkFrames`, chemins cassés… |
| P3 | Compatibilité **WoW Forever** (Interface 16001, `_Camelot.toc`) | 🔍 | Client « Mainline » allégé : pas de `GetSpecialization`, `BackdropTemplate` possiblement absent. |
| P4 | Réécriture v1.0 (sortie de l'héritage eePanels) | 🔍 | Voir « Architecture v1.0 ». |
| P5 | Nouvelle interface de configuration (inspiration EllesmereUI) | 💡 | Mode édition visuel + fenêtre de config moderne. |

---

## Client chinois (zhCN / zhTW)

Constats sur le code actuel :
- Police par défaut = `L["Blizzard"]` (« 暴雪 » en zhCN), inexistante dans LibSharedMedia → repli sur `FRIZQT__.TTF`, **sans glyphes chinois** → texte invisible / carrés.
- LibSharedMedia n'enregistre pas « Friz Quadrata TT » en zhCN → les layouts importés d'EU/US tombent aussi dans ce repli.
- Clés de données localisées (`"None"`, `"Blizzard Tooltip"`…) → incohérences entre locales et entre joueurs qui s'échangent des layouts.

À faire :
- 💡 Repli de police par locale : `STANDARD_TEXT_FONT` / police par défaut LSM ; jamais de police latine en dur.
- 💡 Clés de données **neutres** (jamais traduites), traduction uniquement à l'affichage.
- 💡 Import de layouts : remapper les polices absentes du client vers la police par défaut de la locale.
- 💡 Revue des traductions zhCN/zhTW (idéalement par un joueur natif) ; la zhTW actuelle contient des tournures zhCN (« 默認 »).
- 💡 Tester l'affichage des noms de panneaux/calques en caractères CJK dans la config (largeurs, troncature).
- 💡 FAQ / guide traduits, captures d'écran pour la page CurseForge chinoise.
- 🔍 Récupérer le rapport d'erreur (BugSack) du joueur qui a signalé le problème.

---

## Identité du projet (décidé le 2026-09-27)

La v1.0 devient un addon à part entière, sans lien de code avec eePanels / kgPanels.

| Sujet | Décision | Statut |
|---|---|---|
| Nom | Nouveau nom, à choisir (vérifier la disponibilité sur CurseForge, Wago et GitHub) | 🔍 |
| Base de sauvegarde | Nouvelle base avec son propre nom + import des anciennes données kgPanels / kgPanels_Reloaded | 📐 |
| Licence | Licence propre, à choisir | 🔍 |
| Crédits | Une ligne de remerciement envers kgPanels (kagaro) et eePanels | 📐 |

Point technique : un addon ne peut lire que son propre fichier de sauvegarde (fichier nommé d'après son dossier).

**Plan de migration (à concevoir en phase 2) — indispensable :**
- **Depuis kgPanels_Reloaded** : livrer, avec le nouvel addon, un petit dossier « pont » `kgPanels_Reloaded` (chargé à la demande, `## SavedVariables: kgPanelsDB`). Il lit l'ancien fichier de sauvegarde, le nouvel addon importe les données automatiquement, sans action du joueur.
- **Depuis kgPanels (original)** : si l'addon d'origine est détecté, import de `kgPanelsDB` puis proposition de le désactiver. Sinon, import par chaîne d'export.
- Garder le **même projet CurseForge** (renommé) pour que les joueurs actuels reçoivent la mise à jour automatiquement.
- Tester le comportement de l'app CurseForge quand les noms de dossiers changent.

## Phases

| Phase | Contenu | Statut |
|---|---|---|
| 1 | Librairies : mises à jour, suppressions, ajouts (`Libs-VERSIONS.md`, `tools/check-libs.sh`) | ✅ branche `v1/phase1-libs` |
| 2a | Moteur nxPanels : données, migration, rendu, bordures, ancrages, scripts, commandes, minicarte, tests hors jeu | 🚧 branche `v1/phase2-core` — en test local |
| 2b | Fenêtre de configuration (`nxPanels_Options`) + mode édition | 🔍 |
| 2c | Nouvelles options (visibilité, animations, masques…) | 💡 |

**Nom : nxPanels** (« next »), licence **GPLv3**, décidés le 2026-09-27.

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

Principe : les librairies ne sont plus copiées dans le dépôt ; elles sont récupérées à la dernière version par le packager (`.pkgmeta`, section `externals`).

| Librairie | Rôle | Décision v1.0 |
|---|---|---|
| LibStub, CallbackHandler-1.0 | Chargement des librairies, callbacks | Garder (socle des autres) |
| AceDB-3.0 | Profils (perso / classe / royaume), valeurs par défaut | Garder (profils + migration de l'ancienne base) |
| LibSharedMedia-3.0 | Textures / polices partagées entre addons | Garder (indispensable pour un addon artistique) |
| AceSerializer-3.0 | Chaînes d'export | Garder (import des anciens exports kgPanels) |
| AceLocale-3.0 | Traductions | Garder (traduction collaborative via CurseForge) |
| LibDualSpec-1.0 | Profil par spécialisation | Garder, mettre à jour (v35 gère Forever) |
| LibDeflate | Compression des exports | Ajouter |
| AceAddon-3.0, AceConsole-3.0 | Cycle de vie, commande `/kgpanels` | Remplacer par du code maison (quelques dizaines de lignes) |
| LibBackdrop-1.0 | Bordures | Supprimer → bordure maison en 9 parties |
| AceConfig / AceGUI / AceDBOptions / SharedMediaWidgets | Interface de config actuelle | Remplacer par la nouvelle interface ; conservés pendant la transition |

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
- 💡 **Conditions d'affichage sans script** : combat / hors combat, groupe / raid, type d'instance, monture, cible existante, combat de mascottes, conditions de macro (`[combat] show; hide`).
- 💡 **Animations** : fondu d'apparition/disparition, opacité au survol, opacité différente en combat.
- 💡 Changement automatique de layout par spécialisation, personnage ou résolution d'écran.

### Rendu artistique
- 💡 **Couleurs dynamiques** : classe, faction, réaction de la cible (fond et bordure).
- 💡 **Masques** (`MaskTexture`) : coins arrondis, cercles, formes personnalisées.
- 💡 **Plusieurs calques de texture** par panneau.
- 💡 Support direct des **atlas Blizzard** (`C_Texture.GetAtlasInfo`).
- 💡 **Ombres / halos**, bordure intérieure + extérieure, bordures 1 px au pixel près (`PixelUtil`).
- 💡 Dégradés à 4 coins / multi-étapes ; dégradés de bordure.
- 💡 Désaturation, couleur de sommet (vertex color).

### Texte
- 💡 Contour et ombre du texte (options de police).
- 💡 **Variables sans Lua** : `{player}`, `{zone}`, `{time}`, `{fps}`, `{latency}`…

### Création & édition
- 💡 **Mode édition visuel** : grille, aimantation (bords, centre, autres panneaux), guides d'alignement, flèches du clavier, sélection multiple, annuler/rétablir.
- 💡 **Navigateur de textures en vignettes** (au lieu d'une liste déroulante).
- 💡 **Sélecteur de frame au survol** (façon `/fstack`) pour ancrer sur EllesmereUI, ElvUI, frames du mode édition…
- 💡 Éditeur de scripts : coloration syntaxique, affichage de la ligne en erreur, bibliothèque d'extraits.

### Partage
- 💡 **Chaînes d'export compressées** (LibDeflate, préfixe versionné), compatibles avec les anciens exports kgPanels.
- 💡 **Galerie de modèles** prêts à l'emploi.
- 💡 Avertissement de sécurité à l'import quand le layout contient des scripts.

### Intégration
- 💡 Bouton du menu des addons (`## AddonCompartmentFunc`).
- 💡 Catégorie dans les options Blizzard (API Settings).

---

## Recherche & inspiration
- 🔍 Parcourir r/WowUI, les UI Packs Wago et les commentaires CurseForge de kgPanels pour recenser des créations d'utilisateurs.
- 🔍 Étudier le mode édition d'EllesmereUI (aimantation, alignement au pixel près).
- 🔍 WeakAuras n'est plus développé pour Midnight / Forever : une partie de ses usages « décoratifs » pourrait se reporter sur kgPanels.
