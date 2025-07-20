## Debug script to test Player3D component loading
extends SceneTree

func _init():
	print("=== Testing Player3D Component Loading ===")
	
	# Load the PlayerCharacter scene
	var player_scene = load("res://characters/PlayerCharacter.tscn")
	if not player_scene:
		print("✗ Failed to load PlayerCharacter scene")
		quit()
		return
	
	print("✓ PlayerCharacter scene loaded")
	
	# Instantiate the player
	var player = player_scene.instantiate()
	if not player:
		print("✗ Failed to instantiate player")
		quit()
		return
	
	print("✓ Player instantiated")
	
	# Add to scene tree so _ready gets called
	get_root().add_child(player)
	
	# Wait a frame for _ready to complete
	await process_frame
	
	print("✓ Player _ready completed")
	
	# Check components
	print("\n=== Final Component State ===")
	print("movement: ", player.movement)
	print("combat: ", player.combat) 
	print("stats: ", player.stats)
	print("input: ", player.input)
	
	if player.movement:
		print("movement has process_movement: ", player.movement.has_method("process_movement"))
	
	player.queue_free()
	quit()