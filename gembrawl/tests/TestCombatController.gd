## Test combat controller for testing combat mechanics
## Handles debug inputs and UI updates for combat testing
extends Node3D

@onready var player: Player3D = $Player
@onready var health_label: Label = $UI/DebugPanel/VBoxContainer/HealthLabel
@onready var lives_label: Label = $UI/DebugPanel/VBoxContainer/LivesLabel
@onready var status_label: Label = $UI/DebugPanel/VBoxContainer/StatusLabel

func _ready() -> void:
	# Connect player signals
	if player:
		player.health_changed.connect(_on_health_changed)
		player.lives_changed.connect(_on_lives_changed)
		player.defeated.connect(_on_player_defeated)
		player.became_spectator.connect(_on_became_spectator)
		player.respawning.connect(_on_respawning)
		
		# Update initial UI
		_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not player:
		return
		
	# Test damage
	if event.is_action_pressed("ui_select"):  # Spacebar
		# Test new damage system with different types
		_test_damage_system()
		#player.take_damage(25)  # Old method
		#print("Applied 25 damage to player")
		
	# Test instant kill
	if event.is_action_pressed("kill_test"):  # K key
		if player.gem_data:
			player.take_damage(player.gem_data.current_health + 100)
		print("Instant kill applied")
		
	# Test manual respawn
	if event.is_action_pressed("respawn_test"):  # R key
		var spawn_point = player._get_spawn_point()
		if spawn_point:
			player.respawn(spawn_point.global_position)
			print("Manual respawn triggered")

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_label.text = "Health: %d/%d" % [new_health, max_health]
	
func _on_lives_changed(new_lives: int, max_lives: int) -> void:
	lives_label.text = "Lives: %d/%d" % [new_lives, max_lives]
	
func _on_player_defeated() -> void:
	status_label.text = "Status: Defeated"
	
func _on_became_spectator() -> void:
	status_label.text = "Status: Spectator Mode"
	
func _on_respawning(time_remaining: float) -> void:
	if time_remaining > 0:
		status_label.text = "Status: Respawning in %d..." % int(time_remaining)
	else:
		status_label.text = "Status: Alive"
		
func _update_ui() -> void:
	if player and player.gem_data:
		health_label.text = "Health: %d/%d" % [player.gem_data.current_health, player.gem_data.max_health]
		lives_label.text = "Lives: %d/%d" % [player.current_lives, player.max_lives]
		
		if player.is_spectator:
			status_label.text = "Status: Spectator Mode"
		elif not player.is_alive:
			status_label.text = "Status: Defeated"
		else:
			status_label.text = "Status: Alive"

## Test the new damage system
func _test_damage_system() -> void:
	if not player:
		return
	
	# Cycle through different damage types
	var damage_types = [
		{"type": DamageSystem.DamageType.PHYSICAL, "name": "Physical"},
		{"type": DamageSystem.DamageType.MAGICAL, "name": "Magical"},
		{"type": DamageSystem.DamageType.TRUE, "name": "True"},
		{"type": DamageSystem.DamageType.ELEMENTAL, "name": "Elemental"}
	]
	
	# Pick a random damage type
	var damage_data = damage_types[randi() % damage_types.size()]
	
	# Create damage info
	var damage_info = DamageSystem.create_basic_attack(null, player, 25)
	damage_info.damage_type = damage_data.type
	damage_info.skill_name = "Test " + damage_data.name + " Attack"
	
	# Apply damage
	player.take_damage_info(damage_info)
	
	# Log the damage
	print("Applied %s damage: %d (after defenses: %d)%s" % [
		damage_data.name,
		damage_info.final_damage,
		damage_info.damage_dealt,
		" CRITICAL!" if damage_info.is_critical else ""
	]) 