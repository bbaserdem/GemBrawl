## Base GemResource class for all gem types in GemBrawl
## This class defines the core attributes and behaviors shared by all gems
class_name GemResource
extends Resource

## Visual properties
@export var gem_name: String = ""
@export var color: Color = Color.WHITE
@export var texture: Texture2D
@export var model_path: String = ""  # Path to 3D model (GLB/GLTF)
@export var element: String = ""  # Gem element type (ruby, sapphire, emerald, etc.)

## Combat stats
@export var max_health: int = 100
@export var current_health: int = 100
@export var base_damage: int = 10
@export var defense: int = 5  # Physical defense
@export var magic_resistance: int = 10  # Magical defense (as percentage)
@export var crit_chance_bonus: float = 0.0  # Additional crit chance

## Movement properties
@export var movement_speed: float = 300.0
@export var dash_speed: float = 600.0

## Skill properties
@export var skill_cooldown: float = 5.0
@export var skill_damage_multiplier: float = 1.5

## Initialize gem with default values
func _init() -> void:
	current_health = max_health

## Take damage and return true if gem is defeated
func take_damage(damage: int) -> bool:
	# Damage has already been calculated with defenses by DamageSystem
	# Don't apply defense again!
	current_health -= damage
	current_health = max(0, current_health)  # Prevent negative health
	return current_health <= 0

## Heal the gem
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)

## Get current health percentage
func get_health_percentage() -> float:
	return float(current_health) / float(max_health) 
