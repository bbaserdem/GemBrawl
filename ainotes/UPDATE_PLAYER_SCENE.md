# PlayerCharacter Scene Update Guide

The PlayerCharacter.gd script has been refactored into a component-based architecture for better maintainability. You'll need to update your PlayerCharacter.tscn scene file to add the required component nodes.

## Required Changes

Add these child nodes to your PlayerCharacter node in the scene:

1. **Movement** (Node)
   - Script: `res://characters/components/PlayerMovement.gd`
   
2. **Combat** (Node)
   - Script: `res://characters/components/PlayerCombat.gd`
   
3. **Stats** (Node)
   - Script: `res://characters/components/PlayerStats.gd`
   
4. **Input** (Node)
   - Script: `res://characters/components/PlayerInput.gd`

## Scene Structure

Your scene hierarchy should look like this:

```
PlayerCharacter (CharacterBody3D)
├── Movement (Node)
├── Combat (Node)
├── Stats (Node)
├── Input (Node)
├── MeshInstance3D
├── CollisionShape3D
└── DirectionArrow (Node3D)
```

## Export Variables

The export variables from the original script have been distributed across components:

- **Movement component**: movement_speed, acceleration, friction, rotation_speed, jump_force, gravity, etc.
- **Combat component**: invulnerability_duration
- **Stats component**: max_lives, respawn_delay
- **Input component**: gamepad_deadzone, enable_gamepad, enable_keyboard

## Benefits of the Refactor

1. **Smaller, focused files**: Each component is under 250 lines
2. **Better organization**: Related functionality is grouped together
3. **Easier testing**: Components can be tested independently
4. **More maintainable**: Changes to one system don't affect others
5. **Reusable**: Components can potentially be used by other entities

## Migration Notes

- The public API remains the same, so existing code calling PlayerCharacter methods will continue to work
- All signals are re-exposed from components, maintaining compatibility
- The original file is backed up as `PlayerCharacter.gd.backup` if you need to reference it