# GemBrawl Testing Guide

This guide provides comprehensive instructions for testing the refactored GemBrawl project in Godot 4.3.

## Project Entry Points

### Main Scenes
- **MainGame.tscn** (`game/MainGame.tscn`) - Main game entry point
- **PracticeMode.tscn** (`game/PracticeMode.tscn`) - Practice mode for single player
- **LocalMultiplayerGame.tscn** (`game/LocalMultiplayerGame.tscn`) - Local multiplayer mode
- **SplashScreen.tscn** (`ui/menus/SplashScreen.tscn`) - Game splash/intro screen

### Note on Main Scene Configuration
The project.godot file references `res://scenes/hex_arena_3d_gameplay.tscn` as the main scene, but this file doesn't exist. You should update the main scene to one of the available scenes above.

## Test Scenes Directory Structure

All test scenes are located in the `tests/` directory:

```
tests/
├── TestMainCamera.tscn        # Camera angle and control test
├── TestCombatDamage.tscn      # Damage taking and health system test
├── TestCombatAttack.tscn      # Attack hitbox and collision test
├── TestArenaHex.tscn          # Hex grid functionality test
├── TestCombatSpawn.tscn       # Spawn system test
├── TestAssetsGemMesh.tscn     # Gem mesh analysis test
├── TestArenaHazards.tscn      # Arena hazards test
└── combat/
    ├── TestCombatAOE.tscn     # Area of effect attacks
    ├── TestCombatMelee.tscn   # Melee combat hitboxes
    └── TestCombatRanged.tscn  # Projectile mechanics
└── gems/
    ├── TestAssetsEmerald.tscn # Emerald gem test
    └── TestAssetsRuby.tscn    # Ruby gem test
```

## Test Scene Descriptions

### 1. TestMainCamera.tscn
**Purpose**: Tests camera angles and controls
**What it tests**:
- Hex-based movement system
- Arena boundaries and fall zones
- Player spawning on hex tiles
- Camera following mechanics
- Basic gameplay loop

**How to run**:
1. Open the scene in Godot
2. Press F6 or click "Play Scene"
3. Use WASD/Arrow keys to move
4. Test falling off edges and respawning

### 2. TestCombatDamage.tscn
**Purpose**: Tests damage taking and health system
**What it tests**:
- Damage system (physical, magical, true, elemental damage types)
- Health and lives system
- Player defeat and respawn mechanics
- Damage feedback and UI updates

**Controls**:
- **Spacebar**: Apply test damage (cycles through damage types)
- **K**: Instant kill test
- **R**: Manual respawn
- **WASD/Arrows**: Movement

**How to run**:
1. Open the scene and press F6
2. Watch the debug UI panel for health/lives/status
3. Test different damage types and observe the console output
4. Test death and respawn mechanics

### 3. TestCombatAttack.tscn
**Purpose**: Tests attack hitboxes and collision detection
**What it tests**:
- Melee attack hitboxes
- Projectile physics and collision
- Area of Effect (AoE) attacks
- Multi-player combat interactions
- Combat UI with health bars

**Controls**:
- **Enter/X Button**: Melee Attack
- **Q/Square**: Fire Projectile
- **E/Circle**: AoE Attack
- **Tab**: Switch Player Control
- **WASD/Arrows/Left Stick**: Move Player
- **Space/A Button**: Jump

**Camera Controls**:
- **Mouse Wheel**: Zoom In/Out
- **Q/E Keys**: Rotate Camera
- **Page Up/Down**: Tilt Camera

**How to run**:
1. Open the scene and press F6
2. Two players spawn on opposite sides of the hex arena
3. Use Tab to switch control between players
4. Test combat between players
5. Observe hit detection and damage numbers

### 4. TestArenaHex.tscn
**Purpose**: Tests hexagonal grid system
**What it tests**:
- Hex coordinate system
- Hex-to-world position conversion
- Grid-based movement
- Tile interactions

**How to run**:
1. Open the scene and press F6
2. Test movement on hex grid
3. Verify proper hex snapping and transitions

### 5. Combat Test Scenes (in `tests/combat/`)

These are component scenes used by TestCombatCollision.tscn:

- **TestCombatAOE.tscn**: Area attack visual and collision component
- **TestCombatMelee.tscn**: Melee attack hitbox component
- **TestCombatRanged.tscn**: Projectile physics component

These scenes are not meant to be run directly but are instantiated by the test controllers.

## Running Tests in Godot

### Method 1: Run Individual Test Scenes
1. Open Godot and load the GemBrawl project
2. In the FileSystem dock, navigate to `tests/`
3. Double-click on a test scene to open it
4. Press **F6** or click the "Play Scene" button (film clapper icon)
5. Use the controls listed above for each scene

### Method 2: Set as Main Scene (Temporary)
1. Right-click on a test scene in the FileSystem
2. Select "Set as Main Scene"
3. Press **F5** or click "Play" to run the project
4. Remember to change it back when done testing

### Method 3: Quick Run from Editor
1. With a test scene open in the editor
2. Click the "Play Scene" button in the toolbar
3. Or use the keyboard shortcut **F6**

## Common Testing Workflows

### Testing Combat Mechanics
1. Start with `TestCombatDamage.tscn` to verify basic damage/health systems
2. Move to `TestCombatAttack.tscn` for full combat testing
3. Test different attack types and observe damage calculations
4. Verify hitbox accuracy and collision detection

### Testing Movement and Arena
1. Use `TestArenaHex.tscn` for hex-based movement
2. Test arena boundaries and fall detection
3. Verify spawn points work correctly
4. Test camera following and controls

### Testing Multiplayer Interactions
1. Use `TestCombatAttack.tscn` with Tab to switch players
2. Test combat between multiple players
3. Verify damage is applied correctly to targets
4. Check that UI updates for both players

## Debug Information

Most test scenes include debug UI panels that show:
- Player health and lives
- Current status (alive, defeated, respawning)
- Last combat action
- Control instructions

Check the console output (bottom panel in Godot) for detailed logs about:
- Damage calculations
- Hit detection
- State changes
- Error messages

## Troubleshooting

### Scene Won't Run
- Ensure all dependencies are present (check for missing scripts in red)
- Verify the scene has a root node
- Check console for error messages

### Player Not Moving
- Verify input mappings in Project Settings > Input Map
- Check if the player is in spectator mode
- Ensure player has spawned correctly

### Combat Not Working
- Check collision layers in Project Settings
- Verify combat scripts are attached
- Look for errors in the console
- Ensure CombatManager is present in the scene

### Missing Main Scene Error
Update the main scene in Project Settings:
1. Go to Project > Project Settings
2. Under Application > Run, set Main Scene to `game/MainGame.tscn`
3. Save and restart Godot if needed

## Performance Testing

When testing, monitor:
- FPS counter (enable in Project Settings > Debug > Settings)
- Memory usage in the Profiler
- Number of collision checks in the debugger
- Draw calls for rendering optimization

## Next Steps

After testing individual components:
1. Test the full game flow from `MainGame.tscn`
2. Try local multiplayer with `LocalMultiplayerGame.tscn`
3. Test menu navigation starting from `SplashScreen.tscn`
4. Create custom test scenarios as needed