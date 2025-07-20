## Visual indicator for spawn points
## Adds a semi-transparent sphere to show spawn locations
class_name SpawnPointVisual
extends Marker3D

var mesh_instance: MeshInstance3D
var spawn_color: Color = Color(0.2, 1.0, 0.2, 0.5)

func _ready() -> void:
	# Create visual indicator
	mesh_instance = MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	
	mesh_instance.mesh = sphere_mesh
	
	# Create semi-transparent material
	var material := StandardMaterial3D.new()
	material.albedo_color = spawn_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = spawn_color
	material.emission_energy = 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	# Add floating animation
	_start_float_animation()

## Set the spawn point color
func set_spawn_color(color: Color) -> void:
	spawn_color = color
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color
		mesh_instance.material_override.emission = color

## Start floating animation
func _start_float_animation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	
	# Float up and down
	tween.tween_property(mesh_instance, "position:y", 0.3, 2.0)
	tween.tween_property(mesh_instance, "position:y", -0.3, 2.0) 