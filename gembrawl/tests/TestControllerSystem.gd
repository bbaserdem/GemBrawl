## Test script for multi-controller system
extends Node

@onready var info_label: Label = $UI/InfoPanel/VBoxContainer/InfoLabel
@onready var player_label: Label = $UI/InfoPanel/VBoxContainer/PlayerLabel
@onready var input_label: Label = $UI/InfoPanel/VBoxContainer/InputLabel
@onready var controller_label: Label = $UI/InfoPanel/VBoxContainer/ControllerLabel

var controller_manager: Node
var player: Player3D

func _ready() -> void:
	# Get controller manager
	controller_manager = get_node("/root/ControllerManager")
	if not controller_manager:
		push_error("ControllerManager singleton not found!")
		return
	
	# Connect signals
	controller_manager.controller_connected.connect(_on_controller_connected)
	controller_manager.controller_disconnected.connect(_on_controller_disconnected)
	controller_manager.player_joined.connect(_on_player_joined)
	controller_manager.player_left.connect(_on_player_left)
	
	# Get or spawn player
	player = $Player
	if player:
		# Simulate player 0 joining with keyboard by default
		controller_manager.assign_controller_to_player(0, -1)
		_update_display()

func _input(event: InputEvent) -> void:
	# F1: Assign keyboard to player 0
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		controller_manager.assign_controller_to_player(0, -1)
		print("Assigned keyboard to player 0")
		_update_display()
	
	# F2-F5: Assign controllers 0-3 to player 0
	elif event is InputEventKey and event.pressed and event.keycode >= KEY_F2 and event.keycode <= KEY_F5:
		var controller_id = event.keycode - KEY_F2
		var connected = Input.get_connected_joypads()
		if controller_id in connected:
			controller_manager.assign_controller_to_player(0, controller_id)
			print("Assigned controller %d to player 0" % controller_id)
			_update_display()
		else:
			print("Controller %d not connected!" % controller_id)
	
	# P: Print controller assignments
	elif event is InputEventKey and event.pressed and event.keycode == KEY_P:
		controller_manager.print_assignments()
	
	# M: Toggle single/multi player mode
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		var current_mode = controller_manager.is_single_player_mode()
		controller_manager.set_single_player_mode(not current_mode)
		info_label.text = "Switched to %s mode" % ("single-player" if not current_mode else "multi-player")
		
		# Reset player input based on new mode
		if player and player.input:
			if not current_mode:  # Switching to single-player
				player.input.update_device_id(-2)
			else:  # Switching to multi-player
				player.input.update_device_id(-1)  # Default to keyboard
				controller_manager.assign_controller_to_player(0, -1)
		
		_update_display()

func _process(_delta: float) -> void:
	if player and player.input:
		# Display current input state
		var movement = player.input.get_movement_input()
		var camera = player.input.get_camera_input()
		var jump = player.input.is_jump_pressed
		var skill = player.input.is_skill_pressed
		
		input_label.text = "Movement: (%.2f, %.2f)\nCamera: (%.2f, %.2f)\nJump: %s | Skill: %s" % [
			movement.x, movement.y,
			camera.x, camera.y,
			"Pressed" if jump else "Released",
			"Pressed" if skill else "Released"
		]

func _on_controller_connected(device_id: int) -> void:
	info_label.text = "Controller %d connected" % device_id
	_update_display()

func _on_controller_disconnected(device_id: int) -> void:
	info_label.text = "Controller %d disconnected" % device_id
	_update_display()

func _on_player_joined(player_index: int, device_id: int) -> void:
	var device_name = "Keyboard" if device_id == -1 else "Controller %d" % device_id
	info_label.text = "Player %d joined with %s" % [player_index + 1, device_name]
	
	# Update player's input component if this is our test player
	if player_index == 0 and player and player.input:
		player.input.update_device_id(device_id)
		print("Updated player input device to: %d (%s)" % [device_id, device_name])

func _on_player_left(player_index: int) -> void:
	info_label.text = "Player %d left" % [player_index + 1]

func _update_display() -> void:
	# Show connected controllers
	var connected = Input.get_connected_joypads()
	var controller_text = "Connected Controllers: %d" % connected.size()
	for i in connected:
		controller_text += "\n  [%d] %s" % [i, Input.get_joy_name(i)]
	
	controller_label.text = controller_text
	
	# Show mode and player assignment
	if player and player.input:
		var mode_text = "Mode: %s" % ("Single-player" if controller_manager.is_single_player_mode() else "Multi-player")
		var device_id = player.input.device_id
		var device_name = "All inputs" if device_id == -2 else ("Keyboard" if device_id == -1 else "Controller %d (%s)" % [device_id, Input.get_joy_name(device_id)])
		player_label.text = "%s\nPlayer 1: %s" % [mode_text, device_name]