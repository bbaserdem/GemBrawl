extends Node3D

@export var move_speed: float = 10.0
@export var zoom_speed: float = 20.0
@export var rotate_speed: float = 2.0
@export var tilt_speed: float = 1.0

@export var min_zoom: float = 5.0
@export var max_zoom: float = 50.0
@export var min_tilt: float = -80.0
@export var max_tilt: float = -10.0

var camera_pivot: Node3D
var camera: Camera3D
var current_zoom: float = 20.0
var current_tilt: float = -45.0

func _ready():
	# Set up camera structure
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.z = current_zoom
	camera.fov = 45.0
	camera_pivot.add_child(camera)
	
	# Apply initial tilt
	camera_pivot.rotation.x = deg_to_rad(current_tilt)
	
	# Spawn gems
	_spawn_gems()

func _spawn_gems():
	var gem_types = ["emerald", "garnet", "ruby", "sapphire", "topaz"]
	var player_scene = preload("res://characters/PlayerCharacter.tscn")
	
	for i in range(gem_types.size()):
		var player = player_scene.instantiate()
		player.name = "Player_" + gem_types[i]
		
		# Position gems in a line with spacing
		player.position.x = (i - 2) * 3.0  # Center around 0, 3 units apart
		player.position.z = 0
		
		# Load and set gem data
		var gem_data_path = "res://characters/data/classes/" + gem_types[i] + ".tres"
		if ResourceLoader.exists(gem_data_path):
			var gem_data = load(gem_data_path)
			player.gem_data = gem_data
		else:
			print("Warning: Gem data not found for " + gem_types[i])
		
		add_child(player)

func _process(delta):
	var move_vector = Vector3.ZERO
	var zoom_delta = 0.0
	var rotate_delta = 0.0
	var tilt_delta = 0.0
	
	# Keyboard input
	if Input.is_action_pressed("ui_right"):
		move_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		move_vector.x -= 1
	if Input.is_action_pressed("ui_up"):
		move_vector.z -= 1
	if Input.is_action_pressed("ui_down"):
		move_vector.z += 1
	
	# W/S for zoom
	if Input.is_key_pressed(KEY_W):
		zoom_delta -= 1
	if Input.is_key_pressed(KEY_S):
		zoom_delta += 1
	
	# A/D for rotation
	if Input.is_key_pressed(KEY_A):
		rotate_delta += 1
	if Input.is_key_pressed(KEY_D):
		rotate_delta -= 1
	
	# Q/E for tilt
	if Input.is_key_pressed(KEY_Q):
		tilt_delta += 1
	if Input.is_key_pressed(KEY_E):
		tilt_delta -= 1
	
	# Controller input
	var right_stick = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	move_vector.x += right_stick.x
	move_vector.z += right_stick.y
	
	# Left stick for zoom (vertical) and rotation (horizontal)
	var left_stick = Vector2(
		Input.get_axis("rotate_camera_left", "rotate_camera_right"),
		-Input.get_axis("camera_zoom_out", "camera_zoom_in")  # Inverted for intuitive control
	)
	rotate_delta -= left_stick.x
	zoom_delta += left_stick.y
	
	# Use tilt camera actions for Q/E functionality on controller
	if Input.is_action_pressed("tilt_camera_up"):
		tilt_delta += 1
	if Input.is_action_pressed("tilt_camera_down"):
		tilt_delta -= 1
	
	# Apply movement (relative to camera rotation)
	if move_vector.length() > 0:
		move_vector = move_vector.normalized()
		var rotated_move = move_vector.rotated(Vector3.UP, camera_pivot.rotation.y)
		camera_pivot.position += rotated_move * move_speed * delta
	
	# Apply rotation
	if abs(rotate_delta) > 0.1:
		camera_pivot.rotate_y(rotate_delta * rotate_speed * delta)
	
	# Apply zoom
	if abs(zoom_delta) > 0.1:
		current_zoom += zoom_delta * zoom_speed * delta
		current_zoom = clamp(current_zoom, min_zoom, max_zoom)
		camera.position.z = current_zoom
	
	# Apply tilt
	if abs(tilt_delta) > 0.1:
		current_tilt += tilt_delta * tilt_speed * rad_to_deg(1.0) * delta
		current_tilt = clamp(current_tilt, min_tilt, max_tilt)
		camera_pivot.rotation.x = deg_to_rad(current_tilt)