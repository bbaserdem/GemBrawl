## Test controller for combat collision systems
## Tests melee, projectile, and AoE collision detection
extends Node3D

## Player management
@export var player_count: int = 2
@export var spawn_radius: float = 5.0
@export var player_scene: PackedScene = preload("res://characters/PlayerCharacter.tscn")

## Combat test scenes
@export var melee_hitbox_scene: PackedScene = preload("res://tests/combat/TestMeleeHitbox.tscn")
@export var projectile_scene: PackedScene = preload("res://tests/combat/TestProjectile.tscn")
@export var aoe_scene: PackedScene = preload("res://tests/combat/TestAOE.tscn")

## References
var players: Array[Player3D] = []
var current_player_index: int = 0
var combat_manager: CombatManager
var active_debug_markers: Array[Node3D] = []  # Track active markers for cleanup
var combat_ui: CombatUI
var arena: Node3D  # HexArena instance
var camera_controller: Node3D  # CameraController3D instance

## UI Labels
@onready var instructions_label: Label = $UI/VBoxContainer/InstructionsLabel
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var debug_label: Label = $UI/VBoxContainer/DebugLabel

func _ready() -> void:
	# Find arena
	arena = $HexArena
	if not arena:
		push_error("HexArena not found!")
		
	# Find camera controller
	camera_controller = $CameraController
	if not camera_controller:
		push_error("CameraController not found!")
	
	# Create combat manager
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	# Connect combat events
	combat_manager.combat_hit.connect(_on_combat_hit)
	combat_manager.player_killed.connect(_on_player_killed)
	
	# Create spawn points on hex tiles
	_create_hex_spawn_points()
	
	# Create players
	_create_players()
	
	# Create combat UI
	_create_combat_ui()
	
	# Set camera to follow player 1
	if camera_controller and players.size() > 0:
		camera_controller.set_follow_target(players[0])
		camera_controller.set_arena_center(Vector3.ZERO)
	
	# Update UI
	_update_ui()

func _create_hex_spawn_points() -> void:
	# Use simple spawn positions on hex grid pattern without validation
	var spawn_hexes: Array[Vector2i] = []
	
	# Choose hexes in a circle pattern around center
	var hex_ring_positions = [
		Vector2i(2, -1),   # Right
		Vector2i(1, -2),   # Top-Right
		Vector2i(-1, -1),  # Top-Left
		Vector2i(-2, 1),   # Left
		Vector2i(-1, 2),   # Bottom-Left
		Vector2i(1, 1),    # Bottom-Right
	]
	
	# Just use the positions directly for the number of players we have
	for i in player_count:
		if i < hex_ring_positions.size():
			spawn_hexes.append(hex_ring_positions[i])
	
	# Create visual spawn points
	for i in spawn_hexes.size():
		var spawn_point = Node3D.new()
		spawn_point.name = "SpawnPoint" + str(i + 1)
		
		# Convert hex to world position
		var world_pos = HexGrid.hex_to_world_3d(spawn_hexes[i])
		# Ensure spawn point is above ground level
		spawn_point.position = world_pos + Vector3(0, 1.0, 0)  # Raised from 0.5 to 1.0
		
		# Add visual indicator
		var mesh = MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		mesh.mesh.radius = 0.5
		mesh.mesh.height = 1.0
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GREEN
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.3
		mesh.material_override = material
		
		spawn_point.add_child(mesh)
		spawn_point.add_to_group("spawn_points")
		add_child(spawn_point)

func _create_combat_ui() -> void:
	# Create combat UI
	var ui_node = get_node_or_null("UI")
	if ui_node:
		combat_ui = CombatUI.new()
		ui_node.add_child(combat_ui)
		
		# Setup health bars for first two players
		if players.size() >= 2:
			combat_ui.setup_players(players[0], players[1])

