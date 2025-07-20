# Location: res://gembrawl/globals/ControllerManager.gd
# Singleton to manage controller assignments for local multiplayer
extends Node

signal controller_connected(device_id: int)
signal controller_disconnected(device_id: int)
signal player_joined(player_index: int, device_id: int)
signal player_left(player_index: int)

# Track controller assignments
var controller_assignments = {} # {player_index: device_id}
var available_controllers = [] # List of unassigned controller IDs
var max_players = 4
var single_player_mode = true # When true, all inputs control player 0

func _ready():
	print("[ControllerManager] Initialized")
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_controllers()
	print("[ControllerManager] Found %d controllers" % available_controllers.size())

func _refresh_controllers():
	available_controllers.clear()
	var connected = Input.get_connected_joypads()
	for device_id in connected:
		if not _is_controller_assigned(device_id):
			available_controllers.append(device_id)

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		controller_connected.emit(device_id)
		if not _is_controller_assigned(device_id) and not device_id in available_controllers:
			available_controllers.append(device_id)
	else:
		controller_disconnected.emit(device_id)
		available_controllers.erase(device_id)
		
		# Find and remove player if their controller was disconnected
		for player_index in controller_assignments:
			if controller_assignments[player_index] == device_id:
				remove_player(player_index)
				break

func assign_controller_to_player(player_index: int, device_id: int):
	if player_index >= max_players:
		push_error("Player index %d exceeds max players (%d)" % [player_index, max_players])
		return
	
	# If player already has a controller, free it first
	if player_index in controller_assignments:
		var old_device = controller_assignments[player_index]
		if old_device >= 0:  # Don't add keyboard (-1) to available controllers
			available_controllers.append(old_device)
	
	controller_assignments[player_index] = device_id
	available_controllers.erase(device_id)
	player_joined.emit(player_index, device_id)

func remove_player(player_index: int):
	if player_index in controller_assignments:
		var device_id = controller_assignments[player_index]
		controller_assignments.erase(player_index)
		if device_id >= 0: # Only add back to available if it's a gamepad
			available_controllers.append(device_id)
		player_left.emit(player_index)

func get_player_device_id(player_index: int) -> int:
	return controller_assignments.get(player_index, -1)

func _is_controller_assigned(device_id: int) -> bool:
	return device_id in controller_assignments.values()

func get_assigned_player_count() -> int:
	return controller_assignments.size()

func get_available_controller_count() -> int:
	return available_controllers.size()

func is_player_assigned(player_index: int) -> bool:
	return player_index in controller_assignments

func set_single_player_mode(enabled: bool) -> void:
	single_player_mode = enabled
	print("[ControllerManager] Single player mode: %s" % enabled)
	
	if enabled:
		# Clear all assignments
		controller_assignments.clear()
		_refresh_controllers()

func is_single_player_mode() -> bool:
	return single_player_mode

# Debug function to print current assignments
func print_assignments():
	print("Controller Assignments:")
	for player_index in controller_assignments:
		var device_id = controller_assignments[player_index]
		var device_name = "Keyboard" if device_id == -1 else Input.get_joy_name(device_id)
		print("  Player %d: Device %d (%s)" % [player_index + 1, device_id, device_name])
	print("Available Controllers: ", available_controllers)