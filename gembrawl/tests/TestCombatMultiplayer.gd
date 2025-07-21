extends Node3D

const HexGrid = preload("res://arena/HexGrid.gd")
const PlayerCharacter = preload("res://characters/PlayerCharacter.tscn")
const HexArena = preload("res://arena/HexArena.tscn")
const GemResource = preload("res://characters/data/classes/GemResource.gd")

@onready var camera_controller = $CameraController
@onready var hud = $HUD

var arena: HexArena
var players: Array[Node3D] = []
var player_indices: Dictionary = {} # Maps player instance to player index (0 or 1)
var players_ready: int = 0

func _ready() -> void:
	# Set up multi-player mode
	ControllerManager.set_single_player_mode(false)
	# Clear any existing assignments
	for i in range(4):
		if ControllerManager.is_player_assigned(i):
			ControllerManager.remove_player(i)
	
	_setup_arena()
	# Wait a frame for arena to generate spawn points
	await get_tree().process_frame
	_create_players()
	_setup_camera()
	_setup_hud()
	
	# Start controller assignment process
	_start_controller_assignment()

func _setup_arena() -> void:
	arena = HexArena.instantiate()
	arena.arena_radius = 8
	arena.hazard_count = 12
	add_child(arena)

func _create_players() -> void:
	print("[TestCombatMultiplayer] Creating players...")
	# Load gem resources directly
	var ruby_gem = load("res://characters/data/classes/ruby.tres")
	var sapphire_gem = load("res://characters/data/classes/sapphire.tres")
	
	if not ruby_gem or not sapphire_gem:
		push_error("Could not load gem data for Ruby or Sapphire")
		return
	
	# Get spawn points from arena
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	if spawn_points.size() < 2:
		push_error("Not enough spawn points for 2 players")
		return
	
	# Create Player 1 (Ruby)
	var player1 = PlayerCharacter.instantiate()
	player1.name = "Player1"
	player1.gem_data = ruby_gem
	add_child(player1)
	player1.global_position = spawn_points[0].global_position
	players.append(player1)
	player_indices[player1] = 0
	
	# Set up player 1 input component (disabled until controller assigned)
	var input1 = player1.get_node("Input")
	if input1:
		input1.player_index = 0
		input1.device_id = -999  # Invalid device - no input until assigned
	
	# Create Player 2 (Sapphire)
	var player2 = PlayerCharacter.instantiate()
	player2.name = "Player2"
	player2.gem_data = sapphire_gem
	add_child(player2)
	player2.global_position = spawn_points[1].global_position
	players.append(player2)
	player_indices[player2] = 1
	
	# Set up player 2 input component (disabled until controller assigned)
	var input2 = player2.get_node("Input")
	if input2:
		input2.player_index = 1
		input2.device_id = -999  # Invalid device - no input until assigned

func _setup_camera() -> void:
	# Configure camera for overhead arena view
	if camera_controller:
		# Set to arena mode for fixed overhead view
		camera_controller.camera_mode = camera_controller.CameraMode.ARENA_FOCUSED
		camera_controller.arena_center = Vector3.ZERO  # Center of arena
		
		# Position camera for good overhead view
		camera_controller.camera_distance = 30.0
		camera_controller.camera_height = 25.0
		
		# Set tilt for proper top-down view
		camera_controller.tilt_angle = 75.0  # Almost top-down
		
		# Disable following individual players
		camera_controller.enable_follow = false

func _setup_hud() -> void:
	if not hud:
		return
	
	# Create CombatUI for health bars
	var combat_ui = preload("res://ui/hud/CombatUI.gd").new()
	combat_ui.name = "CombatUI"
	hud.add_child(combat_ui)
	
	# Create UI for controller assignment
	var assignment_label = Label.new()
	assignment_label.name = "ControllerAssignment"
	assignment_label.text = "Press START on controller or ENTER on keyboard to join"
	assignment_label.add_theme_font_size_override("font_size", 24)
	assignment_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	assignment_label.position.y = 100
	hud.add_child(assignment_label)

func _start_controller_assignment() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# Handle keyboard Enter key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_try_assign_controller(-1) # -1 represents keyboard
	
	# Handle controller Start button (Options/Menu button)
	elif event is InputEventJoypadButton and event.pressed:
		var device = event.device
		print("Controller %d pressed button %d" % [device, event.button_index])
		# START button is typically button index 6 (Options) or 7 (Menu)
		if event.button_index == JOY_BUTTON_START or event.button_index == 6 or event.button_index == 7:
			print("Start button detected on device %d" % device)
			_try_assign_controller(device)

