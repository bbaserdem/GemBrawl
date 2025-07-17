## Health Bar UI Component
## Displays a player's current health with a progress bar and text label

extends Control
class_name HealthBar

@onready var health_progress: ProgressBar = $HealthProgress
@onready var label: Label = $Label

var player_name: String = "Player"
var current_health: int = 100
var max_health: int = 100

func _ready() -> void:
	# Set up progress bar colors
	var health_style = StyleBoxFlat.new()
	health_style.bg_color = Color(0.2, 0.8, 0.2)  # Green
	health_style.corner_radius_top_left = 2
	health_style.corner_radius_top_right = 2
	health_style.corner_radius_bottom_right = 2
	health_style.corner_radius_bottom_left = 2
	
	health_progress.add_theme_stylebox_override("fill", health_style)

## Set up the health bar with player info
func setup(player: Node3D, name: String) -> void:
	player_name = name
	
	# Connect to player's health_changed signal
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	
	# Get initial health values
	if player.get("gem_data") != null:
		var gem = player.gem_data
		current_health = gem.current_health
		max_health = gem.max_health
		_update_display()

## Update health display when health changes
func _on_health_changed(new_health: int, new_max_health: int) -> void:
	current_health = new_health
	max_health = new_max_health
	_update_display()

## Update the visual display
func _update_display() -> void:
	# Update progress bar
	if max_health > 0:
		health_progress.value = (float(current_health) / float(max_health)) * 100.0
	else:
		health_progress.value = 0.0
	
	# Update label
	label.text = "%s: %d/%d" % [player_name, current_health, max_health]
	
	# Change color based on health percentage
	var health_percentage = health_progress.value / 100.0
	var health_style = health_progress.get_theme_stylebox("fill") as StyleBoxFlat
	
	if health_style:
		if health_percentage > 0.6:
			health_style.bg_color = Color(0.2, 0.8, 0.2)  # Green
		elif health_percentage > 0.3:
			health_style.bg_color = Color(0.8, 0.8, 0.2)  # Yellow
		else:
			health_style.bg_color = Color(0.8, 0.2, 0.2)  # Red 