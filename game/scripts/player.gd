## Player character controller for GemBrawl
## Handles player movement, input, and gem-specific behaviors
class_name Player
extends CharacterBody2D

## Player properties
@export var gem_data: Gem
@export var player_id: int = 1
@export var is_local_player: bool = true

## Combat state
var is_alive: bool = true
var invulnerable: bool = false
var invulnerability_duration: float = 0.5

## Skill state
var skill_ready: bool = true
var skill_cooldown_timer: float = 0.0

## Signals
signal health_changed(new_health: int, max_health: int)
signal defeated()
signal skill_used()

## Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	if gem_data:
		# Apply gem visuals
		if sprite and gem_data.texture:
			sprite.texture = gem_data.texture
		if sprite:
			sprite.modulate = gem_data.color

func _physics_process(delta: float) -> void:
	if not is_local_player or not is_alive:
		return
	
	# Handle movement input
	var input_vector: Vector2 = Vector2.ZERO
	
	# Get analog stick input directly for smooth movement
	var gamepad_vector: Vector2 = Vector2.ZERO
	if Input.get_connected_joypads().size() > 0:
		gamepad_vector.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		gamepad_vector.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Apply deadzone to avoid drift
		if gamepad_vector.length() < 0.15:
			gamepad_vector = Vector2.ZERO
	
	# Get keyboard input
	var keyboard_vector: Vector2 = Vector2.ZERO
	keyboard_vector.x = Input.get_axis("move_left", "move_right")
	keyboard_vector.y = Input.get_axis("move_up", "move_down")
	
	# Use gamepad input if available, otherwise use keyboard
	if gamepad_vector != Vector2.ZERO:
		input_vector = gamepad_vector
		# Clamp to unit circle for consistent max speed
		if input_vector.length() > 1.0:
			input_vector = input_vector.normalized()
	else:
		input_vector = keyboard_vector
		if input_vector != Vector2.ZERO:
			input_vector = input_vector.normalized()
	
	# Apply movement
	if input_vector != Vector2.ZERO:
		velocity = input_vector * gem_data.movement_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, gem_data.movement_speed * delta * 3)
	
	move_and_slide()
	
	# Update skill cooldown
	if not skill_ready:
		skill_cooldown_timer -= delta
		if skill_cooldown_timer <= 0:
			skill_ready = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player or not is_alive:
		return
	
	# Handle skill activation
	if event.is_action_pressed("use_skill") and skill_ready:
		use_skill()

## Take damage from an attack
func take_damage(damage: int, attacker: Node2D = null) -> void:
	if invulnerable or not is_alive:
		return
	
	var is_defeated: bool = gem_data.take_damage(damage)
	health_changed.emit(gem_data.current_health, gem_data.max_health)
	
	if is_defeated:
		is_alive = false
		defeated.emit()
		set_physics_process(false)
		# TODO: Play death animation
		queue_free()
	else:
		# Trigger invulnerability frames
		invulnerable = true
		await get_tree().create_timer(invulnerability_duration).timeout
		invulnerable = false

## Use the gem's special skill
func use_skill() -> void:
	skill_ready = false
	skill_cooldown_timer = gem_data.skill_cooldown
	skill_used.emit()
	# Skill implementation will be handled by skill system

## Respawn the player at a given position
func respawn(spawn_position: Vector2) -> void:
	position = spawn_position
	is_alive = true
	gem_data.current_health = gem_data.max_health
	health_changed.emit(gem_data.current_health, gem_data.max_health)
	set_physics_process(true) 
