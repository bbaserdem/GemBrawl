## Visual indicator for spawn points in test scenes
extends Marker3D

@export var color: Color = Color.CYAN
@export var size: float = 1.0

func _ready() -> void:
	# Get spawn point index from parent name or position in group
	var spawn_index = -1
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	for i in range(spawn_points.size()):
		if spawn_points[i] == self:
			spawn_index = i
			break
	
	# Set color based on index
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	if spawn_index >= 0 and spawn_index < colors.size():
		color = colors[spawn_index]
	else:
		color = Color.WHITE
	
	# Create visual indicator
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create cylinder mesh
	var cylinder = CylinderMesh.new()
	cylinder.height = 0.1
	cylinder.top_radius = size
	cylinder.bottom_radius = size
	mesh_instance.mesh = cylinder
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.5
	mesh_instance.material_override = material
	
	# Add pole to make it more visible
	var pole_mesh = MeshInstance3D.new()
	add_child(pole_mesh)
	
	var pole = CylinderMesh.new()
	pole.height = 2.0
	pole.top_radius = 0.05
	pole.bottom_radius = 0.05
	pole_mesh.mesh = pole
	pole_mesh.position.y = 1.0
	
	var pole_material = StandardMaterial3D.new()
	pole_material.albedo_color = color
	pole_material.albedo_color.a = 0.8
	pole_mesh.material_override = pole_material
	
	# Add label for spawn index
	if spawn_index >= 0:
		var label = Label3D.new()
		label.text = "S%d" % spawn_index
		label.position.y = 2.5
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	
	# Add rotation animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation:y", TAU, 2.0)
