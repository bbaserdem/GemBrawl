# Multi-Controller Support Implementation Plan

## Overview
This document outlines the implementation plan for local multiplayer support in GemBrawl, allowing multiple players to connect controllers and play together on the same machine.

## Current State
- The game currently only supports single player input
- PlayerInput component is hardcoded to read from controller index 0
- Input actions in project.godot are configured with device: -1 (any device)
- Player system has infrastructure for multiple players (player_id, is_local_player) but no controller assignment
- LocalMultiplayerGame.tscn exists but is empty

## Key Files to Modify
- `gembrawl/characters/components/PlayerInput.gd` - Currently hardcoded to device 0
- `gembrawl/game/LocalMultiplayerGame.tscn` - Empty scene that needs implementation
- `gembrawl/ui/menus/ControllerAssignmentScreen.tscn` - Empty scene for controller setup
- `gembrawl/project.godot` - Contains input action definitions

## Architecture Goals
- **Modular Design**: Keep input mapping separate from input handling
- **No Boilerplate**: Avoid duplicating input actions for each player
- **Single Source of Truth**: Centralize control scheme definitions
- **Hot-swappable**: Support controllers being connected/disconnected during gameplay

## Implementation Components

### 1. Input Mapping System (`InputMapping.gd`)
**NEW FILE** - Create a new singleton/resource that defines base control mappings:

```gdscript
# Location: res://gembrawl/globals/InputMapping.gd
# This is a NEW FILE to be created
extends Node

const BASE_ACTIONS = {
    "move_left": {
        "keyboard": [KEY_A, KEY_LEFT],
        "gamepad": [JOY_AXIS_LEFT_X_NEGATIVE]
    },
    "move_right": {
        "keyboard": [KEY_D, KEY_RIGHT],
        "gamepad": [JOY_AXIS_LEFT_X_POSITIVE]
    },
    "move_up": {
        "keyboard": [KEY_W, KEY_UP],
        "gamepad": [JOY_AXIS_LEFT_Y_NEGATIVE]
    },
    "move_down": {
        "keyboard": [KEY_S, KEY_DOWN],
        "gamepad": [JOY_AXIS_LEFT_Y_POSITIVE]
    },
    "use_skill": {
        "keyboard": [KEY_SPACE],
        "gamepad": [JOY_BUTTON_A]
    },
    "jump": {
        "keyboard": [KEY_SHIFT],
        "gamepad": [JOY_BUTTON_B]
    },
    # Camera controls
    "camera_left": {
        "keyboard": [KEY_Q],
        "gamepad": [JOY_AXIS_RIGHT_X_NEGATIVE]
    },
    "camera_right": {
        "keyboard": [KEY_E],
        "gamepad": [JOY_AXIS_RIGHT_X_POSITIVE]
    }
}

# Helper functions to query mappings
func get_action_mapping(action: String, device_type: String):
    if BASE_ACTIONS.has(action):
        return BASE_ACTIONS[action].get(device_type, [])
    return []
```

### 2. Controller Manager (`ControllerManager.gd`)
**NEW FILE** - Singleton to manage controller assignments:

```gdscript
# Location: res://gembrawl/globals/ControllerManager.gd
# This is a NEW FILE to be created
extends Node

signal controller_connected(device_id: int)
signal controller_disconnected(device_id: int)
signal player_joined(player_index: int, device_id: int)
signal player_left(player_index: int)

# Track controller assignments
var controller_assignments = {} # {player_index: device_id}
var available_controllers = [] # List of unassigned controller IDs
var max_players = 4

func _ready():
    Input.joy_connection_changed.connect(_on_joy_connection_changed)
    _refresh_controllers()

func _refresh_controllers():
    available_controllers.clear()
    var connected = Input.get_connected_joypads()
    for device_id in connected:
        if not _is_controller_assigned(device_id):
            available_controllers.append(device_id)

func assign_controller_to_player(player_index: int, device_id: int):
    controller_assignments[player_index] = device_id
    available_controllers.erase(device_id)
    player_joined.emit(player_index, device_id)

func get_player_device_id(player_index: int) -> int:
    return controller_assignments.get(player_index, -1)

func _is_controller_assigned(device_id: int) -> bool:
    return device_id in controller_assignments.values()
```

