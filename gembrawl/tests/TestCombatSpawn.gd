## Test controller for spawn manager functionality
extends Node

@onready var player: Player3D = $Player
@onready var ui_panel: Panel = $UI/DebugPanel
@onready var health_label: Label = $UI/DebugPanel/VBoxContainer/HealthLabel
@onready var lives_label: Label = $UI/DebugPanel/VBoxContainer/LivesLabel
@onready var status_label: Label = $UI/DebugPanel/VBoxContainer/StatusLabel
@onready var spawn_info_label: Label  # Will be set dynamically

var damage_types = ["Physical", "Magical", "True", "Elemental"]
var current_damage_type = 0

func _ready() -> void:
	# Connect player signals
	if player:
		player.health_changed.connect(_on_health_changed)
		player.lives_changed.connect(_on_lives_changed)
		player.became_spectator.connect(_on_became_spectator)
		player.respawning.connect(_on_respawning)
		player.damage_received.connect(_on_damage_received)
		
		# Set initial UI
		_update_ui()
	
	# Update spawn manager settings
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		# Add spawn mode controls
		_add_spawn_mode_controls()
		# Defer spawn info update to ensure spawn points are registered
		call_deferred("_update_spawn_info")

func _add_spawn_mode_controls() -> void:
	var vbox = $UI/DebugPanel/VBoxContainer
	
	# Add separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Add spawn mode label
	var mode_label = Label.new()
	mode_label.name = "SpawnModeLabel"
	vbox.add_child(mode_label)
	
	# Add spawn info label
	var info_label = Label.new()
	info_label.text = "Spawn Points: 0"
	info_label.name = "SpawnInfoLabel"
	vbox.add_child(info_label)
	spawn_info_label = info_label
	
	# Update initial spawn mode display
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		var modes = ["ASSIGNED", "RANDOM", "SEQUENTIAL", "FARTHEST"]
		mode_label.text = "Spawn Mode: " + modes[spawn_manager.spawn_mode]

func _input(event: InputEvent) -> void:
	if not player:
		return
	
	# Debug key presses
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_M or event.physical_keycode == KEY_T:
			print("Physical key pressed: ", OS.get_keycode_string(event.physical_keycode))
	
	# Damage test (Space)
	if event.is_action_pressed("use_skill"):
		_apply_test_damage()
	
	# Manual respawn (R)
	elif event.is_action_pressed("respawn_test"):
		if player.stats and not player.stats.is_alive:
			var spawn_manager = get_node_or_null("/root/SpawnManager")
			if spawn_manager:
				player.respawn(spawn_manager.get_spawn_point(player))
	
	# Instant kill (K)
	elif event.is_action_pressed("kill_test"):
		if player.gem_data:
			var damage_info = DamageSystem.DamageInfo.new()
			damage_info.base_damage = 9999
			damage_info.damage_type = DamageSystem.DamageType.TRUE
			damage_info.source = self
			damage_info.is_critical = false
			player.take_damage_info(damage_info)
	
	# Cycle spawn modes (M)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_M:
		_cycle_spawn_mode()
	
	# Cycle spawn point assignment (T)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_T:
		_cycle_spawn_point()

func _cycle_spawn_mode() -> void:
	print("Cycling spawn mode...")
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if not spawn_manager:
		print("No spawn manager found!")
		return
	
	var modes = ["ASSIGNED", "RANDOM", "SEQUENTIAL", "FARTHEST"]
	spawn_manager.spawn_mode = (spawn_manager.spawn_mode + 1) % 4  # SpawnMode enum size
	print("New spawn mode: ", modes[spawn_manager.spawn_mode])
	
	# If switching to ASSIGNED mode and player has no spawn, assign one
	if spawn_manager.spawn_mode == spawn_manager.SpawnMode.ASSIGNED:
		if not spawn_manager.player_spawn_assignments.has(player):
			spawn_manager._assign_spawn_point(player)
			print("Assigned initial spawn point to player")
	
	var vbox = $UI/DebugPanel/VBoxContainer
	var mode_label = vbox.get_node_or_null("SpawnModeLabel")
	if mode_label:
		mode_label.text = "Spawn Mode: " + modes[spawn_manager.spawn_mode]
	else:
		print("Mode label not found in VBoxContainer!")
	
	_update_spawn_info()

