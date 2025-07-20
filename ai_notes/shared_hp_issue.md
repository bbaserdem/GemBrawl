# Shared Health Pool Issue - GemResource Architecture

## Problem Description

The current implementation has a critical architectural flaw where player health is stored in the shared `GemResource` class, which extends Godot's `Resource` type. Resources in Godot are shared instances by default, meaning all players using the same gem type would share the same health pool.

### Current Implementation

```gdscript
# In /gembrawl/characters/data/classes/GemResource.gd
class_name GemResource
extends Resource

## Combat stats
@export var max_health: int = 100
@export var current_health: int = 100  # <-- PROBLEM: Runtime state in shared resource
```

### Why This Is a Problem

1. **Shared State**: When multiple players select the same gem type (e.g., two players both choose Ruby), they reference the same `ruby.tres` resource instance
2. **Unintended Damage Sharing**: When one player takes damage, `gem_data.take_damage()` modifies the shared `current_health`, affecting ALL players using that gem
3. **Resource Misuse**: Resources are meant to be data templates/definitions, not runtime state holders

### Current Workaround

The issue is currently masked because:
- The test scene assigns different gem types to each player
- Single-player testing doesn't reveal the shared state problem
- But this would immediately break in:
  - Multiplayer scenarios
  - Multiple AI players using the same gem
  - Any game mode where players can choose duplicate gems

## Proposed Solution

### 1. Refactor GemResource to be Template-Only

```gdscript
# GemResource should only contain static/template data
class_name GemResource
extends Resource

## Combat stats templates
@export var max_health: int = 100  # Keep as template value
# Remove current_health - this is runtime state
@export var base_damage: int = 10
@export var defense: int = 5
# ... other static properties
```

### 2. Move Runtime State to Player Components

Option A - In PlayerStats component:
```gdscript
# PlayerStats.gd
class_name PlayerStats
extends Node

@export var gem_data: GemResource
var current_health: int = 100  # Instance variable, not shared
var max_health: int = 100

func _ready():
    if gem_data:
        max_health = gem_data.max_health
        current_health = max_health
```

Option B - In PlayerCombat component:
```gdscript
# PlayerCombat.gd
var current_health: int  # Separate from resource
var max_health: int

func setup_from_gem(gem: GemResource):
    max_health = gem.max_health
    current_health = max_health
```

### 3. Update Damage System References

All references to `gem_data.current_health` and `gem_data.take_damage()` need to be updated to use the instance variables instead.

## Implementation Steps

1. **Create instance health tracking** in either PlayerStats or PlayerCombat
2. **Update GemResource** to remove current_health and take_damage()
3. **Update all damage calculations** to use instance health
4. **Update UI/health bar references** to use instance health
5. **Test with multiple players** using the same gem type
6. **Update save/load system** if it relies on resource state

## Files That Need Changes

- `/gembrawl/characters/data/classes/GemResource.gd` - Remove runtime state
- `/gembrawl/characters/components/PlayerStats.gd` - Add health tracking
- `/gembrawl/characters/components/PlayerCombat.gd` - Update damage handling
- `/gembrawl/ui/CombatUI.gd` - Update health display references
- Any save/load system that might serialize gem resources

## Testing After Fix

1. Create a test with 2+ players using the same gem type
2. Verify damage to one player doesn't affect others
3. Test gem switching (if implemented) preserves correct health
4. Verify UI updates correctly for each player independently

## Note

This is a high-priority fix as it's a fundamental architectural issue that will cause major bugs in any multiplayer or multi-character scenario. The current single-player test masks the problem but doesn't solve it.