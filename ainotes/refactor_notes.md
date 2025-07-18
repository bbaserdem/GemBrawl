# Gembrawl Refactor Notes

## Purpose

This document logs the reasoning, decisions, and concrete steps taken while migrating the current prototype found in `game/` into a new, well-structured Godot project rooted at `gembrawl/`, as outlined in `docs/prd.md` and `docs/project_design.md`.

---

## High-Level Goals

1. **Modular Project Layout** – Align folder hierarchy with the Recommended File Tree in `project_design.md`.
2. **Content Migration** – Move existing scenes, scripts, and assets into their new logical locations _after_ evaluating each file’s purpose.
3. **Placeholder Scaffolding** – Generate empty (placeholder) `.tscn`, `.tres`, and `.gd` files for nodes/resources that don’t yet exist but are referenced in the design docs.
4. **Clean Namespaces** – Ensure scripts use clear namespaces (folder paths) and Godot-style PascalCase for scene names.
5. **Documentation** – Keep an up-to-date record of every change _here_ instead of editing anything in `docs/`.

---

## Phase 1 – Project Skeleton

- [ ] Create root directory `gembrawl/`.
- [ ] Inside `gembrawl/`, initialise a fresh Godot project (`project.godot`, `default_env.tres`).
- [ ] Add top-level folders matching sections in **Recommended File Tree**: `assets/`, `ui/`, `game/`, `arena/`, `characters/`, `effects/`, `scripts/`, `control/`, `multiplayer/`, `globals/`, `replay/`, `utils/`, `logs/`, `tests/`.
- [ ] Commit empty `.gd` or `.gdignore` to preserve empty dirs.

## Phase 2 – Asset & Scene Migration

For each existing file in current `game/` prototype:
1. **Read** the file and classify it (scene, script, resource, asset).
2. **Decide** its target location in the new tree.
3. **Copy-with-understanding**: paste its exact contents into the new file path (no blind copying of whole folders).
4. **Update** paths inside scripts or scenes when necessary (e.g., `load("res://scripts/...`) ).

We will iterate folder-by-folder (assets → scenes → scripts).

## Phase 3 – Placeholder Generation

- Walk through `docs/project_design.md` tree and create placeholder `.tscn` / `.gd` files for nodes not yet implemented.
- Insert a short comment header in each placeholder describing its intended functionality.

## Phase 4 – Verification & Cleanup

- Run Godot editor to ensure project opens without missing-file errors.
- Fix broken resource paths discovered by Godot.
- Commit staged changes with descriptive messages per module.

---

### ⏩ Migration Batch 2–3 (UI, Player, Combat)

- **UI ➜ gembrawl/ui/hud**
  - Migrated `combat_ui.tscn` → `CombatUI.tscn`
  - Migrated `combat_ui.gd` → `CombatUI.gd`
  - Migrated `health_bar.tscn` → `HealthBar.tscn`
  - Migrated `health_bar.gd` → `HealthBar.gd`

- **Characters ➜ gembrawl/characters**
  - `player_3d.tscn` → `PlayerCharacter.tscn`
  - `player_3d.gd` → `PlayerCharacter.gd`
  - Moved gem resource `test_gem.tres` to `characters/data/`
  - Updated damage number preload path inside `PlayerCharacter.gd`

- **Skills & Effects**
  - Skills (`aoe_attack.gd`, `melee_hitbox.gd`, `projectile.gd`) → `characters/skills/`
  - Effects (`damage_number.gd`, `aoe_visual.gd`) → `effects/`
  - Scene `damage_number.tscn` renamed & moved to `effects/DamageNumber.tscn`

- **Tests**
  - Combat prototype scenes moved to `tests/combat/` with clearer names:
    - `TestAOE.tscn`, `TestProjectile.tscn`, `TestMeleeHitbox.tscn`

### ⏩ Migration Batch 4 (Core Scripts)

- **Game Logic ➜ gembrawl/game**
  - `camera_controller_3d.gd` → `CameraController.gd`
  - `simple_camera_3d.gd` → `SimpleCamera3D.gd`
  - `combat_manager.gd` → `CombatManager.gd`

