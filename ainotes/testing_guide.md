# GemBrawl Testing Guide

## Overview
This guide helps you test the refactored GemBrawl codebase to ensure all systems work correctly after the migration from `game/` to `gembrawl/`.

## Prerequisites
1. Open the project in Godot 4.x
2. Navigate to the `gembrawl/` folder as the project root
3. Let Godot import all assets

## Main Entry Points

### 1. Main Game Scene
**Path**: `game/MainGame.tscn`
- The primary game scene
- Test by running: F6 with this scene open

### 2. Practice Mode
**Path**: `game/PracticeMode.tscn`
- Single player practice arena
- Good for testing basic mechanics

### 3. Splash Screen
**Path**: `ui/menus/SplashScreen.tscn`
- Game intro/menu system
- Tests UI navigation

## Test Scenes

### 1. Hex Arena Gameplay Test
**Path**: `tests/HexArenaGameplay.tscn`
**Tests**: Hexagonal grid movement, spawning system, camera controls
**How to test**:
1. Open scene and press F6
2. Use WASD/Arrow keys to move
3. Verify smooth hex-based movement
4. Check camera follows player properly

### 2. Combat System Test
**Path**: `tests/TestCombat.tscn`
**Tests**: Damage types, health system, death/respawn
**How to test**:
1. Open scene and press F6
2. Press Spacebar to apply damage
3. Press K to test instant kill
4. Press R to respawn
5. Verify damage numbers appear
6. Check health bar updates

### 3. Combat Collision Test (Most Comprehensive)
**Path**: `tests/TestCombatCollision.tscn`
**Tests**: All combat mechanics together
**How to test**:
1. Open scene and press F6
2. Movement: WASD/Arrow keys
3. Melee attack: Enter or Gamepad X
4. Projectile: Q or Gamepad Square
5. AoE attack: E or Gamepad Circle
6. Switch players: Tab
7. Verify all attacks hit enemies
8. Check UI shows both player health bars

### 4. Hex Grid Test
**Path**: `tests/TestHex.tscn`
**Tests**: Basic hex grid functionality
**How to test**:
1. Open scene and press F6
2. Test movement on hex grid
3. Verify grid boundaries work

### 5. Individual Combat Components
Located in `tests/combat/`:
- `TestAOE.tscn` - Area effect attacks
- `TestMeleeHitbox.tscn` - Melee combat
- `TestProjectile.tscn` - Projectile mechanics

## Testing Checklist

### Core Systems
- [ ] Hex grid movement works smoothly
- [ ] Camera follows player correctly
- [ ] All movement inputs respond (keyboard/gamepad)

### Combat Systems
- [ ] Melee attacks create hitboxes
- [ ] Projectiles fire and travel correctly
- [ ] AoE attacks show warning zones
- [ ] Damage numbers appear on hit
- [ ] Health bars update properly
- [ ] Death triggers correctly
- [ ] Respawn works at spawn points

### UI Systems
- [ ] Health bars display for all players
- [ ] Combat UI scales properly
- [ ] Menu navigation works (if testing SplashScreen)

### Resource Loading
- [ ] No missing script errors in console
- [ ] No missing scene/resource errors
- [ ] All textures/sprites load properly

## Common Issues to Check

1. **Script Paths**: Verify no "Script not found" errors
2. **Scene References**: Check all preloaded scenes exist
3. **Class Names**: Ensure HexGrid and HexArena work (no more 3D suffix)
4. **Import Paths**: Confirm all res:// paths are correct

## Project Configuration Issue

**Important**: The project.godot file needs updating:
```ini
run/main_scene=""  # Currently empty
```
Should be set to one of:
- `"res://game/MainGame.tscn"`
- `"res://ui/menus/SplashScreen.tscn"`

## Running Full Test Suite

1. Start with `TestCombatCollision.tscn` - most comprehensive
2. Test `HexArenaGameplay.tscn` for movement/arena
3. Run `MainGame.tscn` for full game flow
4. Check `SplashScreen.tscn` for menu system

## Console Output
Watch the Godot console for:
- Any script errors
- Missing resource warnings
- Null reference exceptions
- Performance warnings

If all tests pass without errors, the refactoring is successful!