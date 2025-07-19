#!/usr/bin/env python3
"""
Generate a single gem GLB file with specified cut and color.
Usage: blender gem_template_<cut>.blend --background --python generate_gem_color.py -- <cut_name> <color_name>
Example: blender gem_template_round.blend --background --python generate_gem_color.py -- round red
"""

import bpy
import os
import sys

# Define gem colors
GEM_COLORS = {
    "red": (0.8, 0.1, 0.1, 1.0),
    "blue": (0.1, 0.3, 0.8, 1.0),
    "green": (0.1, 0.7, 0.2, 1.0),
    "purple": (0.5, 0.2, 0.7, 1.0),
    "yellow": (0.9, 0.7, 0.1, 1.0),
    "white": (0.95, 0.95, 0.95, 1.0),
    "cyan": (0.3, 0.7, 0.8, 1.0),
    "orange": (0.9, 0.6, 0.2, 1.0),
    "black": (0.1, 0.1, 0.1, 1.0),
    "pink": (0.9, 0.5, 0.7, 1.0),
    "brown": (0.4, 0.2, 0.1, 1.0),
    "gray": (0.5, 0.5, 0.5, 1.0)
}

def get_command_args():
    """Get cut name and color name from command line arguments"""
    argv = sys.argv
    if "--" not in argv:
        return None, None
    
    idx = argv.index("--")
    args = argv[idx + 1:]
    
    if len(args) >= 2:
        return args[0], args[1]
    elif len(args) == 1:
        # If only one arg, assume it's the color and get cut from filename
        color = args[0]
        cut = "round"  # default
        
        # Try to extract cut name from blend filename
        blend_file = bpy.data.filepath
        if blend_file:
            filename = os.path.basename(blend_file)
            if filename.startswith("gem_template_") and filename.endswith(".blend"):
                cut = filename[13:-6]  # Extract cut name
        
        return cut, color
    
    return None, None

def find_gem_object():
    """Find the gem mesh object in the scene"""
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and ("gem" in obj.name.lower() or "cut" in obj.name.lower()):
            return obj
    return None

def create_gem_material(color_name, color_rgb):
    """Create a gem material with specified color"""
    mat_name = f"Gem_{color_name}"
    
    # Create new material
    mat = bpy.data.materials.new(name=mat_name)
    mat.use_nodes = True
    
    # Clear and setup nodes
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    # Create Principled BSDF
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    
    # Set gem properties
    bsdf.inputs['Base Color'].default_value = color_rgb
    bsdf.inputs['Metallic'].default_value = 0.0
    bsdf.inputs['Roughness'].default_value = 0.0
    bsdf.inputs['IOR'].default_value = 2.4
    
    # Set transmission (version compatibility)
    if 'Transmission Weight' in bsdf.inputs:
        bsdf.inputs['Transmission Weight'].default_value = 0.95
    elif 'Transmission' in bsdf.inputs:
        bsdf.inputs['Transmission'].default_value = 0.95
    
    # Add subsurface for gem-like appearance
    if 'Subsurface Weight' in bsdf.inputs:
        bsdf.inputs['Subsurface Weight'].default_value = 0.1
        bsdf.inputs['Subsurface Radius'].default_value = (color_rgb[0], color_rgb[1], color_rgb[2])
    
    # Create output node
    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (300, 0)
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    
    return mat

def export_gem(obj, material, output_path):
    """Export gem with specified material as GLB"""
    # Apply material
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)
    
    # Select only the gem
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Export as GLB
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        use_selection=True,
        export_format='GLB',
        export_apply=True,
        export_draco_mesh_compression_enable=False
    )

def main():
    """Generate a single gem with specified cut and color"""
    # Get command line arguments
    cut_name, color_name = get_command_args()
    
    if not cut_name or not color_name:
        print("Error: Missing arguments!")
        print("Usage: blender gem_template_<cut>.blend --background --python generate_gem_color.py -- <cut> <color>")
        print("Example: blender gem_template_round.blend --background --python generate_gem_color.py -- round red")
        return
    
    # Validate color
    if color_name not in GEM_COLORS:
        print(f"Error: Unknown color '{color_name}'")
        print(f"Available colors: {', '.join(GEM_COLORS.keys())}")
        return
    
    # Find gem object
    gem_obj = find_gem_object()
    if not gem_obj:
        print("Error: No gem object found in the scene!")
        return
    
    print(f"Generating {cut_name} cut gem in {color_name}...")
    
    # Create material
    color_rgb = GEM_COLORS[color_name]
    material = create_gem_material(color_name, color_rgb)
    
    # Set up output path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "output")
    
    # Create output directory if needed
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Export gem
    output_filename = f"gem_{cut_name}_{color_name}.glb"
    output_path = os.path.join(output_dir, output_filename)
    
    export_gem(gem_obj, material, output_path)
    
    print(f"✅ Successfully generated: {output_filename}")
    print(f"📁 Location: {output_path}")

if __name__ == "__main__":
    main()