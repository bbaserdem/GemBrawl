# TestAssetsGems Crash Investigation

## Problem Summary
The TestAssetsGems.tscn scene crashes with signal 11 (SIGSEGV - Segmentation Fault) when trying to display multiple gem types with their custom shaders.

## Key Findings

### 1. The crash occurs AFTER all three PlayerCharacter instances are successfully initialized
- All three gems complete their `_ready()` functions
- Combat layers are set up
- Arena is found
- Components are initialized
- Gem properties are applied

### 2. What we've ruled out:
- **NOT the outline shader**: Crash still happens with shader disabled
- **NOT async/await operations**: Removed all async code, still crashes
- **NOT CombatManager syntax error**: Fixed the `pass` statement issue
- **NOT missing CombatLayers**: It's a static class, calls work fine
- **NOT the arena reference**: Arena is found successfully

### 3. Crash characteristics:
- Happens after all PlayerCharacters are spawned
- Occurs during scene tree operations (based on backtrace)
- TestAssetsGemsSimple.tscn (single gem, no loops) works fine
- TestMinimal.tscn works fine

### 4. Current state of files:

#### TestAssetsGemsController.gd
- Removed all `await` statements
- Spawns all gems immediately in a loop
- Sets gem data directly without waiting

#### PlayerCharacter.gd
- Fixed arena path lookups to check multiple locations
- All components initialize successfully
- Outline shader re-enabled (not the cause)

#### CombatManager.gd
- Fixed syntax error (removed `pass` before code)

#### outlined_gem.gdshader
- Updated to use safer vertex transformation
- Added proper render modes for shadow support
- Works in TestAssetsGemsSimple scene

## Suspected Issues

The crash happens after all gems are spawned, suggesting:
1. **Memory/Resource issue**: Three PlayerCharacters with complex component systems might be overwhelming something
2. **Scene tree corruption**: Multiple rapid additions to scene tree
3. **Godot 4.3 nixpkgs build issue**: Specific to this Godot build
4. **Hidden dependency**: Something in the full scene setup that doesn't exist in the simple test

## Next Steps for New Chat

1. Try spawning gems with a Timer node instead of in _ready
2. Check if crash happens with 1 or 2 gems instead of 3
3. Create minimal PlayerCharacter without components
4. Test on different Godot build if possible
5. Use Godot debugger/editor instead of headless mode

## Working Test Scene
TestAssetsGemsSimple.tscn works correctly - spawns single gem without crash.