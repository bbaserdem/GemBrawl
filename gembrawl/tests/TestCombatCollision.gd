## Test controller for combat collision systems
## Tests melee, projectile, and AoE collision detection
extends Node3D

# Import dependencies
const DamageSystem = preload("res://scripts/DamageSystem.gd")

## Player management
@export var player_count: int = 2
@export var spawn_radius: float = 5.0
@export var player_scene: PackedScene = preload("res://characters/PlayerCharacter.tscn")

## Gem resources for different players
var gem_resources: Array[Resource] = [
	preload("res://characters/data/classes/ruby.tres"),
	preload("res://characters/data/classes/sapphire.tres"),
	preload("res://characters/data/classes/emerald.tres")
]

## Combat skill classes - using actual game implementations
const MeleeHitbox = preload("res://characters/skills/MeleeHitbox.gd")
const Projectile = preload("res://characters/skills/Projectile.gd")
const AoeAttack = preload("res://characters/skills/AoeAttack.gd")

## References
var players: Array = []  ## Array[IPlayer]
var current_player_index: int = 0
var combat_manager: Node
var active_debug_markers: Array[Node3D] = []  # Track active markers for cleanup
var combat_ui: CombatUI
var arena: Node3D  # HexArena instance
var camera_controller: Node3D  # CameraController3D instance

## UI Labels
@onready var instructions_label: Label = $UI/VBoxContainer/InstructionsLabel
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var debug_label: Label = $UI/VBoxContainer/DebugLabel

func _ready() -> void:
	# Increase physics tick rate for better collision detection in testing
	Engine.physics_ticks_per_second = 120  # Double the default 60
	
	# Find arena
	arena = $HexArena
	if not arena:
		push_error("HexArena not found!")
		
	# Find camera controller
	camera_controller = $CameraController
	if not camera_controller:
		push_error("CameraController not found!")
	
	# Create combat manager node
	combat_manager = Node.new()
	combat_manager.name = "CombatManager"
	combat_manager.set_script(preload("res://game/CombatManager.gd"))
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
	
	# Set arena center for the camera
	if camera_controller:
		camera_controller.set_arena_center(Vector3.ZERO)
		print("Camera setup complete - will auto-detect local player")
	
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
		
		# Add visual indicator - small flat disc
		var mesh = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.5
		cylinder.bottom_radius = 0.5
		cylinder.height = 0.05  # Very flat disc
		cylinder.radial_segments = 16
		mesh.mesh = cylinder
		mesh.position.y = -0.9  # Place it on the ground
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 0.2, 0.3)  # Green, semi-transparent
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color(0.1, 0.4, 0.1)
		material.emission_energy = 0.2
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
		var player = player_scene.instantiate()  ## as IPlayer (Player3D)
		player.player_id = i + 1
		player.name = "Player" + str(i + 1)
		player.is_local_player = (i == 0)  # Only first player is controlled
		
		# Assign a gem to each player (cycle through available gems)
		if i < gem_resources.size():
			player.gem_data = gem_resources[i]
		else:
			# If more players than gems, cycle through gems
			player.gem_data = gem_resources[i % gem_resources.size()]
		
		# Add to scene FIRST before accessing global_position
		add_child(player)
		
		# Add player to the "players" group so camera can find them
		player.add_to_group("players")
		
		# Set spawn position AFTER adding to scene tree
		var spawn_points_array = get_tree().get_nodes_in_group("spawn_points")
		if i < spawn_points_array.size():
			player.global_position = spawn_points_array[i].global_position
			# Ensure player is at correct height
			player.global_position.y = max(player.global_position.y, 1.0)
			
			# Make player face away from center (outward)
			var facing_direction = player.global_position
			facing_direction.y = 0  # Keep it on the horizontal plane
			if facing_direction.length() > 0:
				facing_direction = facing_direction.normalized()
				# Calculate rotation to face outward
				var rotation_y = atan2(facing_direction.x, facing_direction.z)
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
	
	# Create melee hitbox node
	var hitbox = MeleeHitbox.new()
	
	# Add a CollisionShape3D to the hitbox BEFORE adding to scene
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 1.0, 1.0)  # Width, Height, Depth
	collision_shape.shape = box_shape
	hitbox.add_child(collision_shape)
	
	# Add visual indicator for the melee attack
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2.0, 1.0, 1.0)  # Match collision shape
	mesh_instance.mesh = box_mesh
	
	# Create a semi-transparent material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.2, 0.2, 0.5)  # Red, semi-transparent
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1, 0, 0)
	material.emission_energy = 0.3
	mesh_instance.material_override = material
	hitbox.add_child(mesh_instance)
	
	# Now add to scene
	add_child(hitbox)
	
	# Get forward direction (reversed because players face outward)
	var forward = attacker.transform.basis.z
	
	# Position in front of player at player's center height
	var spawn_position = attacker.global_position + forward * 1.5
	spawn_position.y = attacker.global_position.y + 0.5  # Center of player capsule
	
	hitbox.global_position = spawn_position
	hitbox.rotation = attacker.rotation  # Match player rotation
	
	# Setup hitbox
	hitbox.setup(attacker)
	hitbox.damage = 20  # Set damage
	hitbox.damage_type = 0  # DamageSystem.DamageType.PHYSICAL
	
	# Activate the hitbox
	hitbox.activate()
	
	# Connect to hit signal
	hitbox.hit_target.connect(_on_melee_hit)
	
	# Auto-remove the hitbox after its active time
	await get_tree().create_timer(0.3).timeout
	hitbox.queue_free()
	
	# Melee attack by Player

