# Revue du code nxPanels (2026-10-25)

Périmètre : `nxPanels/`, `nxPanels_Options/`, `nxPanels_Import/` (sans `Libs/`), sur `main` (`b92efeb`). Clients : Retail 12.1.5.70575, WoW Forever 1.60.1.70532, TBC Anniversary 2.5.6.70006 (versions données par `wowapi.py version`).

## Résumé

1. `run-all.sh` vert (lint sans remarque, tous les scénarios) ; `wowapi.py audit` : aucune API supprimée, inconnue ou dépréciée, aucun événement inconnu sur les 3 clients.
2. Aucun problème critique trouvé. Migration (section 5 du suivi) respectée : `kgPanelsDB` n'est jamais écrit (copie profonde avant toute conversion).
3. **Important** : le ticker de nouvelle tentative (`Engine/Layouts.lua`) n'est jamais remis à `nil` après ses 60 essais : ensuite, un panneau qui attend sa frame n'est plus réessayé chaque seconde jusqu'au prochain rechargement du layout.
4. **Important** : les textures, textes et frames créés par les scripts (`self:CreateTexture()`…) restent sur le cadre recyclé et apparaissent sur un autre panneau après un changement de layout.
5. **Mineur** : `/nxp layout <nom>` avec les panneaux désactivés provoque une erreur Lua (`format` reçoit `nil`).
6. **Mineur** : une chaîne d'import abîmée ou piégée peut provoquer une erreur Lua et laisser un layout à moitié créé (types non vérifiés).
7. Quelques points mineurs ou d'amélioration (taille en % et échelle, événements sans protection, OnUpdate permanent, double validation des champs).
8. Valeurs secrètes de Midnight : rien à corriger (seulement `"player"`, et `UnitCanAttack` / `UnitIsFriend` / `UnitExists` sans drapeau en 12.1.5).
9. Revue non terminée : la partie « vérifier chaque point douteux par un test » reste à faire (voir « Suite »).

## 1. État des lieux automatique

| Contrôle | Résultat |
|---|---|
| `bash tools/tests/run-all.sh` | Vert. `lint: no problems (3.19.1, annotations 2026-06-24)` ; migrate 159, original 6, handinstall 7, empty 4, nolibs 3, notloaded 4, forever 160, tbc 161, zhcn 161, options 9262 × 11 langues, 0 échec. Le scénario `real` n'est pas lancé par `run-all.sh` (non relancé ici) |
| `wowapi.py audit` (3 addons × live, forever, classic_anniversary) | 0 API supprimée / migrée / dépréciée, 0 événement inconnu, 0 motif à risque. « Secret / restricted » : `UnitClass`, `UnitName` (seulement `"player"` : faux positifs, déjà écartés dans le suivi 7 ter). Interfaces du TOC à jour |

## 2. Vrais problèmes