### 3. Modified PlayerInput Component
**MODIFY EXISTING FILE** - Update `PlayerInput.gd` to use direct device IDs:

```gdscript
# Location: res://gembrawl/characters/components/PlayerInput.gd
# This is an EXISTING FILE that needs modification
class_name PlayerInput
extends Node

@export var player_index: int = 0  # NEW: Add player index
@export var gamepad_deadzone: float = 0.15

var device_id: int = -1  # NEW: Device ID from ControllerManager
var input_mapping = preload("res://gembrawl/globals/InputMapping.gd")  # NEW: Reference to mapping

func _ready():
    # Get assigned device from ControllerManager
    var controller_manager = get_node("/root/ControllerManager")
    device_id = controller_manager.get_player_device_id(player_index)

func get_movement_input() -> Vector2:
    var input_vector = Vector2.ZERO
    
    if device_id >= 0:  # Gamepad
        input_vector.x = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
        input_vector.y = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
        
        # Apply deadzone
        if input_vector.length() < gamepad_deadzone:
            input_vector = Vector2.ZERO
    
    elif device_id == -1 and player_index == 0:  # Keyboard only for P1
        input_vector.x = Input.get_axis("move_left", "move_right")
        input_vector.y = Input.get_axis("move_up", "move_down")
    
    return input_vector.normalized() if input_vector.length() > 1.0 else input_vector

func is_action_pressed(action: String) -> bool:
    if device_id >= 0:  # Gamepad
        var mappings = input_mapping.get_action_mapping(action, "gamepad")
        for button in mappings:
            if Input.is_joy_button_pressed(device_id, button):
                return true
    elif device_id == -1 and player_index == 0:  # Keyboard
        return Input.is_action_pressed(action)
    return false
```

### 4. Local Multiplayer Manager
**NEW FILE** - Handles player spawning and management:

```gdscript
# Location: res://gembrawl/game/LocalMultiplayerManager.gd
# This is a NEW FILE to be created
extends Node

@export var player_scene: PackedScene
@export var max_local_players: int = 4

var active_players = {}  # {player_index: player_instance}

func _ready():
    var controller_manager = get_node("/root/ControllerManager")
    controller_manager.player_joined.connect(_on_player_joined)
    controller_manager.player_left.connect(_on_player_left)

func _on_player_joined(player_index: int, device_id: int):
    if player_index in active_players:
        return  # Player already exists
    
    # Spawn new player
    var player = player_scene.instantiate()
    player.player_id = player_index + 1
    player.is_local_player = true
    
    # Configure input component
    var input_component = player.get_node("Input")
    input_component.player_index = player_index
    
    # Add to scene and track
    add_child(player)
    active_players[player_index] = player
    
    # Position at spawn point
    var spawn_pos = SpawnManager.get_spawn_point(player)
    player.global_position = spawn_pos

func _on_player_left(player_index: int):
    if player_index in active_players:
        active_players[player_index].queue_free()
        active_players.erase(player_index)
```

### 5. Controller Assignment UI
**NEW FILE** - Simple "Press A to Join" screen script (the .tscn exists but is empty):

