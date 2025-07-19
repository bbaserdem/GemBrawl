extends Node3D

func _ready():
	# Load the ruby gem model
	var gem_scene = load("res://assets/models/items/gem_ruby.glb")
	if gem_scene:
		var instance = gem_scene.instantiate()
		add_child(instance)
		print("Ruby gem model loaded successfully!")
		
		# Position it for better visibility
		instance.position = Vector3(0, 0, 0)
		
		# Add rotation animation for visual effect
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(instance, "rotation:y", TAU, 3.0)
		
		# Try to ensure hard edges on the mesh
		_ensure_hard_edges(instance)
		
		# Modify the material to be shiny and brighter red
		_apply_ruby_material(instance)
	else:
		print("Failed to load ruby gem model")

func _apply_ruby_material(node: Node):
	# Find all MeshInstance3D nodes and apply custom material
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		print("Found MeshInstance3D: ", mesh_instance.name)
		
		# Try different shader approaches
		var shader_mode = "crystal"  # Options: "faceted", "outlined", "crystal", "standard"
		
		match shader_mode:
			"faceted":
				# Use the new faceted gem shader for sharp angular appearance
				var shader = load("res://shaders/faceted_gem.gdshader")
				if shader:
					var shader_material = ShaderMaterial.new()
					shader_material.shader = shader
					
					# Set shader parameters for ruby
					shader_material.set_shader_parameter("gem_color", Color(0.9, 0.15, 0.2, 1.0))
					shader_material.set_shader_parameter("edge_color", Color(0.3, 0.0, 0.05, 1.0))
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
					_apply_standard_ruby_material(mesh_instance)
			
			"outlined":
				# Use the outlined gem shader for cartoon-like angular appearance
				var shader = load("res://shaders/outlined_gem.gdshader")
				if shader:
					var shader_material = ShaderMaterial.new()
					shader_material.shader = shader
					
					# Set shader parameters for ruby
					shader_material.set_shader_parameter("gem_color", Color(0.9, 0.15, 0.2, 1.0))
					shader_material.set_shader_parameter("highlight_color", Color(1.0, 0.5, 0.6, 1.0))
					shader_material.set_shader_parameter("shadow_color", Color(0.4, 0.05, 0.1, 1.0))
					shader_material.set_shader_parameter("outline_color", Color(0.2, 0.0, 0.0, 1.0))
					shader_material.set_shader_parameter("light_threshold", 0.5)
					shader_material.set_shader_parameter("shadow_threshold", 0.3)
					shader_material.set_shader_parameter("outline_width", 0.02)
					
					mesh_instance.material_override = shader_material
					print("Applied outlined gem shader")
				else:
					_apply_standard_ruby_material(mesh_instance)
			
			"crystal":
				# Use the original crystal shader
				var shader = load("res://shaders/crystal_gem.gdshader")
				if shader:
					var shader_material = ShaderMaterial.new()
					shader_material.shader = shader
					
					# Set shader parameters for ruby
					shader_material.set_shader_parameter("albedo_color", Color(0.9, 0.15, 0.2, 1.0))
					shader_material.set_shader_parameter("roughness", 0.05)
					shader_material.set_shader_parameter("metallic", 0.0)
					shader_material.set_shader_parameter("specular", 1.0)
					shader_material.set_shader_parameter("rim_power", 2.5)
					shader_material.set_shader_parameter("rim_strength", 0.7)
					shader_material.set_shader_parameter("rim_color", Color(1.0, 0.4, 0.4, 1.0))
					shader_material.set_shader_parameter("fresnel_power", 3.0)
					shader_material.set_shader_parameter("fresnel_strength", 0.3)
					
					mesh_instance.material_override = shader_material
					print("Applied custom crystal shader")
				else:
					_apply_standard_ruby_material(mesh_instance)
			
			"standard":
				_apply_standard_ruby_material(mesh_instance)
	
	# Recursively check children
	for child in node.get_children():
		_apply_ruby_material(child)

func _apply_standard_ruby_material(mesh_instance: MeshInstance3D):
	# Create a new shiny ruby material
	var ruby_material = StandardMaterial3D.new()
	
	# Bright red color - opaque
	ruby_material.albedo_color = Color(0.9, 0.15, 0.2, 1.0)  # Fully opaque
	
	# Make it reflective like a real gem
	ruby_material.metallic = 0.0  # Gems are not metallic
	ruby_material.roughness = 0.1  # Slightly more rough for better facet definition
	ruby_material.specular = 1.0  # Maximum specular reflection
	
	# CRITICAL: Enable vertex shading for flat/angular appearance
	ruby_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	ruby_material.vertex_color_use_as_albedo = false
	
	# Disable emission - no glow
	ruby_material.emission_enabled = false
	
	# No transparency - we want to see the edges clearly
	ruby_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	# Disable subsurface scattering
	ruby_material.subsurf_scatter_enabled = false
	
	# Stronger rim lighting to emphasize edges
	ruby_material.rim_enabled = true
	ruby_material.rim = 0.5  # Increased for more edge definition
	ruby_material.rim_tint = 0.2  # Slight color tint for gemstone effect
	
	# No backlight
	ruby_material.backlight_enabled = false
	
	# Enable clearcoat for polished look without glow
	ruby_material.clearcoat_enabled = true
	ruby_material.clearcoat = 1.0  # Maximum clearcoat
	ruby_material.clearcoat_roughness = 0.0  # Perfectly smooth
	
	# Apply the material override
	mesh_instance.material_override = ruby_material
	
	print("Applied angular ruby material with flat shading")

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
