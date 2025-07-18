## Health Bar UI Component - migrated from prototype `game/scripts/ui/health_bar.gd`
extends Control
class_name HealthBar

@onready var health_progress: ProgressBar = $HealthProgress
@onready var label: Label = $Label

var player_name: String = "Player"
var current_health: int = 100
var max_health: int = 100

func _ready() -> void:
	var health_style := StyleBoxFlat.new()
	health_style.bg_color = Color(0.2, 0.8, 0.2)
	health_style.corner_radius_top_left = 2
	health_style.corner_radius_top_right = 2
	health_style.corner_radius_bottom_right = 2
	health_style.corner_radius_bottom_left = 2
	health_progress.add_theme_stylebox_override("fill", health_style)

func setup(player: Node3D, name: String) -> void:
	player_name = name
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	if player.get("gem_data") != null:
		var gem = player.gem_data
		current_health = gem.current_health
		max_health = gem.max_health
		_update_display()

func _on_health_changed(new_health: int, new_max_health: int) -> void:
	current_health = new_health
	max_health = new_max_health
	_update_display()

func _update_display() -> void:
	if max_health > 0:
		health_progress.value = (float(current_health) / float(max_health)) * 100.0
	else:
		health_progress.value = 0.0
	label.text = "%s: %d/%d" % [player_name, current_health, max_health]
	var health_percentage := health_progress.value / 100.0
	var health_style := health_progress.get_theme_stylebox("fill") as StyleBoxFlat
	if health_style:
		if health_percentage > 0.6:
			health_style.bg_color = Color(0.2, 0.8, 0.2)
		elif health_percentage > 0.3:
			health_style.bg_color = Color(0.8, 0.8, 0.2)
		else:
			health_style.bg_color = Color(0.8, 0.2, 0.2) 