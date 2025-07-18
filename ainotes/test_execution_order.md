# GemBrawl Test Execution Order

## Tests to Run First (Should Work)

### 1. **TestHex.tscn** - Start Here! ✅
- Tests the HexGrid utility class which is fully implemented
- No dependencies on other game systems
- Good for verifying basic hex math works

### 2. **TestCombat.tscn** - Run Second ✅
- Tests DamageSystem which is fully implemented
- Tests basic player health/damage without complex dependencies
- May need to check if it depends on missing UI elements

### 3. **HexArenaGameplay.tscn** - Run Third ✅
- Tests HexArena generation and player movement
- Both HexArena and PlayerCharacter are implemented
- Should work but may have missing asset warnings

## Tests That May Have Issues

### 4. **TestCombatCollision.tscn** ⚠️
- Depends on skill system (AoeAttack, Projectile, MeleeHitbox)
- Check if these skill scripts have implementation
- May fail if skills aren't implemented

### 5. **Combat subfolder tests** ⚠️
- TestAOE.tscn
- TestMeleeHitbox.tscn  
- TestProjectile.tscn
- These depend on skill implementations

## Before Running Tests

1. **Check for missing globals:**
   ```bash
   # The project needs these autoloads configured:
   - CombatManager
   - GameState
   - AudioManager
   - MatchConfig
   - SceneLoader
   ```

2. **Common missing dependencies:**
   - UI scenes (HealthBar.tscn, DamageNumber.tscn)
   - Skill implementations
   - Audio files
   - 3D models/meshes

## Quick Test Commands

```bash
# Run from project root
cd gembrawl

# Test 1: Basic hex grid
godot --path . tests/TestHex.tscn

# Test 2: Damage system
godot --path . tests/TestCombat.tscn

# Test 3: Full gameplay
godot --path . tests/HexArenaGameplay.tscn
```

## Expected Results

- **TestHex**: Should show hex grid visualization
- **TestCombat**: Should show damage being applied with console output
- **HexArenaGameplay**: Should show 3D hex arena with moveable player

## If Tests Fail

1. Check console for specific missing dependencies
2. Verify autoloads are configured in Project Settings
3. Create stub implementations for missing components
4. Start with simpler tests first