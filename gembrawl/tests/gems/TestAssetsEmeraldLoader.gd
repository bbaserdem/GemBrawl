extends Node3D

func _ready():
	# Load the emerald gem model
	var gem_scene = load("res://assets/models/items/gem_emerald.glb")
	if gem_scene:
		var instance = gem_scene.instantiate()
		add_child(instance)
		print("Emerald gem model loaded successfully!")
		
		# Position it for better visibility
		instance.position = Vector3(0, 0, 0)
		
		# Add rotation animation for visual effect
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(instance, "rotation:y", TAU, 3.0)
		
		# Try to ensure hard edges on the mesh
		_ensure_hard_edges(instance)
		
		# Modify the material to be shiny and bright green
		_apply_emerald_material(instance)
	else:
		print("Failed to load emerald gem model")

func _apply_emerald_material(node: Node):
	# Find all MeshInstance3D nodes and apply custom material
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		print("Found MeshInstance3D: ", mesh_instance.name)
		
		# Try different shader approaches
		var shader_mode = "outlined"  # Options: "faceted", "outlined", "crystal", "standard", "transmission"
		
		match shader_mode:
			"faceted":
				# Use the new faceted gem shader for sharp angular appearance
				var shader = load("res://shaders/faceted_gem.gdshader")
				if shader:
					var shader_material = ShaderMaterial.new()
					shader_material.shader = shader
					
					# Set shader parameters for emerald
					shader_material.set_shader_parameter("gem_color", Color(0.1, 0.8, 0.3, 1.0))
					shader_material.set_shader_parameter("edge_color", Color(0.0, 0.3, 0.1, 1.0))
					shader_material.set_shader_parameter("edge_thickness", 0.15)
					shader_material.set_shader_parameter("light_levels", 3.0)
					shader_material.set_shader_parameter("specular_size", 0.2)
					shader_material.set_shader_parameter("specular_intensity", 1.8)
					shader_material.set_shader_parameter("facet_sharpness", 5.0)
					shader_material.set_shader_parameter("rim_light_power", 2.0)
					shader_material.set_shader_parameter("rim_light_intensity", 0.8)
					
					mesh_instance.material_override = shader_material
					print("Applied faceted gem shader")
				else:
					_apply_standard_emerald_material(mesh_instance)
			
			"outlined":
				# Use the outlined gem shader for cartoon-like angular appearance
				var shader = load("res://shaders/outlined_gem.gdshader")
				if shader:
					var shader_material = ShaderMaterial.new()
					shader_material.shader = shader
					
					# Set shader parameters for emerald
					shader_material.set_shader_parameter("gem_color", Color(0.1, 0.8, 0.3, 1.0))
					shader_material.set_shader_parameter("highlight_color", Color(0.5, 1.0, 0.6, 1.0))
					shader_material.set_shader_parameter("shadow_color", Color(0.05, 0.4, 0.15, 1.0))
					shader_material.set_shader_parameter("outline_color", Color(0.0, 0.2, 0.05, 1.0))
					shader_material.set_shader_parameter("light_threshold", 0.5)
					shader_material.set_shader_parameter("shadow_threshold", 0.3)
					shader_material.set_shader_parameter("outline_width", 0.02)
					
					mesh_instance.material_override = shader_material
					print("Applied outlined gem shader")
				else:
					_apply_standard_emerald_material(mesh_instance)
			
			"crystal":
				# Use the original crystal shader
				var shader = load("res://shaders/crystal_gem.gdshader")
				if shader:
					var shader_material = ShaderMaterial.new()
					shader_material.shader = shader
					
					# Set shader parameters for emerald
					shader_material.set_shader_parameter("albedo_color", Color(0.1, 0.8, 0.3, 1.0))
					shader_material.set_shader_parameter("roughness", 0.05)
					shader_material.set_shader_parameter("metallic", 0.0)
					shader_material.set_shader_parameter("specular", 1.0)
					shader_material.set_shader_parameter("rim_power", 2.5)
					shader_material.set_shader_parameter("rim_strength", 0.7)
					shader_material.set_shader_parameter("rim_color", Color(0.4, 1.0, 0.5, 1.0))
					shader_material.set_shader_parameter("fresnel_power", 3.0)
					shader_material.set_shader_parameter("fresnel_strength", 0.3)
					
					mesh_instance.material_override = shader_material
					print("Applied custom crystal shader")
				else:
					_apply_standard_emerald_material(mesh_instance)
			
			"standard":
				_apply_standard_emerald_material(mesh_instance)
			
			"transmission":
				# Use the configured gem material from the import settings
				# This ensures we're testing the actual material that will be used in-game
				print("Using imported material configuration")
				# Don't override - let the import settings handle the material
	
	# Recursively check children
	for child in node.get_children():
		_apply_emerald_material(child)

func _apply_standard_emerald_material(mesh_instance: MeshInstance3D):
	# Create a new shiny emerald material
	var emerald_material = StandardMaterial3D.new()

	# Bright green color - opaque
	emerald_material.albedo_color = Color(0.1, 0.8, 0.3, 1.0)  # Fully opaque

	# Make it reflective like a real gem
	emerald_material.metallic = 0.0  # Gems are not metallic
	emerald_material.roughness = 0.1  # Slightly more rough for better facet definition
	emerald_material.specular = 1.0  # Maximum specular reflection

	# CRITICAL: Enable vertex shading for flat/angular appearance
	emerald_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	emerald_material.vertex_color_use_as_albedo = false

	# Disable emission - no glow
	emerald_material.emission_enabled = false

	# No transparency - we want to see the edges clearly
	emerald_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

	# Disable subsurface scattering
	emerald_material.subsurf_scatter_enabled = false

	# Stronger rim lighting to emphasize edges
	emerald_material.rim_enabled = true
	emerald_material.rim = 0.5  # Increased for more edge definition
	emerald_material.rim_tint = 0.2  # Slight color tint for gemstone effect

	# No backlight
	emerald_material.backlight_enabled = false

	# Enable clearcoat for polished look without glow
	emerald_material.clearcoat_enabled = true
	emerald_material.clearcoat = 1.0  # Maximum clearcoat
	emerald_material.clearcoat_roughness = 0.0  # Perfectly smooth

	# Apply the material override
	mesh_instance.material_override = emerald_material

	print("Applied angular emerald material with flat shading")

func _ensure_hard_edges(node: Node):
	# Find all MeshInstance3D nodes and try to create hard edges
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh:
			print("Found mesh to process for hard edges")
			
			# Check if we can access the mesh arrays
			if mesh_instance.mesh is ArrayMesh:
				var array_mesh = mesh_instance.mesh as ArrayMesh
				print("Mesh surface count: ", array_mesh.get_surface_count())
				
				# Note: In Godot 4, we can't easily modify imported meshes at runtime
				# The best approach is to ensure the mesh is imported with hard edges
				# or use shaders to simulate the effect

	# Recursively check children
	for child in node.get_children():
		_ensure_hard_edges(child)