func _create_players() -> void:
	for i in player_count:
		var player = player_scene.instantiate() as Player3D
		player.player_id = i + 1
		player.name = "Player" + str(i + 1)
		player.is_local_player = (i == 0)  # First player is controlled
		
		# Add to scene FIRST before accessing global_position
		add_child(player)
		
		# Set spawn position AFTER adding to scene tree
		var spawn_points_array = get_tree().get_nodes_in_group("spawn_points")
		if i < spawn_points_array.size():
			player.global_position = spawn_points_array[i].global_position
			# Ensure player is at correct height
			player.global_position.y = max(player.global_position.y, 1.0)
			
			# Make player face the center (0, 0, 0)
			var to_center = -player.global_position
			to_center.y = 0  # Keep it on the horizontal plane
			if to_center.length() > 0:
				to_center = to_center.normalized()
				# Calculate rotation to face center
				var rotation_y = atan2(to_center.x, to_center.z)
				player.rotation.y = rotation_y
		
		# Connect signals
		player.health_changed.connect(_on_player_health_changed.bind(player))
		player.damage_dealt.connect(_on_damage_dealt.bind(player))
		player.damage_received.connect(_on_damage_received.bind(player))
		
		players.append(player)

func _unhandled_input(event: InputEvent) -> void:
	# Test melee attack
	if event.is_action_pressed("attack_melee"):  # Enter or X button
		_test_melee_attack()
	
	# Test projectile
	elif event.is_action_pressed("attack_ranged"):  # Q or Square button
		_test_projectile()
	
	# Test AoE
	elif event.is_action_pressed("attack_aoe"):  # E or Circle button
		_test_aoe_attack()
	
	# Switch player
	elif event.is_action_pressed("ui_page_down"):  # Tab
		_switch_player()

func _test_melee_attack() -> void:
	if players.is_empty():
		return
		
	var attacker = players[current_player_index]
	
	# Create melee hitbox
	var hitbox = melee_hitbox_scene.instantiate() as MeleeHitbox
	add_child(hitbox)  # Add to scene, not to player
	
	# Get forward direction (Godot standard: -transform.basis.z)
	var forward = -attacker.transform.basis.z
	
	# Position in front of player at player's center height
	var spawn_position = attacker.global_position + forward * 1.5
	spawn_position.y = attacker.global_position.y + 0.5  # Center of player capsule
	
	hitbox.global_position = spawn_position
	hitbox.rotation = attacker.rotation  # Match player rotation
	
	# Setup hitbox
	hitbox.setup(attacker)
	hitbox.damage = 20  # Set damage
	hitbox.damage_type = DamageSystem.DamageType.PHYSICAL  # Use PHYSICAL instead of SLASH
	
	# Activate the hitbox
	hitbox.activate()
	
	# Connect to hit signal
	hitbox.hit_target.connect(_on_melee_hit)
	
	# Melee attack by Player

func _test_projectile() -> void:
	if players.is_empty():
		return
		
	var attacker = players[current_player_index]
	
	# Get aim direction (Godot standard: -transform.basis.z)
	var aim_direction = -attacker.transform.basis.z
	aim_direction.y = 0
	aim_direction = aim_direction.normalized()
	
	# Create projectile manually instead of using static method
	var projectile = projectile_scene.instantiate() as Projectile
	add_child(projectile)  # Add to this scene
	# Spawn projectile further in front of the player to avoid immediate collision
	# Match player's center height better (capsule is 1.0 tall, so center is at 0.5)
	var spawn_offset = attacker.global_position + aim_direction * 2.0
	spawn_offset.y = attacker.global_position.y + 0.5  # Center of player capsule
	projectile.setup(attacker, spawn_offset, aim_direction)
	
	# Register with combat manager
	combat_manager.register_projectile(projectile)
	
	# Connect hit signal for debug
	projectile.hit_target.connect(_on_projectile_hit)
	
	status_label.text = "Player %d fired projectile!" % attacker.player_id
	# Projectile fired by Player

func _test_aoe_attack() -> void:
	if players.is_empty():
		return
		
	var attacker = players[current_player_index]
	
	# Create AoE manually instead of using static method
	var aoe = aoe_scene.instantiate() as AoeAttack
	add_child(aoe)  # Add to this scene
	var forward = -attacker.transform.basis.z
	aoe.setup(attacker, attacker.global_position, forward)
	
	# Register with combat manager
	combat_manager.register_aoe(aoe)
	
	# Connect hit signal for debug
	aoe.hit_targets.connect(_on_aoe_hit)
	
	status_label.text = "Player %d created AoE attack!" % attacker.player_id
	# AoE attack by Player

func _switch_player() -> void:
	current_player_index = (current_player_index + 1) % players.size()
	status_label.text = "Controlling Player %d" % (current_player_index + 1)
	
	# Update camera focus
	for i in players.size():
		players[i].is_local_player = (i == current_player_index)

