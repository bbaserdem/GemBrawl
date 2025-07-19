#!/usr/bin/env python3
"""
Gem Generation Script for GemBrawl
This script generates gem models with different colors using Blender's Python API.
Usage: blender gem_template_<cut>.blend --background --python generate_gems.py -- <cut_name>
Example: blender gem_template_round.blend --background --python generate_gems.py -- round
"""

import bpy
import os
import sys

def get_gem_cut_name():
    """Get the gem cut name from command line arguments"""
    # Find the -- separator
    argv = sys.argv
    if "--" in argv:
        idx = argv.index("--")
        if idx + 1 < len(argv):
            return argv[idx + 1]
    return "round"  # Default to round if not specified

def create_gem_material(color_name, color_rgb):
    """Create a gem material with specified color"""
    
    mat_name = f"Gem_{color_name}"
    
    # Check if material already exists
    if mat_name in bpy.data.materials:
        mat = bpy.data.materials[mat_name]
    else:
        mat = bpy.data.materials.new(name=mat_name)
    
    mat.use_nodes = True
    
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    # Principled BSDF
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    
    # Set properties
    bsdf.inputs['Base Color'].default_value = color_rgb
    bsdf.inputs['Metallic'].default_value = 0.0
    bsdf.inputs['Roughness'].default_value = 0.0
    bsdf.inputs['IOR'].default_value = 2.4
    
    # Try to set transmission (Blender version compatibility)
    if 'Transmission Weight' in bsdf.inputs:
        bsdf.inputs['Transmission Weight'].default_value = 0.95
    elif 'Transmission' in bsdf.inputs:
        bsdf.inputs['Transmission'].default_value = 0.95
    
    # Add subsurface for gem-like appearance
    if 'Subsurface Weight' in bsdf.inputs:
        bsdf.inputs['Subsurface Weight'].default_value = 0.1
        bsdf.inputs['Subsurface Radius'].default_value = (color_rgb[0], color_rgb[1], color_rgb[2])
    
    # Output
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
    
    # Export
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        use_selection=True,
        export_format='GLB',
        export_apply=True,
        export_draco_mesh_compression_enable=False
    )
    
    print(f"Exported: {output_path}")

def main():
    """Generate gem variations with different colors"""
    
    # Get gem cut name from command line
    cut_name = get_gem_cut_name()
    
    # Define gem colors (color name -> RGB values)
    gem_colors = {
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
    
    # Find the gem object in the scene
    # Look for objects with "Gem" in the name
    gem_obj = None
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and ("gem" in obj.name.lower() or "cut" in obj.name.lower()):
            gem_obj = obj
            break
    
    if not gem_obj:
        print("Error: No gem object found in the scene!")
        print("Make sure the blend file contains a gem mesh object.")
        return
    
    print(f"Found gem object: {gem_obj.name}")
    print(f"Generating {cut_name} cut gems with {len(gem_colors)} color variations")
    
    # Get output directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "output")
    
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Generate each color variation
    for color_name, color_rgb in gem_colors.items():
        # Create material
        mat = create_gem_material(color_name, color_rgb)
        
        # Export with naming convention: gem_<cut>_<color>.glb
        output_filename = f"gem_{cut_name}_{color_name}.glb"
        output_path = os.path.join(output_dir, output_filename)
        
        export_gem(gem_obj, mat, output_path)
    
    print(f"\nSuccessfully generated {len(gem_colors)} gem variations!")
    print(f"Files saved to: {output_dir}")

if __name__ == "__main__":
    main()