func _cycle_spawn_point() -> void:
	print("Cycling spawn point...")
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if not spawn_manager:
		print("No spawn manager found!")
		return
	
	# Ensure player has a spawn assignment before cycling
	if not spawn_manager.player_spawn_assignments.has(player):
		spawn_manager._assign_spawn_point(player)
		print("Assigned initial spawn point to player")
	
	spawn_manager.cycle_player_spawn(player)
	print("Spawn point cycled")
	_update_spawn_info()

func _apply_test_damage() -> void:
	if not player.gem_data or not player.stats.is_alive:
		return
	
	# Create damage info
	var damage_info = DamageSystem.DamageInfo.new()
	damage_info.base_damage = randi_range(10, 30)
	damage_info.damage_type = current_damage_type
	damage_info.source = self
	damage_info.is_critical = randf() < 0.2  # 20% crit chance for testing
	
	# Apply damage
	player.take_damage_info(damage_info)
	
	# Cycle damage type
	current_damage_type = (current_damage_type + 1) % damage_types.size()
	print("Next damage type: ", damage_types[current_damage_type])

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_label.text = "Health: %d/%d" % [new_health, max_health]
	# Update status when health is restored (respawn)
	if new_health == max_health and player.stats and player.stats.is_alive:
		status_label.text = "Status: Alive"
		status_label.modulate = Color.WHITE

func _on_lives_changed(new_lives: int, max_lives: int) -> void:
	lives_label.text = "Lives: %d/%d" % [new_lives, max_lives]

func _on_became_spectator() -> void:
	status_label.text = "Status: SPECTATOR"
	status_label.modulate = Color.GRAY

func _on_respawning(time_left: float) -> void:
	if time_left > 0:
		status_label.text = "Respawning in: %.1f" % time_left
		status_label.modulate = Color.YELLOW
	else:
		status_label.text = "Status: Alive"
		status_label.modulate = Color.WHITE
		_update_ui()

func _on_damage_received(damage_info: DamageSystem.DamageInfo) -> void:
	# Show damage in status
	var damage_text = "%d %s damage" % [damage_info.final_damage, damage_types[damage_info.damage_type]]
	if damage_info.is_critical:
		damage_text += " (CRIT!)"
	
	print(damage_text)

func _update_ui() -> void:
	if player and player.gem_data:
		health_label.text = "Health: %d/%d" % [player.gem_data.current_health, player.gem_data.max_health]
		
		if player.stats:
			lives_label.text = "Lives: %d/%d" % [player.stats.current_lives, player.stats.max_lives]
			
			if player.stats.is_spectator:
				status_label.text = "Status: SPECTATOR"
				status_label.modulate = Color.GRAY
			elif player.stats.is_alive:
				status_label.text = "Status: Alive"
				status_label.modulate = Color.WHITE
			else:
				status_label.text = "Status: Dead"
				status_label.modulate = Color.RED

func _update_spawn_info() -> void:
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if not spawn_manager or not spawn_info_label:
		return
	
	var info = spawn_manager.get_spawn_points_info()
	var text = "Spawn Points: %d total" % info.total_spawns
	
	# Show player's assigned spawn point if in ASSIGNED mode
	if spawn_manager.spawn_mode == spawn_manager.SpawnMode.ASSIGNED:
		var player_spawn = spawn_manager.player_spawn_assignments.get(player)
		if player_spawn:
			text += "\nYour spawn: S%d" % player_spawn.index
		else:
			text += "\nYour spawn: None"
	
	if info.active_respawns > 0:
		text += "\nActive Respawns: %d" % info.active_respawns
	
	spawn_info_label.text = text