- **Low-level Utilities ➜ gembrawl/scripts & utils**
  - `combat_layers.gd` → `scripts/CombatLayers.gd`
  - `damage_system.gd` → `scripts/DamageSystem.gd`
  - `godot_direction_reference.gd` → `utils/GodotDirectionReference.gd`

- **Arena Helpers ➜ gembrawl/arena**
  - `spawn_point_visual.gd` → `SpawnPointVisual.gd`

- **Characters ➜ gembrawl/characters & skills**
  - `gem.gd` → `characters/Gem.gd`
  - `skill.gd` → `characters/skills/Skill.gd`
  - Individual skill scripts (`cut.gd`, `polish.gd`, `shine.gd`) placed in `characters/skills/`

- **Test Controllers ➜ gembrawl/tests**
  - `test_camera_controller.gd` → `TestCameraController.gd`
  - `test_combat_controller.gd` → `TestCombatController.gd`
  - `test_combat_collision_controller.gd` → `TestCombatCollisionController.gd`

### ⏩ Migration Batch 5 (Scaffolding Placeholders)

- **Menus (ui/menus)**: SplashScreen, SettingsScreen, LocalMultiplayerScreen, ControllerAssignmentScreen, LobbySearchScreen, LobbySetupScreen, ControllerSelectionScreen, CharacterSelectScreen, ArenaSelectScreen `.tscn` created.
- **Game Scenes (game/)**: MainGame, PracticeMode, PracticeArena, LocalMultiplayerGame `.tscn` added.
- **Arena Scenes (arena/)**: ArenaBase, Arena1, Arena2, Tile, TrapTile, EdgeTile, FallZone, SpawnPoint placeholders.
- **Multiplayer Managers**: `NetworkManager.gd`, `LobbyManager.gd` stubs.
- **Global Singletons**: `GameState.gd`, `MatchConfig.gd`, `AudioManager.gd`, `SceneLoader.gd` stubs.

All placeholders contain minimal nodes/scripts with TODO comments for future implementation.

### ⏩ Cleanup Phase (Post-Migration)

- **Duplicate Files Removed**:
  - Removed `CombatManager.gd` from `scripts/` (kept in `game/`)
  - Removed `HexGrid3D.gd` from `scripts/` (kept in `arena/`)
  - Removed `damage_number.gd` from `effects/` (kept `DamageNumber.gd`)
  - Removed `projectile.gd` from `characters/skills/` (kept `Projectile.gd`)
  - Removed `polish.gd` and `shine.gd` from `characters/skills/` (kept PascalCase versions)
  - Removed duplicate test files with snake_case naming

- **File Reorganization**:
  - Moved `godot_direction_reference.gd` from `scripts/` to `utils/`
  - Renamed to `GodotDirectionReference.gd` (PascalCase)

- **3D Reference Removal** (since entire project is 3D):
  - `SimpleCamera3D.gd` → `SimpleCamera.gd`
  - `HexGrid3D.gd` → `HexGrid.gd`
  - `HexArena3D.gd` → `HexArena.gd`
  - `HexArena3D.tscn` → `HexArena.tscn`

- **Snake_case to PascalCase Conversions**:
  - `melee_hitbox.gd` → `MeleeHitbox.gd`
  - `godot_direction_reference.gd` → `GodotDirectionReference.gd`
  - `test_combat_collision.tscn` → `TestCombatCollision.tscn`
  - `test_combat.tscn` → `TestCombat.tscn`
  - `test_hex_3d.tscn` → `TestHex.tscn`
  - `hex_arena_3d_gameplay.tscn` → `HexArenaGameplay.tscn`

### ⏩ Path Updates & Reference Fixes

- **Updated Import Paths**:
  - TestCombatCollisionController.gd: Fixed preload paths for player and test scenes
  - HUDManager.gd: Updated health bar preload path
  - All HexGrid3D class references updated to HexGrid
  - All HexArena3D class references updated to HexArena
  - Updated .tscn file script paths to match new locations

- **Class Name Changes**:
  - `class_name HexGrid3D` → `class_name HexGrid`
  - `class_name HexArena3D` → `class_name HexArena`
  - All static method calls updated accordingly

*Last updated: 2025-01-18* 