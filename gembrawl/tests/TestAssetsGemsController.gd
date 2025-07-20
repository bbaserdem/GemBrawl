extends Node3D

const PlayerCharacter = preload("res://characters/PlayerCharacter.tscn")

@onready var camera_controller = $CameraController
@onready var hex_arena = $HexArena
@onready var status_label = $UI/VBoxContainer/StatusLabel
@onready var gems_container = $GemsContainer

var gem_data_files = []
var spawned_gems = []

# Camera movement variables
var camera_move_speed = 10.0
var camera_rotate_speed = 2.0
var camera_tilt_speed = 1.0
var camera_rotation = 0.0
var camera_tilt = 45.0

func _ready():
	status_label.text = "Loading gem data..."
	
	# Load all gem data files
	_load_gem_data_files()
	
	# Spawn gems in a grid layout
	_spawn_gem_showcase()
	
	# Set initial camera position
	_setup_camera()

func _load_gem_data_files():
	var dir = DirAccess.open("res://characters/data/classes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") and file_name != "GemResource.gd":
				var gem_path = "res://characters/data/classes/" + file_name
				var gem_data = load(gem_path)
				if gem_data:
					gem_data_files.append({
						"name": file_name.trim_suffix(".tres"),
						"path": gem_path,
						"data": gem_data
					})
			file_name = dir.get_next()
		dir.list_dir_end()
	
	status_label.text = "Found %d gem types" % gem_data_files.size()

func _spawn_gem_showcase():
	# Clear existing gems
	for gem in spawned_gems:
		if is_instance_valid(gem):
			gem.queue_free()
	spawned_gems.clear()
	
	# Calculate grid layout
	var gems_per_row = 3
	var row_spacing = 4.0
	var col_spacing = 3.5
	
	status_label.text = "Spawning all gems..."
	
	# Spawn all gems at once without async operations
	for i in range(gem_data_files.size()):
		var gem_info = gem_data_files[i]
		var row = i / gems_per_row
		var col = i % gems_per_row
		
		# Calculate position
		var x_offset = (col - float(gems_per_row - 1) / 2.0) * col_spacing
		var z_offset = row * row_spacing - 2.0  # Center it a bit
		
		# Spawn character
		var character = PlayerCharacter.instantiate()
		gems_container.add_child(character)
		
		# Set gem data immediately
		if gem_info.data:
			character.gem_data = gem_info.data
		
		character.global_position = Vector3(x_offset, 0, z_offset)
		
		# Disable player input and movement components
		_disable_character_components(character)
		
		# Add label above gem
		var label_3d = Label3D.new()
		label_3d.text = gem_info.name.capitalize()
		label_3d.position = Vector3(0, 2.0, 0)
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label_3d.no_depth_test = true
		label_3d.outline_size = 10
		label_3d.modulate = Color(1, 1, 1, 1)
		character.add_child(label_3d)
		
		spawned_gems.append(character)
	
	status_label.text = "All %d gem types displayed!" % gem_data_files.size()

func _disable_character_components(character: Node3D):
	# Disable input
	if character.has_node("Input"):
		character.get_node("Input").queue_free()
	
	# Disable movement
	if character.has_node("Movement"):
		character.get_node("Movement").set_physics_process(false)
		character.get_node("Movement").set_process(false)
	
	# Disable combat
	if character.has_node("Combat"):
		character.get_node("Combat").set_physics_process(false)
		character.get_node("Combat").set_process(false)

# Material application is handled by PlayerCharacter._apply_gem_properties()
# No need for manual material override

func _setup_camera():
	if not camera_controller:
		return
		
	# Position camera to view all gems
	camera_controller.global_position = Vector3(0, 8, 12)
	camera_controller.rotation = Vector3(-deg_to_rad(camera_tilt), deg_to_rad(camera_rotation), 0)
	
	# Disable the CameraController script's built-in controls
	if camera_controller.has_method("set_physics_process"):
		camera_controller.set_physics_process(false)
	if camera_controller.has_method("set_process"):
		camera_controller.set_process(false)

func _process(delta):
	if not camera_controller:
		return
	
	# Camera movement (ASDF or left joystick)
	var move_input = Vector3.ZERO
	
	# Keyboard input
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_input.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_input.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_input.z -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_input.z += 1
	
	# Gamepad left stick
	if Input.get_connected_joypads().size() > 0:
		var left_stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var left_stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Apply deadzone
		if abs(left_stick_x) > 0.15:
			move_input.x += left_stick_x
		if abs(left_stick_y) > 0.15:
			move_input.z += left_stick_y
	
	# Apply movement relative to camera rotation
	if move_input.length() > 0:
		move_input = move_input.normalized()
		var cam_transform = camera_controller.global_transform.basis
		move_input = cam_transform * move_input
		move_input.y = 0  # Keep movement horizontal
		camera_controller.global_position += move_input * camera_move_speed * delta
	
	# Camera rotation (left/right arrows or right stick horizontal)
	var rotate_input = 0.0
	
	if Input.is_key_pressed(KEY_LEFT):
		rotate_input += 1
	if Input.is_key_pressed(KEY_RIGHT):
		rotate_input -= 1
	
	# Gamepad right stick horizontal
	if Input.get_connected_joypads().size() > 0:
		var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		if abs(right_stick_x) > 0.15:
			rotate_input -= right_stick_x
	
	if rotate_input != 0:
		camera_rotation += rotate_input * camera_rotate_speed * rad_to_deg(delta)
		camera_controller.rotation.y = deg_to_rad(camera_rotation)
	
	# Camera tilt (up/down arrows or right stick vertical)
	var tilt_input = 0.0
	
	if Input.is_key_pressed(KEY_UP):
		tilt_input += 1
	if Input.is_key_pressed(KEY_DOWN):
		tilt_input -= 1
	
	# Gamepad right stick vertical
	if Input.get_connected_joypads().size() > 0:
		var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if abs(right_stick_y) > 0.15:
			tilt_input += right_stick_y
	
	if tilt_input != 0:
		camera_tilt = clamp(camera_tilt + tilt_input * camera_tilt_speed * rad_to_deg(delta), 15, 75)
		camera_controller.rotation.x = -deg_to_rad(camera_tilt)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_R:
				# Reset camera
				camera_rotation = 0.0
				camera_tilt = 45.0
				_setup_camera()
			KEY_SPACE:
				# Rotate all gems
				for gem in spawned_gems:
					if is_instance_valid(gem):
						gem.rotate_y(PI / 4)