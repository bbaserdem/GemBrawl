#!/usr/bin/env python3
"""
Generate all gem color variations for a specific cut.
Usage: blender gem_template_<cut>.blend --background --python generate_gems.py -- <cut_name>
Example: blender gem_template_round.blend --background --python generate_gems.py -- round
"""

import bpy
import os
import sys

# Import the single gem generation functionality
# Since we're running in Blender's Python, we need to add the script directory to path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from generate_gem_color import (
    GEM_COLORS, 
    find_gem_object, 
    create_gem_material, 
    export_gem
)

def get_gem_cut_name():
    """Get the gem cut name from command line arguments"""
    argv = sys.argv
    if "--" in argv:
        idx = argv.index("--")
        if idx + 1 < len(argv):
            return argv[idx + 1]
    
    # Try to extract from blend filename if no argument
    blend_file = bpy.data.filepath
    if blend_file:
        filename = os.path.basename(blend_file)
        if filename.startswith("gem_template_") and filename.endswith(".blend"):
            return filename[13:-6]  # Extract cut name
    
    return "round"  # Default

def main():
    """Generate all gem color variations"""
    # Get gem cut name
    cut_name = get_gem_cut_name()
    
    # Find gem object
    gem_obj = find_gem_object()
    if not gem_obj:
        print("Error: No gem object found in the scene!")
        print("Make sure the blend file contains a gem mesh object.")
        return
    
    print(f"Generating {cut_name} cut gems in all colors...")
    print(f"Colors to generate: {len(GEM_COLORS)}")
    print("-" * 50)
    
    # Set up output directory
    output_dir = os.path.join(script_dir, "output")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Generate each color variation
    successful = 0
    failed = 0
    
    for color_name, color_rgb in GEM_COLORS.items():
        try:
            # Create material
            material = create_gem_material(color_name, color_rgb)
            
            # Export gem
            output_filename = f"gem_{cut_name}_{color_name}.glb"
            output_path = os.path.join(output_dir, output_filename)
            
            export_gem(gem_obj, material, output_path)
            
            print(f"✅ Generated: {output_filename}")
            successful += 1
            
        except Exception as e:
            print(f"❌ Failed to generate {color_name}: {str(e)}")
            failed += 1
    
    # Summary
    print("-" * 50)
    print(f"\n📊 Generation complete!")
    print(f"✅ Successful: {successful}")
    if failed > 0:
        print(f"❌ Failed: {failed}")
    print(f"\n📁 Files saved to: {output_dir}")
    
    # List all generated files
    if successful > 0:
        print("\nGenerated files:")
        for color_name in GEM_COLORS.keys():
            filename = f"gem_{cut_name}_{color_name}.glb"
            filepath = os.path.join(output_dir, filename)
            if os.path.exists(filepath):
                size_kb = os.path.getsize(filepath) / 1024
                print(f"  • {filename} ({size_kb:.1f} KB)")

if __name__ == "__main__":
    main()