## Test controller for combat testing scenes
extends Node

@export var spawn_points: Array[Marker3D] = []
@export var player_scene: PackedScene
@export var enemy_gem_data: GemResource

var players: Array[Node3D] = []

func _ready() -> void:
	# Spawn test players at marked positions
	for i in range(spawn_points.size()):
		if i >= 2:  # Max 2 players for testing
			break
			
		var spawn_point = spawn_points[i]
		if player_scene:
			var player = player_scene.instantiate()
			add_child(player)
			player.global_position = spawn_point.global_position
			players.append(player)
			
			# Set gem data if available
			if player.has_method("set_gem_data"):
				if i == 0:
					player.set_gem_data(enemy_gem_data)
				else:
					# Second player uses different gem or default
					pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()