| # | Fichier:ligne | Gravité | Client | Explication | Correction proposée | Certitude |
|---|---|---|---|---|---|---|
| 1 | `nxPanels/Engine/Layouts.lua:129-138` | Important | Tous | `C_Timer.NewTicker(1, f, 60)` s'arrête seul après 60 essais, mais la variable `ticker` garde l'objet : `StartRetry` sort aussitôt (`if ticker`) jusqu'au prochain `ReleaseAll`. Un panneau ajouté ou réancré plus d'une minute après le chargement, vers une frame qui n'existe pas encore, n'est plus réessayé chaque seconde (il reste les essais sur `ADDON_LOADED` et `PLAYER_ENTERING_WORLD`). Signature vérifiée : `C_Timer.NewTicker(seconds, callback, iterations?)` (12.1.5.70575) | Compter les essais soi-même et mettre `ticker = nil` au dernier, ou tester `ticker:IsCancelled()` dans `StartRetry`. Test : simuler 60 ticks puis un `PanelChanged(id, "anchors")` vers une frame absente | Haute (logique) |
| 2 | `nxPanels/Render/Panel.lua:82-103` | Important | Tous | `Release` efface les clés posées par les scripts, mais pas les régions et frames enfants qu'ils ont créées, ni l'état des widgets (`SetMovable`, `RegisterForDrag`, ombre du texte, `SetDesaturated` du fond, `HookScript`). Au `ApplyActive` suivant (changement de layout, de profil, de spé, import), le cadre peut servir à un autre panneau : la texture créée par le script de A s'affiche sur B ; sur le même panneau, `LOAD` en recrée une de plus | Noter les régions / enfants à la création (`GetRegions`, `GetChildren`) ; à la libération, si le cadre en a d'autres (ou si le panneau avait des scripts), ne pas le remettre dans la réserve : le cacher et l'abandonner. Test : un script `LOAD` qui crée une texture, puis réactivation du layout | Haute sur le mécanisme, moyenne sur la fréquence |
| 3 | `nxPanels/Core/Commands.lua:33-39` | Mineur | Tous | Avec les panneaux désactivés (`/nxp off`), `ApplyActive` ne fixe pas `activeId` : `GetActiveLayout()` renvoie `nil` et `L["LAYOUT_ACTIVE"]:format(nil)` lève une erreur Lua 5.1 (`%s` attend une chaîne) | Utiliser le nom du layout trouvé par `FindLayout` (ou `activeName()`). Test : `/nxp off` puis `/nxp layout X` | Haute |
| 4 | `nxPanels/Core/Share.lua:67-97, 141-168` | Mineur | Tous | Le contenu décodé n'est pas vérifié : un panneau qui n'est pas une table, `anchor` / `background` / `text` d'un mauvais type, ou un nom non textuel font une erreur Lua pendant `addPanels`, après `CreateLayout` (layout vide laissé). Les chemins de `payload.media` ne sont pas vérifiés non plus | Nettoyer le contenu dans `decodeNative` : ignorer les panneaux non-table, remplacer les sous-tables de mauvais type par les valeurs par défaut, `tostring` sur les noms, ne garder que les chemins texte ou nombre. Test : chaînes forgées | Haute |
| 5 | `nxPanels/Render/Panel.lua:114-116` | Mineur | Tous | Une taille en `%` est calculée dans les unités du parent puis appliquée au cadre mis à l'échelle (`SetScale`) : 100 % avec une échelle de 0,5 donne la moitié du parent. Peut être voulu | Diviser par `scale` pour les tailles en %, si le mainteneur confirme que « % du parent » doit être visuel | Moyenne (choix possible) |
| 6 | `nxPanels/Core/Init.lua:75-81` | Mineur | Tous | Les gestionnaires d'un même événement sont appelés sans protection : une erreur dans l'un (données abîmées dans `ApplyActive` au `PLAYER_LOGIN`) empêche les suivants (`News`, `Import:Finish`) | Appeler chaque gestionnaire avec `xpcall(fn, geterrorhandler(), ...)` | Haute |
| 7 | `nxPanels_Import/Convert.lua:101` | Mineur | Tous | `ns.Anchors:Resolve(value)` sans table `frames` : une ancienne valeur commençant par `panel:` ferait une erreur (`frames[id]` sur `nil`). Très improbable avec des données kgPanels | Passer `{}` comme deuxième argument | Haute (cas rare) |
| 8 | `nxPanels/Render/Panel.lua:183-189` | Mineur | Tous | Fond répété (`tile`) : le style (`NONE`, `GRADIENT`) est ignoré et l'alpha de la couleur n'est pas limité par l'opacité, contrairement au fond simple | Appliquer la même règle de couleur dans les deux chemins | Moyenne (comportement hérité possible) |

## 3. Améliorations (sans changer le comportement)

