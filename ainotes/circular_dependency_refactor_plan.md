# GemBrawl Circular Dependency Refactor Plan

## Executive Summary
This document outlines a comprehensive plan to resolve circular dependencies in the GemBrawl codebase while maintaining type safety and improving architecture.

## Current State Analysis

### Core Issues
1. **Bidirectional Dependencies**: PlayerCharacter ↔ Components create circular references
2. **Lost Type Safety**: Using untyped `var player` instead of `var player: Player3D`
3. **Runtime Dependencies**: Fragile node path lookups (`get_node_or_null("/root/Main/HexArena")`)
4. **Inconsistent Loading**: Mix of preloads and runtime lookups

### Affected Systems
- Player system (PlayerCharacter + 4 components)
- Arena system (HexArena, HexGrid)
- Combat system (CombatManager, SpawnManager)
- Skill system (all skill classes)

## Proposed Architecture

### 1. Interface-Based Design
Create contracts that define public APIs without implementation dependencies:

```gdscript
# interfaces/IPlayer.gd
class_name IPlayer
extends Resource

signal health_changed(new_health: int)
signal died()

func get_position() -> Vector3:
    push_error("IPlayer.get_position() must be implemented")
    return Vector3.ZERO

func take_damage(amount: int, source: Node) -> void:
    push_error("IPlayer.take_damage() must be implemented")
```

### 2. Component Communication Pattern
Replace direct parent references with:
- **Signals** for events
- **Interfaces** for contracts
- **Dependency Injection** for required services

### 3. Service Locator Pattern
For global systems like Arena:
```gdscript
# singletons/ServiceLocator.gd
extends Node

var arena_service: IArena
var combat_service: ICombat

func register_arena(arena: IArena) -> void:
    arena_service = arena
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Create infrastructure without breaking existing code

1. **Create Interface Layer**
   - [ ] Create `interfaces/` directory
   - [ ] Define IPlayer interface
   - [ ] Define IPlayerComponent interface
   - [ ] Define IArena interface
   - [ ] Define ICombat interface

2. **Create Service Locator**
   - [ ] Implement ServiceLocator singleton
   - [ ] Add registration methods
   - [ ] Add service discovery methods

3. **Create Base Classes**
   - [ ] PlayerComponentBase that implements IPlayerComponent
   - [ ] Abstract common component logic

### Phase 2: Player System Refactor (Week 2)
**Goal**: Decouple PlayerCharacter from components

1. **Refactor PlayerCharacter**
   - [ ] Implement IPlayer interface
   - [ ] Replace direct component creation with factory pattern
   - [ ] Use signals for component communication
   - [ ] Register with ServiceLocator

2. **Refactor Components**
   - [ ] PlayerMovement: Remove parent type dependency
   - [ ] PlayerCombat: Use IPlayer interface
   - [ ] PlayerStats: Use signals for health updates
   - [ ] PlayerInput: Decouple from PlayerCharacter

3. **Component Communication**
   - [ ] Replace `get_parent()` with injected player reference
   - [ ] Use signals for all inter-component communication
   - [ ] Type all references as IPlayer instead of Player3D

### Phase 3: Arena System Refactor (Week 3)
**Goal**: Decouple arena dependencies

1. **Refactor HexArena**
   - [ ] Implement IArena interface
   - [ ] Register with ServiceLocator
   - [ ] Remove direct HexGrid preload

2. **Refactor HexGrid**
   - [ ] Make HexGrid standalone
   - [ ] Use signals for arena communication

3. **Update Player-Arena Integration**
   - [ ] Use ServiceLocator for arena access
   - [ ] Remove hardcoded node paths

### Phase 4: External Systems (Week 4)
**Goal**: Update all external references

1. **Combat System**
   - [ ] Update SpawnManager to use IPlayer
   - [ ] Update CombatManager signals
   - [ ] Fix DamageSystem references

2. **Skill System**
   - [ ] Update all skills to use IPlayer
   - [ ] Remove Player3D type dependencies
   - [ ] Use interface-based owner references

### Phase 5: Testing & Documentation (Week 5)
**Goal**: Ensure stability and maintainability

1. **Testing**
   - [ ] Unit tests for each interface
   - [ ] Integration tests for component communication
   - [ ] Performance testing

2. **Documentation**
   - [ ] Architecture documentation
   - [ ] Migration guide for future components
   - [ ] Code examples

## Migration Strategy

### Step-by-Step Component Migration
Example for PlayerMovement:

```gdscript
# OLD: PlayerMovement.gd
extends Node2D

var player  # Untyped to avoid circular dependency

func _ready():
    player = get_parent()

# NEW: PlayerMovement.gd
extends PlayerComponentBase

var _player: IPlayer  # Typed interface reference

func initialize(player: IPlayer) -> void:
    _player = player
    # Connect to player signals
    _player.health_changed.connect(_on_player_health_changed)
```

### Gradual Migration Path
1. Add interfaces alongside existing code
2. Update one component at a time
3. Maintain backward compatibility during transition
4. Remove old code only after full migration

## Risk Mitigation

### High-Risk Areas
1. **Component Initialization Order**: Components depend on each other
   - **Mitigation**: Use deferred initialization
   
2. **Save System Compatibility**: Existing saves might break
   - **Mitigation**: Version save files, provide migration

3. **Performance Impact**: Additional abstraction layers
   - **Mitigation**: Profile critical paths, optimize as needed

### Rollback Plan
- Tag release before refactor
- Keep old implementation in `legacy/` folder
- Feature flag for new vs old system

## Success Metrics
- ✅ All type annotations restored
- ✅ No circular dependency warnings
- ✅ IDE autocomplete fully functional
- ✅ Zero runtime type errors
- ✅ Improved code navigation
- ✅ Easier unit testing

## Next Steps
1. Review and approve this plan
2. Create feature branch: `refactor/circular-dependencies`
3. Begin Phase 1 implementation
4. Weekly progress reviews

## Code Examples

### Before (Current State)
```gdscript
# Circular dependency, loses type safety
const PlayerCharacter = preload("res://characters/PlayerCharacter.gd")
var player  # Untyped
```

### After (Target State)
```gdscript
# Clean dependency, maintains type safety
var player: IPlayer  # Typed interface
```

### Component Factory Pattern
```gdscript
# PlayerComponentFactory.gd
class_name PlayerComponentFactory
extends Resource

static func create_movement(player: IPlayer) -> PlayerMovement:
    var movement = PlayerMovement.new()
    movement.initialize(player)
    return movement
```

## Timeline Summary
- **Week 1**: Foundation (Interfaces, ServiceLocator)
- **Week 2**: Player System
- **Week 3**: Arena System
- **Week 4**: External Systems
- **Week 5**: Testing & Documentation
- **Total Duration**: 5 weeks

## Notes
- Prioritize maintaining game functionality throughout refactor
- Each phase should be independently testable
- Consider creating automated migration scripts where possible