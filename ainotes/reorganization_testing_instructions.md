# GemBrawl Reorganization Testing Instructions

## Overview
This document provides instructions for testing the reorganized GemBrawl codebase to ensure all systems work correctly after the refactoring.

## Pre-Testing Checklist

1. **Fix Main Scene Reference**
   - Open Project Settings → Application → Run
   - Change Main Scene from `res://scenes/hex_arena_3d_gameplay.tscn` (doesn't exist)
   - Set to: `res://game/MainGame.tscn`

2. **Verify Autoloads**
   - Check Project Settings → Autoload
   - Ensure these singletons are loaded:
     - GameState
     - AudioManager
     - MatchConfig
     - SceneLoader
     - CombatManager

3. **Check Input Mappings**
   - Verify all input actions exist in Project Settings → Input Map
   - Required actions: move_left, move_right, move_forward, move_back, jump, attack, skill_1, skill_2, skill_3

## System-by-System Testing

### 1. Arena System Testing

**Test Files**: `tests/HexArenaGameplay.tscn`, `tests/TestHex.tscn`

**What to Test**:
- [ ] Hex grid generation creates proper floor tiles
- [ ] Hazard tiles spawn with red emission
- [ ] Spawn points are created at correct positions
- [ ] Fall zones work (player falls and respawns)
- [ ] Arena boundaries prevent movement beyond edges

**Test Steps**:
1. Open `HexArenaGameplay.tscn` and run (F6)
2. Move around with WASD/Arrows
3. Try to move off the edge - should fall and respawn
4. Walk over red hazard tiles - should take damage
5. Verify hex-snapped movement feels correct

### 2. Character System Testing

**Test Files**: `tests/TestCombat.tscn`, `tests/TestCombatCollision.tscn`

**What to Test**:
- [ ] Player spawns with correct gem data
- [ ] Health/lives system works correctly
- [ ] Movement modes (free vs hex-snapped) switch properly
- [ ] Camera follows player correctly
- [ ] Spectator mode activates when out of lives

**Test Steps**:
1. Run `TestCombat.tscn`
2. Press Spacebar repeatedly to take damage
3. Press K to test instant death
4. Press R to respawn
5. Verify health bar updates and damage numbers appear
6. Die 3 times to test spectator mode

### 3. Combat System Testing

**Test Files**: `tests/TestCombatCollision.tscn`, `tests/combat/` subfolder scenes

**What to Test**:
- [ ] Melee attacks hit targets (Enter key)
- [ ] Projectiles fly and collide (Q key)
- [ ] AoE attacks damage area (E key)
- [ ] Damage types calculate correctly
- [ ] Elemental effectiveness (Ruby > Sapphire > Emerald > Ruby)
- [ ] Critical hits occur (~10% chance)
- [ ] Combat layers prevent friendly fire

**Test Steps**:
1. Run `TestCombatCollision.tscn`
2. Use Tab to switch between Player 1 and Player 2
3. Position players near each other
4. Test each attack type:
   - Enter: Melee attack (close range)
   - Q: Shoot projectile
   - E: AoE blast
5. Watch console for damage calculations
6. Verify damage numbers appear on hit

### 4. Skill System Testing

**Test Files**: `tests/TestCombatCollision.tscn`

**What to Test**:
- [ ] Skills have cooldowns
- [ ] Visual effects spawn correctly
- [ ] Skills consume resources (if applicable)
- [ ] Each skill type works (Cut, Polish, Shine)

**Test Steps**:
1. In TestCombatCollision scene
2. Try rapid attacks - verify cooldown prevents spam
3. Check that each skill has unique behavior
4. Verify particle effects and visuals

### 5. UI System Testing

**Test Files**: All test scenes with UI

**What to Test**:
- [ ] Health bars update correctly
- [ ] Damage numbers appear and fade
- [ ] UI scales properly at different resolutions
- [ ] Combat feedback is clear

**Test Steps**:
1. Run any combat test scene
2. Take damage and verify health bar decreases
3. Deal damage and see damage numbers
4. Resize game window - UI should scale

### 6. Multiplayer System Testing

**Test Files**: `game/LocalMultiplayerGame.tscn`

**What to Test**:
- [ ] Multiple players can join
- [ ] Each player controls independently
- [ ] Combat between players works
- [ ] Winner detection functions

**Test Steps**:
1. Run LocalMultiplayerGame.tscn
2. Use Tab or controller to add players
3. Test combat between players
4. Play until one player wins

## Integration Testing

### Full Game Flow Test
1. Start from `ui/menus/SplashScreen.tscn`
2. Navigate through menus
3. Start a local multiplayer game
4. Select characters/gems
5. Choose arena
6. Play a full match
7. Return to menu

### Performance Testing
1. Enable FPS counter (Project Settings → Debug → Settings → Show FPS)
2. Run `HexArenaGameplay.tscn`
3. Spawn multiple projectiles (spam Q key)
4. Monitor FPS - should stay above 60
5. Check Profiler for performance bottlenecks

## Common Issues and Solutions

### Issue: Player won't move
- Check input mappings exist
- Verify CharacterBody3D has movement script
- Check if player is in spectator mode

### Issue: Combat doesn't work
- Verify CombatManager singleton is loaded
- Check collision layers are set correctly
- Ensure hitboxes have proper collision shapes

### Issue: Scene crashes on load
- Check for missing node references
- Verify all .tres resources exist
- Look for circular dependencies

### Issue: UI not showing
- Check CanvasLayer nodes exist
- Verify UI scenes are instantiated
- Check theme resources are assigned

## Regression Testing Checklist

After any code changes, test these critical paths:

- [ ] Player can spawn and move
- [ ] Basic attacks work
- [ ] Taking damage reduces health
- [ ] Death and respawn work
- [ ] UI updates correctly
- [ ] No console errors during gameplay
- [ ] Performance remains stable

## Automated Testing (Future)

Consider implementing GUT (Godot Unit Test) for:
- Damage calculations
- Hex grid mathematics
- State machine transitions
- Input handling

## Debug Commands

Add these to help testing:

```gdscript
# In Player script
if OS.is_debug_build():
    if Input.is_action_just_pressed("debug_heal"):
        current_health = max_health
    if Input.is_action_just_pressed("debug_damage"):
        take_damage(10)
    if Input.is_action_just_pressed("debug_teleport"):
        global_position = Vector3.ZERO
```

## Conclusion

Complete all test scenarios above to ensure the reorganization hasn't broken any functionality. Pay special attention to:
1. Scene loading and transitions
2. Signal connections between systems
3. Resource loading (.tres files)
4. Singleton access patterns

Report any issues found during testing with:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Console errors (if any)