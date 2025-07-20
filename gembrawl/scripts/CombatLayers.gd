## Combat layer configuration for GemBrawl
## Defines collision layers and masks for combat interactions
class_name CombatLayers
extends Object

## Layer definitions (bit positions)
enum Layer {
	WORLD = 0,           # Environment and obstacles
	PLAYER = 1,          # Player bodies
	PLAYER_HITBOX = 2,   # Player attack hitboxes
	ENEMY = 3,           # Enemy bodies (for future AI)
	ENEMY_HITBOX = 4,    # Enemy attack hitboxes
	PROJECTILE = 5,      # Moving projectiles
	PICKUP = 6,          # Collectible items
	HAZARD = 7           # Environmental hazards
}

## Get layer bit value
static func get_layer_bit(layer: Layer) -> int:
	return 1 << layer

## Get mask for what a layer can hit
static func get_combat_mask(layer: Layer) -> int:
	match layer:
		Layer.PLAYER:
			# Players collide with world, hazards, and pickups
			return get_layer_bit(Layer.WORLD) | get_layer_bit(Layer.HAZARD) | get_layer_bit(Layer.PICKUP)
		Layer.PLAYER_HITBOX:
			# Player attacks hit enemies and other players (for PvP)
			return get_layer_bit(Layer.ENEMY) | get_layer_bit(Layer.PLAYER)
		Layer.ENEMY:
			# Enemies collide with world and hazards
			return get_layer_bit(Layer.WORLD) | get_layer_bit(Layer.HAZARD)
		Layer.ENEMY_HITBOX:
			# Enemy attacks hit players
			return get_layer_bit(Layer.PLAYER)
		Layer.PROJECTILE:
			# Projectiles hit world, players, and enemies
			return get_layer_bit(Layer.WORLD) | get_layer_bit(Layer.PLAYER) | get_layer_bit(Layer.ENEMY)
		Layer.HAZARD:
			# Hazards don't actively collide with anything (they're detected by others)
			return 0
		_:
			return get_layer_bit(Layer.WORLD)

## Configure a collision body for combat
static func setup_combat_body(body: PhysicsBody3D, layer: Layer) -> void:
	body.collision_layer = get_layer_bit(layer)
	body.collision_mask = get_combat_mask(layer)

## Configure an area for combat detection
static func setup_combat_area(area: Area3D, layer: Layer) -> void:
	area.collision_layer = get_layer_bit(layer)
	area.collision_mask = get_combat_mask(layer)

## Common mask constants
const PLAYER_MASK = 1 << 1  # Bit mask for player layer 