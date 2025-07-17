# GemBrawl Testing Workflow

## Overview
This document provides a systematic testing workflow to verify all implemented features in GemBrawl, covering player movement, gem stats integration, damage calculation, and combat collision detection.

## Prerequisites
- Godot 4.3 installed and configured
- Project loaded in Godot editor
- Terminal access for running test commands

## Test Scenes Available
1. `test_hex_3d.tscn` - Basic hex grid and player movement
2. `test_movement.tscn` - Player movement on hex arena
3. `test_combat_collision.tscn` - Complete combat system testing
4. `test_combat.tscn` - Combat mechanics testing

---

## 1. Basic Movement and Hex Grid Test

### Scene: `test_hex_3d.tscn`
```bash
godot --scene res://scenes/test_hex_3d.tscn
```

#### What to Test:
- [ ] Player spawns on hex grid
- [ ] WASD/Arrow keys move player correctly
- [ ] Player aligns with hex tiles (if snap enabled)
- [ ] Jump functionality (Space bar)
- [ ] Camera follows player
- [ ] Player respects arena boundaries

#### Expected Behavior:
- Smooth movement across hex tiles
- Player stays within valid hex areas
- No collision issues with arena edges

---

## 2. Gem Stats Integration Test

### Scene: `test_movement.tscn` or `test_hex_3d.tscn`

#### Setup:
1. Open the scene in Godot editor
2. Select the Player node
3. In Inspector, verify Gem Data is assigned (test_gem.tres)

#### What to Test:
- [ ] Player visual matches gem color (Ruby = red, Sapphire = blue, etc.)
- [ ] Movement speed reflects gem stats
- [ ] Health values match gem configuration
- [ ] Defense stats are properly loaded

#### Verification Steps:
1. Check player mesh color matches gem
2. Time movement across fixed distance
3. Print gem stats to console:
   ```gdscript
   # Add to player _ready():
   print("Gem: ", gem_data.gem_name)
   print("Health: ", gem_data.max_health)
   print("Speed: ", gem_data.movement_speed)
   print("Defense: ", gem_data.defense)
   ```

---

## 3. Combat Collision Detection Test

### Scene: `test_combat_collision.tscn`
```bash
godot --scene res://scenes/test_combat_collision.tscn
```

#### Controls:
- **Movement**: WASD/Arrows or Left Stick
- **Jump**: Space or A Button
- **Melee Attack**: Enter or X Button
- **Projectile**: Q or Square Button
- **AoE Attack**: E or Circle Button
- **Switch Player**: Tab
- **Camera**: Mouse wheel zoom, Middle mouse pan, Q/E rotate

#### Test Checklist:

##### A. Melee Combat
- [ ] Press Enter to perform melee attack
- [ ] Hitbox appears in front of player (brief flash)
- [ ] Other players take damage when hit
- [ ] Damage numbers appear above hit targets
- [ ] Knockback effect pushes target
- [ ] Can't hit same target multiple times per attack
- [ ] Self-damage is prevented

##### B. Projectile Combat
- [ ] Press Q to fire projectile
- [ ] Projectile travels in facing direction
- [ ] Projectile hits other players
- [ ] Damage applied on hit
- [ ] Projectile destroyed on impact
- [ ] Projectile has limited lifetime

##### C. AoE Combat
- [ ] Press E for area attack
- [ ] Visual effect shows damage area
- [ ] All players in area take damage
- [ ] Different shapes work (sphere default)
- [ ] Single damage instance per target

##### D. Damage System
- [ ] Damage numbers show correct values
- [ ] Critical hits show different color/size
- [ ] Defense reduces damage appropriately
- [ ] Different damage types work (physical/magical)
- [ ] Health bars update correctly

##### E. Player State
- [ ] Players flash when taking damage (invulnerability)
- [ ] Players can't be damaged while invulnerable
- [ ] Health decreases correctly
- [ ] Death state triggers at 0 HP (if implemented)

---

## 4. Combat Manager Verification

### In Any Combat Scene:

#### What to Test:
- [ ] Hit registration logs to console
- [ ] Combo system tracks multiple hits
- [ ] Combat events fire correctly
- [ ] No friendly fire (if disabled)

#### Console Output to Verify:
```
Combat Hit: Player1 hit Player2 for 20 damage (PHYSICAL)
Player 2 health: 80/100
Combo achieved: 3 hits!
```

---

## 5. Performance and Stability Tests

### All Scenes:

#### What to Test:
- [ ] No errors in console during normal gameplay
- [ ] Stable 60 FPS during combat
- [ ] No memory leaks (monitor in Godot profiler)
- [ ] Collision detection remains accurate under stress
- [ ] Multiple simultaneous attacks work correctly

#### Stress Test:
1. Tab between players rapidly
2. Spam all attack types
3. Have multiple projectiles active
4. Overlap multiple AoE attacks

---

## 6. Integration Test Workflow

### Complete System Test:
1. Start `test_combat_collision.tscn`
2. Move Player 1 near Player 2
3. Perform melee attack → Verify damage
4. Back away and fire projectile → Verify hit
5. Use AoE attack with both players in range → Verify both damaged
6. Tab to Player 2
7. Attack Player 1 → Verify bi-directional combat
8. Continue until one player reaches low health
9. Verify all visual feedback throughout

---

## 7. Debug Commands

Add these to any test scene for detailed debugging:

```gdscript
# In _ready() or _input():
if Input.is_action_just_pressed("ui_page_up"):  # Page Up key
    print("=== COMBAT DEBUG INFO ===")
    for player in get_tree().get_nodes_in_group("players"):
        print("Player ", player.name)
        print("  Health: ", player.gem_data.current_health, "/", player.gem_data.max_health)
        print("  Position: ", player.global_position)
        print("  Collision Layer: ", player.collision_layer)
        print("  Is Alive: ", player.is_alive)
```

---

## Common Issues and Solutions

### Issue: Attacks not hitting
- Check collision layers are set correctly
- Verify forward direction (-transform.basis.z)
- Ensure targets have `take_damage_info()` method

### Issue: Damage not applying
- Check damage calculation in console
- Verify gem stats are loaded
- Check invulnerability state

### Issue: Visual feedback missing
- Ensure damage_number.tscn scene exists
- Check scene is added to tree correctly
- Verify position calculations

---

## Test Completion Checklist

- [ ] All movement mechanics work correctly
- [ ] Gem stats properly affect gameplay
- [ ] All three attack types function
- [ ] Damage calculation is accurate
- [ ] Visual feedback displays properly
- [ ] No critical errors in console
- [ ] Performance is acceptable
- [ ] Collision detection is reliable

## Next Steps
Once all tests pass:
1. Document any bugs found
2. Note any performance issues
3. Prepare for Task 5.4 (Handle Death State)
4. Consider additional polish items 