```gdscript
# Location: res://gembrawl/ui/menus/ControllerAssignmentScreen.gd
# This is a NEW FILE to be created (scene exists but needs script)
extends Control

@onready var player_slots = $PlayerSlots
var controller_manager: Node
var assigned_players = {}

func _ready():
    controller_manager = get_node("/root/ControllerManager")
    controller_manager.controller_connected.connect(_on_controller_connected)

func _input(event):
    # Check for button press on unassigned controllers
    if event is InputEventJoypadButton and event.pressed:
        if event.button_index == JOY_BUTTON_A:
            _try_assign_controller(event.device)
    
    # Player 1 can use keyboard
    if event.is_action_pressed("ui_accept") and not (0 in assigned_players):
        _assign_player(0, -1)  # Keyboard

func _try_assign_controller(device_id: int):
    # Check if already assigned
    if controller_manager._is_controller_assigned(device_id):
        return
    
    # Find next available player slot
    for i in range(controller_manager.max_players):
        if not (i in assigned_players):
            _assign_player(i, device_id)
            break

func _assign_player(player_index: int, device_id: int):
    controller_manager.assign_controller_to_player(player_index, device_id)
    assigned_players[player_index] = device_id
    _update_ui()
```

## Implementation Steps

1. **Phase 1: Core Systems**
   - [ ] Create InputMapping singleton at `gembrawl/globals/InputMapping.gd`
   - [ ] Create ControllerManager singleton at `gembrawl/globals/ControllerManager.gd`
   - [ ] Add both to project autoloads in Project Settings

2. **Phase 2: Input Refactor**
   - [ ] Modify PlayerInput component to use device IDs
   - [ ] Update input detection methods
   - [ ] Test with single controller

3. **Phase 3: Multi-Player Support**
   - [ ] Create LocalMultiplayerManager
   - [ ] Update spawn system for multiple players
   - [ ] Handle player join/leave events

4. **Phase 4: UI Implementation**
   - [ ] Create controller assignment screen
   - [ ] Update HUD for multiple players
   - [ ] Add player indicators

5. **Phase 5: Camera System**
   - [ ] Decide on camera strategy (shared vs split-screen)
   - [ ] Implement camera tracking for multiple players
   - [ ] Handle edge cases (players too far apart)

6. **Phase 6: Testing & Polish**
   - [ ] Test with various controller types
   - [ ] Handle hot-swapping controllers
   - [ ] Add visual feedback for player identification
   - [ ] Test edge cases (disconnections, max players)

## Considerations

### Camera Options
1. **Shared Camera**: Single camera that tracks all players
   - Pros: Maintains visual cohesion, easier to implement
   - Cons: Players can't separate too far

2. **Split Screen**: Divide screen per player
   - Pros: Players have full autonomy
   - Cons: More complex, reduced screen space per player

3. **Dynamic Split**: Shared camera that splits when players separate
   - Pros: Best of both worlds
   - Cons: Most complex to implement

### Player Identification
- Color-coded player indicators
- Unique gem materials/shaders per player
- UI elements positioned based on player index
- Controller vibration for feedback

### Edge Cases to Handle
- Controller disconnection during gameplay
- Player wanting to switch controllers
- Mixing keyboard and gamepad players
- Maximum player limits
- Spectator mode for eliminated players

## Testing Plan
1. Test single player with each controller type
2. Test 2-player scenarios (keyboard + gamepad)
3. Test 4-player scenarios (all gamepads)
4. Test controller hot-swapping
5. Test player join/leave during match
6. Performance testing with multiple players

## Future Enhancements
- Custom control remapping per player
- Controller profiles/presets
- Network multiplayer adaptation
- AI players to fill empty slots

## Implementation Notes for AI Assistant

### Context
- This is a Godot 4.3 project for a gem-themed brawler game
- The project uses a component-based architecture for players
- Current input system only supports single player
- We want to avoid duplicating input actions for each player

### Key Principles
1. Use direct Input API calls with device_id parameter instead of creating duplicate actions
2. Keep control mappings centralized in InputMapping singleton
3. Make the system modular and easy to extend
4. Support hot-swapping of controllers

### Testing Approach
- Start with Phase 1-2 to get basic multi-controller support working
- Test with print statements to verify correct device IDs are being used
- Use the existing test scenes in `gembrawl/tests/` for testing