func _update_ui() -> void:
	instructions_label.text = """Combat on Hex Arena - Test Controls:
	
COMBAT:
  Enter / X Button - Melee Attack
  Q / Square - Fire Projectile
  E / Circle - AoE Attack
  Tab - Switch Player Control
  
MOVEMENT:
  WASD/Arrows/Left Stick - Move Player
  Space/A Button - Jump
  
CAMERA (Following Player 1):
  Mouse Wheel - Zoom In/Out
  Middle Mouse Drag - Pan Camera
  Q/E Keys - Rotate Camera
  Page Up/Down - Tilt Camera
  
GAMEPAD CAMERA:
  Right Stick Y - Zoom
  Right Stick X - Rotate
  L1/R1 - Tilt Up/Down
  R3 - Toggle Follow/Static Mode"""
	
	status_label.text = "Controlling Player %d" % (current_player_index + 1)
	debug_label.text = "Players created: %d | Arena: %s" % [players.size(), "Ready" if arena else "Not Found"]

## Signal handlers
func _on_combat_hit(attacker: Node3D, target: Node3D, damage_info: DamageSystem.DamageInfo) -> void:
	var final_damage = damage_info.damage_dealt if damage_info.damage_dealt > 0 else damage_info.final_damage
	print("Combat Hit: %s hit %s for %d damage (%s)" % [
		attacker.name, 
		target.name, 
		final_damage,
		DamageSystem.DamageType.keys()[damage_info.damage_type]
	])
	debug_label.text = "Last hit: %s → %s (%d damage)" % [attacker.name, target.name, final_damage]

func _on_player_killed(victim: Player3D, killer: Node3D) -> void:
	print("Player killed: %s by %s" % [victim.name, killer.name if killer else "environment"])

func _on_player_health_changed(new_health: int, max_health: int, player: Player3D) -> void:
	print("Player %d health: %d/%d" % [player.player_id, new_health, max_health])

func _on_damage_dealt(damage_info: DamageSystem.DamageInfo, player: Player3D) -> void:
	var damage_amount = damage_info.damage_dealt if damage_info.damage_dealt > 0 else damage_info.final_damage
	print("Player %d dealt %d damage" % [player.player_id, damage_amount])

func _on_damage_received(damage_info: DamageSystem.DamageInfo, player: Player3D) -> void:
	var damage_amount = damage_info.damage_dealt if damage_info.damage_dealt > 0 else damage_info.final_damage
	print("Player %d received %d damage" % [player.player_id, damage_amount])

## Helper function to create debug markers
func _create_debug_marker(position: Vector3, color: Color, label: String) -> void:
	var marker = MeshInstance3D.new()
	marker.mesh = SphereMesh.new()
	marker.mesh.radial_segments = 8
	marker.mesh.rings = 4
	
	# Scale based on marker type
	if label == "Player":
		marker.mesh.radius = 0.3
		marker.mesh.height = 0.6
	else:
		marker.mesh.radius = 0.2
		marker.mesh.height = 0.4
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.3
	marker.material_override = material
	
	add_child(marker)
	marker.global_position = position + Vector3(0, 1.5, 0)  # Raise markers for visibility
	
	# Add label
	var label_3d = Label3D.new()
	label_3d.text = label
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.modulate = color
	marker.add_child(label_3d)
	label_3d.position = Vector3(0, 0.5, 0)
	
	# Track marker for cleanup
	active_debug_markers.append(marker)
	
	# Auto-remove after 3 seconds
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): 
		if is_instance_valid(marker):
			active_debug_markers.erase(marker)
			marker.queue_free()
	)

func _exit_tree() -> void:
	# Clean up any remaining debug markers
	for marker in active_debug_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	active_debug_markers.clear()

func _on_melee_hit(target: Node3D, damage_info: DamageSystem.DamageInfo) -> void:
	print("Melee hit target: ", target.name)

func _on_projectile_hit(target: Node3D, damage_info: DamageSystem.DamageInfo) -> void:
	print("Projectile hit target: ", target.name)

func _on_aoe_hit(targets: Array[Node3D]) -> void:
	# AoE hit targets
	for target in targets:
		pass  # Target hit logged 
