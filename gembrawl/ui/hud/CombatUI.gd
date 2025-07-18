## Combat UI Manager - migrated from prototype `game/scripts/ui/combat_ui.gd`
extends Control
class_name CombatUI

@export var health_bar_scene: PackedScene = preload("res://ui/hud/HealthBar.tscn")

var player1_health_bar: HealthBar
var player2_health_bar: HealthBar

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_health_bars()

## Create health bar UI elements using containers
func _create_health_bars() -> void:
	var top_margin := MarginContainer.new()
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.add_theme_constant_override("margin_top", 20)
	top_margin.custom_minimum_size.y = 70
	add_child(top_margin)
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	top_margin.add_child(hbox)
	
	player1_health_bar = health_bar_scene.instantiate() as HealthBar
	player1_health_bar.custom_minimum_size = Vector2(250, 50)
	player1_health_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(player1_health_bar)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	player2_health_bar = health_bar_scene.instantiate() as HealthBar
	player2_health_bar.custom_minimum_size = Vector2(250, 50)
	player2_health_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(player2_health_bar)

func setup_players(player1: Node3D, player2: Node3D) -> void:
	if player1_health_bar and player1:
		player1_health_bar.setup(player1, "Player 1")
	if player2_health_bar and player2:
		player2_health_bar.setup(player2, "Player 2") 