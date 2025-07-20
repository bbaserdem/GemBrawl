# 2-Hour Circular Dependency Refactor Plan

## Goal
Fix circular dependencies and restore type safety with minimal changes. Focus on the critical Player system only.

## Approach
Use a lightweight interface pattern - just enough to break the circular dependencies without over-engineering.

## Timeline

### 0:00-0:15 - Setup (15 min)
1. Create `gembrawl/interfaces/` directory
2. Create single `IPlayer.gd` interface with essential methods
3. Create git branch `refactor/circular-deps-quick`

### 0:15-0:45 - Player System Core (30 min)
1. Update `PlayerCharacter.gd`:
   - Implement IPlayer interface
   - Keep component preloads (they're fine one-way)
   - Pass `self as IPlayer` to components

2. Update all 4 components:
   - Change `var player` to `var player: IPlayer`
   - Change `get_parent()` to use injected reference
   - Update initialization to accept IPlayer

### 0:45-1:15 - External References (30 min)
1. Quick-fix external systems:
   - SpawnManager: Change `Player3D` to `IPlayer`
   - CombatManager: Update signal types
   - Skill classes: Change owner type to IPlayer

### 1:15-1:30 - Arena Integration (15 min)
1. Create simple arena access:
   - Add arena reference to IPlayer interface
   - Set arena on PlayerCharacter during _ready()
   - Components access arena through player.get_arena()

### 1:30-1:45 - Testing (15 min)
1. Launch game
2. Test player movement
3. Test combat
4. Test skill usage
5. Fix any runtime errors

### 1:45-2:00 - Cleanup & Commit (15 min)
1. Remove any debug prints
2. Quick code review
3. Commit changes
4. Document any remaining issues

## Key Code Changes

### 1. Minimal IPlayer Interface
```gdscript
# gembrawl/interfaces/IPlayer.gd
class_name IPlayer
extends Resource

# Essential methods only
func get_global_position() -> Vector3:
    return Vector3.ZERO

func get_stats() -> Node:
    return null

func get_combat() -> Node:
    return null

func get_arena() -> Node:
    return null

func take_damage(amount: int, source: Node) -> void:
    pass
```

### 2. PlayerCharacter Change
```gdscript
# In PlayerCharacter._ready()
func _ready():
    # ... existing code ...
    
    # Initialize components with interface
    if movement:
        movement.player = self as IPlayer
    if combat:
        combat.player = self as IPlayer
    # etc...
```

### 3. Component Change Example
```gdscript
# PlayerMovement.gd
extends Node2D

# OLD: var player
# NEW:
var player: IPlayer

# Remove get_parent() calls, use player directly
```

## What We're NOT Doing
- No service locator (overkill for now)
- No component factory (unnecessary)
- No major architectural changes
- No comprehensive testing suite

## Success Criteria
✅ No circular dependency errors
✅ Type annotations work (`var player: IPlayer`)
✅ Game runs without crashes
✅ IDE autocomplete restored

## Rollback Plan
If something goes wrong:
```bash
git checkout main
git branch -D refactor/circular-deps-quick
```

## Start Commands
```bash
git checkout -b refactor/circular-deps-quick
mkdir -p gembrawl/interfaces
```

Let's start!