func _test_projectile() -> void:
	if players.is_empty():
		return
		
	var attacker = players[current_player_index]
	
	# Get aim direction (reversed because players face outward)
	var aim_direction = attacker.transform.basis.z
	aim_direction.y = 0
	aim_direction = aim_direction.normalized()
	
	# Create projectile node
	var projectile = Projectile.new()
	
	# Add required child nodes BEFORE adding to scene
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3  # Increased from 0.2 for better visibility
	sphere_mesh.height = 0.6  # Increased from 0.4
	mesh_instance.mesh = sphere_mesh
	
	# Add a simple material for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0)  # Orange color
	material.emission_enabled = true
	material.emission = Color(1, 0.3, 0)
	material.emission_energy = 0.5
	mesh_instance.material_override = material
	projectile.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3  # Match mesh size
	collision.shape = sphere_shape
	projectile.add_child(collision)
	
	var hitbox = Area3D.new()
	hitbox.name = "Hitbox"
	hitbox.monitoring = true  # Enable monitoring
	hitbox.monitorable = false  # Hitbox doesn't need to be monitored
	
	# Set up collision layers for the hitbox using proper CombatLayers
	CombatLayers.setup_combat_area(hitbox, CombatLayers.Layer.PROJECTILE)
	
	var hitbox_collision = CollisionShape3D.new()
	var hitbox_shape = SphereShape3D.new()
	hitbox_shape.radius = 0.6  # Larger hitbox for more reliable detection
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	projectile.add_child(hitbox)
	
	# NOW add to scene after children are set up
	add_child(projectile)
	
	# Configure projectile properties for testing
	projectile.speed = 60.0  # Even slower to improve hit detection
	projectile.damage = 15
	projectile.lifetime = 8.0  # Longer lifetime for slower projectile
	projectile.gravity_scale = 0.0  # No gravity for testing
	
	# Force physics process on projectile to ensure collision checks
	projectile.set_physics_process(true)
	projectile.process_priority = -1  # Process before other nodes
	
	# Spawn projectile in front of the player at a lower height
	var spawn_offset = attacker.global_position + aim_direction * 1.5  # Spawn further to avoid self-collision
	spawn_offset.y = attacker.global_position.y + 0.2  # Lower height to hit ground targets
	projectile.setup(attacker, spawn_offset, aim_direction)
	
	# Debug collision setup
	print("Projectile hitbox layer: ", hitbox.collision_layer, " mask: ", hitbox.collision_mask)
	
	# Register with combat manager
	combat_manager.register_projectile(projectile)
	
	# Connect hit signal for debug
	projectile.hit_target.connect(_on_projectile_hit)
	
	# Debug: ensure projectile is set up correctly
	print("Projectile created: pos=", projectile.global_position, " dir=", aim_direction, " speed=", projectile.speed)
	print("Players in scene: ", players.size(), " Current player: ", attacker.name)
	
	status_label.text = "Player %d fired projectile!" % attacker.player_id
	# Projectile fired by Player

