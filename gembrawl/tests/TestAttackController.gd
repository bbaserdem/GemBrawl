## TestAttackController - Adds basic melee and AoE attacks to players for testing
extends Node

const MeleeHitbox = preload("res://characters/skills/MeleeHitbox.gd")  # Area3D based hitbox
const Projectile = preload("res://characters/skills/Projectile.gd")
const AoeAttack = preload("res://characters/skills/AoeAttack.gd")
const DamageSystem = preload("res://scripts/DamageSystem.gd")

## Attack cooldowns
@export var melee_cooldown: float = 3.0  # 3 seconds for melee
@export var ranged_cooldown: float = 0.5  # 0.5 seconds for ranged
@export var aoe_cooldown: float = 5.0  # 5 seconds for AOE

## Attack parameters
@export var melee_damage: int = 10
@export var melee_range: float = 2.0
@export var melee_knockback: float = 5.0

@export var ranged_damage: int = 8
@export var ranged_speed: float = 20.0

@export var aoe_damage: int = 15
@export var aoe_radius: float = 4.0
@export var aoe_delay: float = 0.5

## State
var player: Node3D
var input_component
var melee_ready: bool = true
var ranged_ready: bool = true
var aoe_ready: bool = true
var melee_timer: float = 0.0
var ranged_timer: float = 0.0
var aoe_timer: float = 0.0

func setup(player_node: Node3D) -> void:
	player = player_node
	input_component = player.get_node("Input")
	if input_component:
		print("[TestAttackController] Setup for %s with device %d" % [player.name, input_component.device_id])
	set_process(true)
	set_process_input(true)

func _process(delta: float) -> void:
	if not player or not input_component:
		return
	
	# Update cooldowns
	if not melee_ready:
		melee_timer -= delta
		if melee_timer <= 0:
			melee_ready = true
	
	if not ranged_ready:
		ranged_timer -= delta
		if ranged_timer <= 0:
			ranged_ready = true
	
	if not aoe_ready:
		aoe_timer -= delta
		if aoe_timer <= 0:
			aoe_ready = true
	
	# Check for attack inputs
	_check_attack_inputs()

func _input(event: InputEvent) -> void:
	if not player or not input_component:
		return
	
	# Get device ID from input component
	var device_id = input_component.device_id
	
	# Debug logging for any button press
	if event is InputEventJoypadButton and event.pressed:
		print("[TestAttackController] Button %d pressed on device %d (my device: %d)" % [event.button_index, event.device, device_id])
	
	# For multiplayer, we need to verify the event comes from our assigned device
	var is_our_input = false
	
	# Check keyboard input (device_id == -1 means keyboard for player 1)
	if event is InputEventKey and device_id == -1:
		is_our_input = true
	# Check gamepad input (match device IDs)
	elif event is InputEventJoypadButton and event.device == device_id and device_id >= 0:
		is_our_input = true
	
	# If this input isn't for us, ignore it
	if not is_our_input:
		return
	
	# Now check for attack actions using the input map
	if event.is_action_pressed("attack_melee"):
		print("[TestAttackController] Melee action detected, ready: %s" % melee_ready)
		if melee_ready:
			_perform_melee_attack()
	elif event.is_action_pressed("attack_ranged"):
		print("[TestAttackController] Ranged action detected, ready: %s" % ranged_ready)
		if ranged_ready:
			_perform_ranged_attack()
	elif event.is_action_pressed("attack_aoe"):
		print("[TestAttackController] AoE action detected, ready: %s" % aoe_ready)
		if aoe_ready:
			_perform_aoe_attack()

func _check_attack_inputs() -> void:
	# Don't use process for input - use _unhandled_input instead
	pass

## Helper to verify event matches our assigned device
func _is_event_from_our_device(event: InputEvent) -> bool:
	var device_id = input_component.device_id
	
	# Keyboard events (device_id = -1)
	if event is InputEventKey:
		return device_id == -1
	
	# Gamepad events should match device ID
	if event is InputEventJoypadButton:
		return event.device == device_id
	
	if event is InputEventJoypadMotion:
		return event.device == device_id
		
	return false

