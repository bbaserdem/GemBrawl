## Damage system for GemBrawl
## Handles all damage calculations, types, and modifiers
class_name DamageSystem
extends RefCounted

## Damage types enum
enum DamageType {
	PHYSICAL,    # Reduced by armor/defense
	MAGICAL,     # Reduced by magic resistance
	TRUE,        # Ignores all defenses
	ELEMENTAL    # Special type for gem-specific damage
}

## Critical hit configuration
const CRIT_CHANCE_BASE: float = 0.1  # 10% base crit chance
const CRIT_DAMAGE_MULTIPLIER: float = 1.5

## Damage calculation data
class DamageInfo extends RefCounted:
	var source: Node3D  # Who dealt the damage
	var target: Node3D  # Who receives the damage
	var base_damage: int
	var damage_type: DamageType = DamageType.PHYSICAL
	var is_critical: bool = false
	var multiplier: float = 1.0
	var is_dot: bool = false  # Damage over time flag
	var element: String = ""  # For elemental damage
	var skill_name: String = ""  # Skill that caused damage
	
	var final_damage: int = 0  # Calculated final damage
	var damage_dealt: int = 0  # Actual damage after defenses
	
	func _to_string() -> String:
		return "DamageInfo: %d %s damage from %s" % [damage_dealt, 
			DamageType.keys()[damage_type], 
			skill_name if skill_name else "basic attack"]
	
	func get_final_damage() -> int:
		return damage_dealt if damage_dealt > 0 else final_damage

## Calculate damage with all modifiers
static func calculate_damage(info: DamageInfo) -> DamageInfo:
	# Start with base damage
	info.final_damage = info.base_damage
	
	# Apply multipliers
	info.final_damage = int(info.final_damage * info.multiplier)
	
	# Check for critical hit
	if not info.is_critical and randf() < CRIT_CHANCE_BASE:
		info.is_critical = true
	
	if info.is_critical:
		info.final_damage = int(info.final_damage * CRIT_DAMAGE_MULTIPLIER)
	
	# Apply defenses based on damage type
	if info.target and info.target.has_method("get_defense_against"):
		var defense: int = info.target.get_defense_against(info.damage_type)
		match info.damage_type:
			DamageType.PHYSICAL:
				# Physical damage reduced by flat defense
				info.damage_dealt = max(1, info.final_damage - defense)
			DamageType.MAGICAL:
				# Magical damage reduced by percentage (defense as magic resist %)
				var reduction: float = min(0.75, defense / 100.0)  # Cap at 75% reduction
				info.damage_dealt = max(1, int(info.final_damage * (1.0 - reduction)))
			DamageType.TRUE:
				# True damage ignores defenses
				info.damage_dealt = info.final_damage
			DamageType.ELEMENTAL:
				# Elemental damage uses special calculation
				info.damage_dealt = _calculate_elemental_damage(info, defense)
	else:
		# No defense available, full damage
		info.damage_dealt = info.final_damage
	
	return info

## Calculate elemental damage with resistances/weaknesses
static func _calculate_elemental_damage(info: DamageInfo, defense: int) -> int:
	var damage: int = info.final_damage
	
	# Check for elemental interactions
	if info.target and info.target.has_method("get_element"):
		var target_element: String = info.target.get_element()
		var effectiveness: float = _get_element_effectiveness(info.element, target_element)
		damage = int(damage * effectiveness)
	
	# Apply general magic defense
	var reduction: float = min(0.5, defense / 150.0)  # Less reduction than pure magical
	return max(1, int(damage * (1.0 - reduction)))

## Get elemental effectiveness multiplier
static func _get_element_effectiveness(attacker_element: String, defender_element: String) -> float:
	# Rock-paper-scissors style: Ruby > Sapphire > Emerald > Ruby
	# Can be expanded with more gem types
	var effectiveness_chart: Dictionary = {
		"ruby": {"sapphire": 1.5, "emerald": 0.5, "ruby": 1.0},
		"sapphire": {"emerald": 1.5, "ruby": 0.5, "sapphire": 1.0},
		"emerald": {"ruby": 1.5, "sapphire": 0.5, "emerald": 1.0}
	}
	
	if attacker_element in effectiveness_chart and defender_element in effectiveness_chart[attacker_element]:
		return effectiveness_chart[attacker_element][defender_element]
	
	return 1.0  # Neutral damage

## Create a basic attack damage info
static func create_basic_attack(source: Node3D, target: Node3D, base_damage: int) -> DamageInfo:
	var info := DamageInfo.new()
	info.source = source
	info.target = target
	info.base_damage = base_damage
	info.damage_type = DamageType.PHYSICAL
	
	# Check if source has an element for basic attacks
	if source and source.has_method("get_element"):
		info.element = source.get_element()
	
	return info

## Create a skill damage info
static func create_skill_damage(source: Node3D, target: Node3D, base_damage: int, 
		skill_name: String, damage_type: DamageType = DamageType.PHYSICAL) -> DamageInfo:
	var info := DamageInfo.new()
	info.source = source
	info.target = target
	info.base_damage = base_damage
	info.damage_type = damage_type
	info.skill_name = skill_name
	
	# Skills often have higher crit chance
	if randf() < 0.15:  # 15% for skills
		info.is_critical = true
	
	return info

## Apply damage to target and return actual damage dealt
static func apply_damage(info: DamageInfo) -> int:
	# Calculate final damage
	calculate_damage(info)
	
	# Apply to target if it has take_damage method
	if info.target and info.target.has_method("take_damage"):
		info.target.take_damage(info.damage_dealt, info.source)
	
	# Emit damage event for UI/effects
	if info.source and info.source.has_signal("damage_dealt"):
		info.source.damage_dealt.emit(info)
	
	return info.damage_dealt 