func _test_aoe_attack() -> void:
	if players.is_empty():
		return
		
	var attacker = players[current_player_index]
	
	# Create AoE node
	var aoe = AoeAttack.new()
	
	# Configure AoE properties BEFORE adding to scene
	aoe.damage = 30
	aoe.radius = 3.0
	aoe.delay_before_damage = 0.5
	aoe.duration = 0.1
	aoe.shape = AoeAttack.Shape.SPHERE
	
	# Add to scene
	add_child(aoe)
	
	# Setup AoE after adding to scene (needs scene tree for timers)
	var forward = attacker.transform.basis.z
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
  R3 - Cycle Camera Modes (Follow → Static → Free)"""
	
	status_label.text = "Controlling Player %d" % (current_player_index + 1)
	debug_label.text = "Players created: %d | Arena: %s" % [players.size(), "Ready" if arena else "Not Found"]

## Signal handlers
func _on_combat_hit(attacker: Node3D, target: Node3D, damage_info: Dictionary) -> void:  ## damage_info is DamageSystem.DamageInfo
	var final_damage = damage_info.damage_dealt if damage_info.damage_dealt > 0 else damage_info.final_damage
	print("Combat Hit: %s hit %s for %d damage (%s)" % [
		attacker.name, 
		target.name, 
		final_damage,
		["PHYSICAL", "MAGICAL", "TRUE", "ELEMENTAL"][damage_info.get("damage_type", 0)]
	])
	debug_label.text = "Last hit: %s → %s (%d damage)" % [attacker.name, target.name, final_damage]

func _on_player_killed(victim, killer: Node3D) -> void:  ## victim: IPlayer
	print("Player killed: %s by %s" % [victim.name, killer.name if killer else "environment"])

func _on_player_health_changed(new_health: int, max_health: int, player) -> void:  ## player: IPlayer
	print("Player %d health: %d/%d" % [player.player_id, new_health, max_health])

func _on_damage_dealt(damage_info: Dictionary, player) -> void:  ## damage_info is DamageSystem.DamageInfo, player: IPlayer
	var damage_amount = damage_info.damage_dealt if damage_info.damage_dealt > 0 else damage_info.final_damage
	print("Player %d dealt %d damage" % [player.player_id, damage_amount])

func _on_damage_received(damage_info: Dictionary, player) -> void:  ## damage_info is DamageSystem.DamageInfo, player: IPlayer
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

func _on_melee_hit(target: Node3D, damage_info: Dictionary) -> void:  ## damage_info is DamageSystem.DamageInfo
	print("Melee hit target: ", target.name)

func _on_projectile_hit(target: Node3D, damage_info: Dictionary) -> void:  ## damage_info is DamageSystem.DamageInfo
	var damage = damage_info.get("final_damage", damage_info.get("damage", 0))
	print("Projectile hit target: ", target.name, " for ", damage, " damage")
	status_label.text = "Hit %s for %d damage!" % [target.name, damage]

func _on_aoe_hit(targets: Array[Node3D]) -> void:
	# AoE hit targets
	for target in targets:
		pass  # Target hit logged 
