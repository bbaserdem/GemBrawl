## Camera Controller for adjusting isometric view
extends Camera2D

@export var adjust_speed: float = 30.0  # Degrees per second
@export var min_angle: float = 15.0
@export var max_angle: float = 75.0

var arena_node: Node2D

func _ready() -> void:
	# Find the arena node to adjust its isometric angle
	arena_node = get_parent()
	print("Camera Controller Ready - Arena node: ", arena_node)
	if arena_node and "isometric_angle" in arena_node:
		print("Found isometric_angle property: ", arena_node.isometric_angle)
	
	# Ensure this node processes input
	set_process_input(true)
	
func _process(delta: float) -> void:
	if not arena_node or not arena_node.has_method("queue_redraw"):
		return
		
	if not "isometric_angle" in arena_node:
		push_warning("Arena node doesn't have isometric_angle property")
		return
		
	# Camera angle adjustment is now handled in _input()
	pass

func update_player_movement_angle(angle: float) -> void:
	# Update any player nodes to use the same angle
	var player = get_node_or_null("../Player")  # Player is sibling of Camera2D
	if player and player.has_method("set_isometric_angle"):
		player.set_isometric_angle(angle)

func _input(event: InputEvent) -> void:
	# Debug all key events
	if event is InputEventKey and event.pressed:
		print("Key pressed: ", event.keycode, " Physical: ", event.physical_keycode)
		
	# Camera angle controls
	if event.is_action_pressed("ui_page_up"):
		print("Page Up action detected!")
		adjust_angle(adjust_speed / 10.0)  # Adjust by a fixed amount per press
	elif event.is_action_pressed("ui_page_down"):
		print("Page Down action detected!")
		adjust_angle(-adjust_speed / 10.0)
		
	# Also try direct key detection as fallback
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_PAGEUP:
			print("Direct Page Up key detected!")
			adjust_angle(adjust_speed / 10.0)
		elif event.physical_keycode == KEY_PAGEDOWN:
			print("Direct Page Down key detected!")
			adjust_angle(-adjust_speed / 10.0)
	
	# Zoom controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom *= 0.9
		
		# Clamp zoom
		zoom = zoom.clamp(Vector2(0.2, 0.2), Vector2(2.0, 2.0))

func adjust_angle(delta_angle: float) -> void:
	if not arena_node or not "isometric_angle" in arena_node:
		print("Cannot adjust angle - arena node not ready")
		return
		
	var current_angle = arena_node.isometric_angle
	current_angle = clamp(current_angle + delta_angle, min_angle, max_angle)
	arena_node.isometric_angle = current_angle
	arena_node.queue_redraw()
	update_player_movement_angle(current_angle)
	print("Adjusted angle to: ", current_angle) 
