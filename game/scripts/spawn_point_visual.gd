## Visual indicator for spawn points
## Adds a semi-transparent sphere to show spawn locations
extends Marker3D

func _ready() -> void:
	# Create visual indicator
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	
	mesh_instance.mesh = sphere_mesh
	
	# Create semi-transparent material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	add_child(mesh_instance) 