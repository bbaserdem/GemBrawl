## Base Gem class for all gem types in GemBrawl
## This class defines the core attributes and behaviors shared by all gems
class_name Gem
extends Resource

## Visual properties
@export var gem_name: String = ""
@export var color: Color = Color.WHITE
@export var texture: Texture2D

## Combat stats
@export var max_health: int = 100
@export var current_health: int = 100
@export var base_damage: int = 10
@export var defense: int = 5

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
	var actual_damage: int = max(0, damage - defense)
	current_health -= actual_damage
	return current_health <= 0

## Heal the gem
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)

## Get current health percentage
func get_health_percentage() -> float:
	return float(current_health) / float(max_health) 