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
		
		# Modify the material to be shiny and brighter red
		_apply_ruby_material(instance)
	else:
		print("Failed to load ruby gem model")

func _apply_ruby_material(node: Node):
	# Find all MeshInstance3D nodes and apply custom material
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		print("Found MeshInstance3D: ", mesh_instance.name)
		
		# Create a new shiny ruby material
		var ruby_material = StandardMaterial3D.new()
		
		# Bright red color - opaque
		ruby_material.albedo_color = Color(0.9, 0.15, 0.2, 1.0)  # Fully opaque
		
		# Make it reflective like a real gem
		ruby_material.metallic = 0.0  # Gems are not metallic
		ruby_material.roughness = 0.05  # Very slightly rough to catch light better
		ruby_material.specular = 0.8  # High specular reflection
		
		# Disable emission - no glow
		ruby_material.emission_enabled = false
		
		# No transparency - we want to see the edges clearly
		ruby_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		
		# Disable subsurface scattering
		ruby_material.subsurf_scatter_enabled = false
		
		# Subtle rim lighting to highlight edges
		ruby_material.rim_enabled = true
		ruby_material.rim = 0.2  # Very subtle
		ruby_material.rim_tint = 0.0  # No color tint, just brightening
		
		# No backlight
		ruby_material.backlight_enabled = false
		
		# Enable clearcoat for polished look without glow
		ruby_material.clearcoat_enabled = true
		ruby_material.clearcoat = 0.5
		ruby_material.clearcoat_roughness = 0.03
		
		# Apply the material override
		mesh_instance.material_override = ruby_material
		
		print("Applied non-glowing ruby material")
	
	# Recursively check children
	for child in node.get_children():
		_apply_ruby_material(child)