func _perform_melee_attack() -> void:
	print("[TestAttackController] Performing melee attack")
	if not melee_ready:
		return
		
	melee_ready = false
	melee_timer = melee_cooldown
	
	# Create actual melee hitbox like in TestCombatCollision
	print("[TestAttackController] Creating melee hitbox...")
	var hitbox = MeleeHitbox.new()
	print("[TestAttackController] Melee hitbox created: %s" % hitbox)
	
	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 1.0, 1.0)
	collision_shape.shape = box_shape
	hitbox.add_child(collision_shape)
	
	# Add to scene
	get_tree().current_scene.add_child(hitbox)
	
	# Position in front of player
	var forward = player.transform.basis.z
	var spawn_position = player.global_position + forward * 1.5
	spawn_position.y = player.global_position.y + 0.5
	
	hitbox.global_position = spawn_position
	hitbox.rotation = player.rotation
	
	# Setup hitbox
	hitbox.setup(player)
	hitbox.damage = melee_damage
	hitbox.damage_type = 0  # Physical damage
	
	# Activate the hitbox
	hitbox.activate()
	
	# Auto-remove after duration
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()

func _perform_aoe_attack() -> void:
	if not aoe_ready:
		return
		
	aoe_ready = false
	aoe_timer = aoe_cooldown
	
	# Create actual AoE attack like in TestCombatCollision
	var aoe = AoeAttack.new()
	
	# Configure AoE properties
	aoe.damage = aoe_damage
	aoe.radius = aoe_radius
	aoe.delay_before_damage = aoe_delay
	aoe.duration = 0.1
	aoe.shape = AoeAttack.Shape.SPHERE
	
	# Add to scene
	get_tree().current_scene.add_child(aoe)
	
	# Setup AoE at player position
	var forward = player.transform.basis.z
	aoe.setup(player, player.global_position, forward)

func _perform_ranged_attack() -> void:
	if not ranged_ready:
		return
		
	ranged_ready = false
	ranged_timer = ranged_cooldown
	
	# Create projectile like in TestCombatCollision
	var projectile = Projectile.new()
	
	# Add required components
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	sphere_mesh.height = 0.6
	mesh_instance.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0)  # Orange
	material.emission_enabled = true
	material.emission = Color(1, 0.3, 0)
	material.emission_energy = 0.5
	mesh_instance.material_override = material
	projectile.add_child(mesh_instance)
	
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3
	collision.shape = sphere_shape
	projectile.add_child(collision)
	
	var hitbox = Area3D.new()
	hitbox.name = "Hitbox"
	hitbox.monitoring = true
	hitbox.monitorable = false
	
	var hitbox_collision = CollisionShape3D.new()
	var hitbox_shape = SphereShape3D.new()
	hitbox_shape.radius = 0.6
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	projectile.add_child(hitbox)
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Configure projectile
	projectile.speed = ranged_speed
	projectile.damage = ranged_damage
	projectile.lifetime = 5.0
	projectile.gravity_scale = 0.0
	
	# Launch projectile
	var forward = player.transform.basis.z
	var spawn_offset = player.global_position + forward * 1.5
	spawn_offset.y = player.global_position.y + 0.5
	projectile.setup(player, spawn_offset, forward)

func _show_attack_effect(text: String, color: Color) -> void:
	# Create floating text above player
	var label_3d = Label3D.new()
	label_3d.text = text
	label_3d.modulate = color
	label_3d.font_size = 32
	label_3d.outline_size = 8
	player.add_child(label_3d)
	label_3d.position.y = 2.0
	
	# Animate and remove
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label_3d, "position:y", 3.0, 1.0)
	tween.tween_property(label_3d, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label_3d.queue_free)

## Get cooldown info for UI
func get_melee_cooldown_percent() -> float:
	if melee_ready:
		return 1.0
	return 1.0 - (melee_timer / melee_cooldown)

func get_ranged_cooldown_percent() -> float:
	if ranged_ready:
		return 1.0
	return 1.0 - (ranged_timer / ranged_cooldown)

func get_aoe_cooldown_percent() -> float:
	if aoe_ready:
		return 1.0
	return 1.0 - (aoe_timer / aoe_cooldown)