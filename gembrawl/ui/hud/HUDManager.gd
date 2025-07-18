## Combat UI Manager
## Manages the display of health bars and other combat UI elements

extends Control
class_name CombatUI

@export var health_bar_scene: PackedScene = preload("res://ui/hud/HealthBar.tscn")

var player1_health_bar: HealthBar
var player2_health_bar: HealthBar

func _ready() -> void:
	# Set up full screen container
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create health bars
	_create_health_bars()
	# CombatUI created with health bars

## Create health bar UI elements using containers
func _create_health_bars() -> void:
	# Create top margin
	var top_margin = MarginContainer.new()
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.add_theme_constant_override("margin_top", 20)
	top_margin.custom_minimum_size.y = 70
	add_child(top_margin)
	
	# Create horizontal container
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	top_margin.add_child(hbox)
	
	# Player 1 health bar (left aligned)
	player1_health_bar = health_bar_scene.instantiate() as HealthBar
	player1_health_bar.custom_minimum_size = Vector2(250, 50)
	player1_health_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(player1_health_bar)
	
	# Spacer to push player 2 to the right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Player 2 health bar (right aligned)
	player2_health_bar = health_bar_scene.instantiate() as HealthBar
	player2_health_bar.custom_minimum_size = Vector2(250, 50)
	player2_health_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(player2_health_bar)

## Set up health bars with player references
func setup_players(player1: Node3D, player2: Node3D) -> void:
	if player1_health_bar and player1:
		player1_health_bar.setup(player1, "Player 1")
	
	if player2_health_bar and player2:
		player2_health_bar.setup(player2, "Player 2") 
