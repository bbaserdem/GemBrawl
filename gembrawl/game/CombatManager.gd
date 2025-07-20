## Combat manager for GemBrawl
## Manages global combat state, hit registration, and combat events
extends Node

## Combat settings
@export var friendly_fire: bool = true
@export var combo_window: float = 2.0
@export var global_damage_multiplier: float = 1.0

## Combat tracking
var active_projectiles: Array[Projectile] = []
var active_aoes: Array[AoeAttack] = []
var recent_hits: Array[Dictionary] = []  # Track recent hits for combos

## Signals
signal combat_hit(attacker: Node3D, target: Node3D, damage_info: DamageSystem.DamageInfo)
signal player_killed(victim: IPlayer, killer: Node3D)
signal combo_achieved(player: IPlayer, combo_count: int)

func _ready() -> void:
	pass
	process_mode = Node.PROCESS_MODE_ALWAYS

## Register a combat hit
## Tracks hits for combo detection, applies global modifiers, and checks friendly fire rules
## @param attacker: The node dealing damage
## @param target: The node receiving damage
## @param damage_info: Damage information including type, amount, and modifiers
func register_hit(attacker: Node3D, target: Node3D, damage_info: DamageSystem.DamageInfo) -> void:
	# Apply global damage multiplier
	damage_info.multiplier *= global_damage_multiplier
	
	# Check friendly fire
	if not friendly_fire and _are_teammates(attacker, target):
		return
	
	# Track hit for combos
	var hit_data = {
		"attacker": attacker,
		"target": target,
		"damage": damage_info.get_final_damage(),
		"time": Time.get_ticks_msec() / 1000.0,
		"skill_name": damage_info.skill_name
	}
	recent_hits.append(hit_data)
	
	# Check for combos
	_check_combos(attacker)
	
	# Clean old hits
	_clean_old_hits()
	
	# Emit signal
	combat_hit.emit(attacker, target, damage_info)

## Register player death
## Cleans up victim's active projectiles/AoEs and emits death signal
## @param victim: The player who died
## @param killer: The node that caused the death (optional)
func register_player_death(victim: IPlayer, killer: Node3D = null) -> void:
	player_killed.emit(victim, killer)
	
	# Clear victim's projectiles
	for projectile in active_projectiles:
		if projectile.owner_player == victim:
			projectile.queue_free()
	
	# Clear victim's AoEs
	for aoe in active_aoes:
		if aoe.owner_player == victim:
			aoe.queue_free()

## Register a projectile
func register_projectile(projectile: Projectile) -> void:
	active_projectiles.append(projectile)
	projectile.tree_exited.connect(_on_projectile_removed.bind(projectile))

## Register an AoE
func register_aoe(aoe: AoeAttack) -> void:
	active_aoes.append(aoe)
	aoe.tree_exited.connect(_on_aoe_removed.bind(aoe))

## Check if two nodes are teammates
func _are_teammates(node1: Node3D, node2: Node3D) -> bool:
	# In PvP all players are enemies
	# This could be expanded for team modes
	return false

## Check for combo achievements
## Analyzes recent hits to detect combo chains within the combo window
## Emits combo_achieved signal when 3+ hits are chained
## @param attacker: The player to check combos for
func _check_combos(attacker: Node3D) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var combo_count = 0
	var combo_damage = 0
	
	for hit in recent_hits:
		if hit.attacker == attacker and current_time - hit.time <= combo_window:
			combo_count += 1
			combo_damage += hit.damage
	
	if combo_count >= 3:
		combo_achieved.emit(attacker, combo_count)

## Clean old hit records
func _clean_old_hits() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	recent_hits = recent_hits.filter(func(hit): 
		return current_time - hit.time <= combo_window * 2
	)

## Handle projectile removal
func _on_projectile_removed(projectile: Projectile) -> void:
	active_projectiles.erase(projectile)

## Handle AoE removal  
func _on_aoe_removed(aoe: AoeAttack) -> void:
	active_aoes.erase(aoe)

## Get active combat entities near position
## Returns all players within the specified radius of a position
## Useful for AoE effects and proximity-based mechanics
## @param position: Center position to search from
## @param radius: Search radius in world units
## @return: Array of Node3D entities within range
func get_combat_entities_near(position: Vector3, radius: float) -> Array[Node3D]:
	var entities: Array[Node3D] = []
	var players = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if player.global_position.distance_to(position) <= radius:
			entities.append(player)
	
	return entities

## Apply screen shake (call on main camera)
func apply_screen_shake(intensity: float = 1.0, duration: float = 0.2) -> void:
	# This would connect to camera controller
	pass 