func _try_assign_controller(device: int) -> void:
	# Check if this controller is already assigned to any player
	for i in range(2):
		if ControllerManager.get_player_device_id(i) == device:
			return
	
	# Find next unassigned player slot
	var assigned_player_index = -1
	for i in range(2):
		if not ControllerManager.is_player_assigned(i):
			assigned_player_index = i
			break
	
	if assigned_player_index == -1:
		return # All players assigned
	
	# Assign the controller
	ControllerManager.assign_controller_to_player(assigned_player_index, device)
	
	# Find the player instance for this index
	var assigned_player = null
	for player in players:
		if player_indices[player] == assigned_player_index:
			assigned_player = player
			break
	
	if not assigned_player:
		return
	
	# Configure the player's input
	var input_component = assigned_player.get_node("Input")
	if input_component:
		input_component.device_id = device
		input_component.update_device_id(device)
		print("Assigned device %d to player %d" % [device, assigned_player_index])
	
	players_ready += 1
	
	# Update UI
	_update_assignment_ui()
	
	# Check if all players are assigned
	if players_ready == 2:
		_on_all_players_ready()

func _update_assignment_ui() -> void:
	var label = hud.get_node_or_null("ControllerAssignment")
	if not label:
		return
	
	if players_ready == 0:
		label.text = "Press START on controller or ENTER on keyboard to join"
	elif players_ready == 1:
		label.text = "Player 1 joined! Waiting for Player 2..."
	else:
		label.visible = false

func _on_all_players_ready() -> void:
	# Hide assignment UI
	var label = hud.get_node_or_null("ControllerAssignment")
	if label:
		label.queue_free()
	
	# Setup health bars
	_setup_combat_ui()
	
	# Start the match
	print("All players ready! Starting match...")
	
	# Add attack functionality to players
	_setup_player_attacks()
	
	# Start match countdown
	_start_match_countdown()

func _setup_combat_ui() -> void:
	var combat_ui = hud.get_node_or_null("CombatUI")
	if combat_ui and players.size() >= 2:
		combat_ui.setup_players(players[0], players[1])

func _setup_player_attacks() -> void:
	# Add attack components to each player
	for player in players:
		_add_attack_system(player)

func _add_attack_system(player: Node3D) -> void:
	# Create a custom attack controller for the test
	var attack_controller = Node.new()
	attack_controller.name = "TestAttackController"
	attack_controller.set_script(preload("res://tests/TestAttackController.gd"))
	player.add_child(attack_controller)
	
	# Configure attack parameters
	attack_controller.melee_cooldown = 2.0
	attack_controller.aoe_cooldown = 5.0
	attack_controller.setup(player)

func _start_match_countdown() -> void:
	var countdown_label = Label.new()
	countdown_label.name = "Countdown"
	countdown_label.text = "3"
	countdown_label.add_theme_font_size_override("font_size", 48)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hud.add_child(countdown_label)
	
	# Countdown sequence
	for i in range(3, 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "FIGHT!"
	await get_tree().create_timer(0.5).timeout
	countdown_label.queue_free()
	
	# Show control hints
	_show_control_hints()

func _show_control_hints() -> void:
	var hints_container = VBoxContainer.new()
	hints_container.name = "ControlHints"
	hints_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hints_container.position = Vector2(20, -140)
	hud.add_child(hints_container)
	
	var title = Label.new()
	title.text = "Combat Actions:"
	title.add_theme_font_size_override("font_size", 20)
	hints_container.add_child(title)
	
	var melee_hint = Label.new()
	melee_hint.text = "X (Tab) - Melee Attack - 3s cooldown"
	melee_hint.add_theme_font_size_override("font_size", 16)
	hints_container.add_child(melee_hint)
	
	var ranged_hint = Label.new()
	ranged_hint.text = "Y (Q) - Ranged Attack - 0.5s cooldown"
	ranged_hint.add_theme_font_size_override("font_size", 16)
	hints_container.add_child(ranged_hint)
	
	var aoe_hint = Label.new()
	aoe_hint.text = "B (E) - AoE Attack - 5s cooldown"
	aoe_hint.add_theme_font_size_override("font_size", 16)
	hints_container.add_child(aoe_hint)
	
	var jump_hint = Label.new()
	jump_hint.text = "R2 (Shift) - Jump"
	jump_hint.add_theme_font_size_override("font_size", 16)
	hints_container.add_child(jump_hint)
	
	var movement_hint = Label.new()
	movement_hint.text = "Use assigned controller to move and attack"
	movement_hint.add_theme_font_size_override("font_size", 14)
	movement_hint.modulate = Color(0.8, 0.8, 0.8)
	hints_container.add_child(movement_hint)