| # | Fichier:ligne | Idée |
|---|---|---|
| A1 | `nxPanels/Engine/Visibility.lua:164-184` | L'`OnUpdate` du `driver` tourne à chaque image même sans fondu ni panneau à surveiller : le cacher quand `fades` est vide et qu'aucun panneau ne demande de sondage |
| A2 | `nxPanels/Engine/TextVars.lua:104-110` | `SetText` chaque seconde même si le texte n'a pas changé : comparer avec le dernier rendu |
| A3 | `nxPanels_Options/UI/Widgets.lua:450-461` | `InputRow` valide deux fois (Entrée puis perte du focus) : sans effet aujourd'hui (renommage idempotent), mais fragile |
| A4 | `nxPanels/Engine/Scripts.lua:57-65` | Une erreur dans `CLICK` ne coupe que `OnMouseDown` ou `OnMouseUp` : couper les deux |
| A5 | `nxPanels/Engine/Anchors.lua:55-70` | Dans une boucle de plus de deux panneaux, tous ne sont pas signalés (`ANCHOR_CYCLE`) ; la boucle est bien cassée, seul le message est incomplet |
| A6 | `nxPanels/Core/Database.lua:82-92` | Données venant d'une version plus récente (`schema > ns.SCHEMA`, retour à une ancienne version) : le numéro est rabaissé sans avertissement |
| A7 | `nxPanels_Options/EditMode/EditMode.lua:792` | La grille n'est pas redessinée sur `UI_SCALE_CHANGED` |

## 4. Faux positifs écartés

- `UnitClass` / `UnitName` (audit, `SecretWhenUnitIdentityRestricted`) : appelés seulement sur `"player"`.
- `UnitCanAttack`, `UnitIsFriend`, `UnitExists` sur `"target"` : aucun drapeau de restriction (12.1.5.70575).
- `C_SpecializationInfo.GetSpecializationInfo(index)` avec un seul argument : `isInspect` et `isPet` ont `Default = false` dans la doc de Blizzard (la sortie de `lookup` les montre à tort comme obligatoires). Présente sur les 3 clients.
- `C_AddOns.DisableAddOn(name)` sans personnage : `character` a `Default = "0"` (3 clients).
- Divisions : toutes protégées (`scale > 0`, `tileSize > 0`, `size > 0`, `f.duration > 0` car écart ≥ 0,01 et `fade > 0`, `math.max(1, …)` en mode édition, barres de défilement avec `total > visible + 1`).
- Polices : `STANDARD_TEXT_FONT` partout ; une police LibSharedMedia qui ne gère pas la langue n'est pas enregistrée par LibSharedMedia, donc `FetchFont` revient à la police par défaut.
- Clés de données : jamais traduites (`Options:Choices` traduit seulement le texte affiché). Toutes les clés `L[...]` utilisées existent (celles de l'import sont dans `nxPanels_Import/Locales.lua`).
- `Anchors:Order` : toute boucle est cassée (un nœud par arête arrière).
- Import : `kgPanelsDB` copié (`ns.DeepCopy`) avant conversion, jamais écrit ; pont et dossier de config intacts.
- Combat : les panneaux sont des frames non protégées ; le mode édition se ferme sur `PLAYER_REGEN_DISABLED` et `SetPropagateKeyboardInput` est protégé par `InCombatLockdown()`.
- Scripts : environnement partagé avec `__index = _G`, erreurs attrapées par `pcall` et signalées une fois. Ce n'est pas un bac à sable (voulu : compatibilité kgPanels ; avertissement à l'import).

## 5. Ce qui coince dans les outils (pour claude-skills / tools)

- `wowapi.py lookup` n'affiche pas les `Default = …` de la doc de Blizzard : des arguments facultatifs paraissent obligatoires (`GetSpecializationInfo`, `DisableAddOn`).
- `wowapi.py lookup` ne cherche pas dans les annotations de Ketho alors que `audit` le fait : `GetAverageItemLevel`, `SecureCmdOptionParse`, `GetMacroIcons`, `C_PetBattles.IsInBattle` donnent « No match ».
- `wowapi.py audit` dit « embedded libraries skipped » mais liste `Libs\AceDB-3.0` dans la section des API secrètes.
- `wowapi.py source 'function C_Timer.NewTicker'` ne trouve rien (fonction côté C) sans le dire : un message « défini côté C, voir `lookup` » aiderait.
- `run-all.sh` ne lance pas le scénario `real` quand `.local/kgPanels_Reloaded.lua` existe : à ajouter (ou l'indiquer à la fin).

## 6. Suite

Revue arrêtée avant la fin (limite d'utilisation) : les points 1 à 8 sont tirés de la lecture du code, pas encore reproduits par un test. À l'étape 4 (après le feu vert), chaque correction commence par un test dans `tools/tests/run.lua` qui échoue.
