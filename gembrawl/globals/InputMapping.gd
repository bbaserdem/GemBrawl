# Location: res://gembrawl/globals/InputMapping.gd
# This singleton defines base control mappings for all players
extends Node

func _ready():
	print("[InputMapping] Initialized")

const BASE_ACTIONS = {
	"move_left": {
		"keyboard": [KEY_A, KEY_LEFT],
		"gamepad": [JOY_AXIS_LEFT_X] # Will check for negative value
	},
	"move_right": {
		"keyboard": [KEY_D, KEY_RIGHT],
		"gamepad": [JOY_AXIS_LEFT_X] # Will check for positive value
	},
	"move_up": {
		"keyboard": [KEY_W, KEY_UP],
		"gamepad": [JOY_AXIS_LEFT_Y] # Will check for negative value
	},
	"move_down": {
		"keyboard": [KEY_S, KEY_DOWN],
		"gamepad": [JOY_AXIS_LEFT_Y] # Will check for positive value
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
		"gamepad": [JOY_AXIS_RIGHT_X] # Will check for negative value
	},
	"camera_right": {
		"keyboard": [KEY_E],
		"gamepad": [JOY_AXIS_RIGHT_X] # Will check for positive value
	}
}

# Helper functions to query mappings
func get_action_mapping(action: String, device_type: String):
	if BASE_ACTIONS.has(action):
		return BASE_ACTIONS[action].get(device_type, [])
	return []

# Check if a specific button/key is mapped to an action
func is_button_for_action(action: String, button: int, device_type: String) -> bool:
	var mappings = get_action_mapping(action, device_type)
	return button in mappings

# Get axis info for movement actions
func get_axis_for_action(action: String) -> Dictionary:
	# Returns axis number and direction for analog stick actions
	match action:
		"move_left":
			return {"axis": JOY_AXIS_LEFT_X, "sign": -1}
		"move_right":
			return {"axis": JOY_AXIS_LEFT_X, "sign": 1}
		"move_up":
			return {"axis": JOY_AXIS_LEFT_Y, "sign": -1}
		"move_down":
			return {"axis": JOY_AXIS_LEFT_Y, "sign": 1}
		"camera_left":
			return {"axis": JOY_AXIS_RIGHT_X, "sign": -1}
		"camera_right":
			return {"axis": JOY_AXIS_RIGHT_X, "sign": 1}
		_:
			return {}