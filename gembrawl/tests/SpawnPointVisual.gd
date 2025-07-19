## Visual indicator for spawn points in test scenes
extends Marker3D

@export var color: Color = Color.CYAN
@export var size: float = 1.0

func _ready() -> void:
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
	
	# Add rotation animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation:y", TAU, 2.0)
