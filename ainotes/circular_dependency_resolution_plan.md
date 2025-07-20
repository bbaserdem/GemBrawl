# Circular Dependency Resolution Plan

## Current Issue
The arena branch introduced a workaround for circular dependencies by removing type annotations and using const preloads. While this makes the code compile, it sacrifices type safety and IDE support.

## Affected Files
- `PlayerCharacter.gd` - References player components
- `PlayerMovement.gd` - References PlayerCharacter and HexArena
- `PlayerCombat.gd` - References PlayerCharacter and DamageSystem
- `PlayerStats.gd` - References PlayerCharacter
- `PlayerInput.gd` - References PlayerCharacter
- `HexArena.gd` - References HexGrid and other arena components
- `HexGrid.gd` - Self-reference issue

## Current Workaround (Arena Branch)
```gdscript
# Instead of typed references:
var player: Player3D  # Causes circular dependency

# Using untyped with const preload:
const Player3D = preload("res://characters/PlayerCharacter.gd")
var player  # No type annotation
```

## Proposed Solutions

### 1. Interface-Based Approach
Create interface scripts that define the public API without implementation:
```gdscript
# IPlayer.gd - Interface defining player contract
class_name IPlayer
extends RefCounted

func get_health() -> int:
    assert(false, "Interface method must be implemented")
    return 0
```

### 2. Component Registry Pattern
Use a central registry to manage component references:
```gdscript
# ComponentRegistry.gd - Singleton
extends Node

var registered_components = {}

func register_component(player_id: int, component_name: String, component: Node):
    # Store component references centrally
```

### 3. Reorganize Architecture
- Move shared types to a separate module
- Use signals/events for component communication
- Implement dependency injection pattern

### 4. Duck Typing with Documentation
Keep untyped but add comprehensive documentation:
```gdscript
## References the parent Player3D node
## @type Player3D
var player  # Untyped but documented
```

## Implementation Plan
1. Complete current merge with arena's workaround
2. Create interface definitions for major classes
3. Gradually migrate components to use interfaces
4. Add unit tests to ensure type contracts are maintained
5. Document the new architecture pattern

## Benefits of Proper Resolution
- Restore type safety and IDE autocomplete
- Improve code maintainability
- Enable better refactoring support
- Reduce runtime errors from type mismatches

## Timeline
- Phase 1: Complete merge (current)
- Phase 2: Design interfaces (next sprint)
- Phase 3: Migrate components (following sprint)
- Phase 4: Documentation and testing