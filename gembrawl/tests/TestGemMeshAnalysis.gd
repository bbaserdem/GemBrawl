extends Node3D

func _ready():
	# Load and analyze the gem mesh
	var gem_scene = load("res://assets/models/items/gem_ruby.glb")
	if gem_scene:
		var instance = gem_scene.instantiate()
		add_child(instance)
		
		# Find mesh instance
		var mesh_instance = _find_mesh_instance(instance)
		if mesh_instance and mesh_instance.mesh:
			print("=== GEM MESH ANALYSIS ===")
			var mesh = mesh_instance.mesh
			
			if mesh is ArrayMesh:
				var array_mesh = mesh as ArrayMesh
				print("Surface count: ", array_mesh.get_surface_count())
				
				for i in range(array_mesh.get_surface_count()):
					print("\nSurface ", i, ":")
					var arrays = array_mesh.surface_get_arrays(i)
					
					# Check vertices
					if arrays[Mesh.ARRAY_VERTEX]:
						var vertices = arrays[Mesh.ARRAY_VERTEX]
						print("  Vertex count: ", vertices.size())
						
					# Check normals
					if arrays[Mesh.ARRAY_NORMAL]:
						var normals = arrays[Mesh.ARRAY_NORMAL]
						print("  Normal count: ", normals.size())
						
						# Check for zero or invalid normals
						var invalid_normals = 0
						for normal in normals:
							if normal.length() < 0.9 or normal.length() > 1.1:
								invalid_normals += 1
						if invalid_normals > 0:
							print("  WARNING: ", invalid_normals, " invalid normals found!")
					else:
						print("  WARNING: No normals found!")
					
					# Check material
					var material = array_mesh.surface_get_material(i)
					if material:
						print("  Material: ", material.resource_path if material.resource_path else material.get_class())
						if material is ShaderMaterial:
							print("    Shader: ", material.shader.resource_path if material.shader else "None")
						elif material is StandardMaterial3D:
							print("    Cull mode: ", material.cull_mode)
							print("    Shading mode: ", material.shading_mode)
					
					# Check primitive type
					var primitive = array_mesh.surface_get_primitive_type(i)
					print("  Primitive type: ", ["POINTS", "LINES", "LINE_STRIP", "TRIANGLES", "TRIANGLE_STRIP"][primitive])
		
		# Add simple rotation for viewing
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(instance, "rotation:y", TAU, 3.0)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null