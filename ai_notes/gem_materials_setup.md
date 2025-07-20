# Gem Materials Setup

## Overview
The gem models use a custom shader that simulates the crystalline appearance of gems without relying on true transmission/refraction which can cause rendering issues in Godot.

## Shader: transmission_gem_fixed.gdshader
Located at: `res://shaders/transmission_gem_fixed.gdshader`

This shader provides:
- Rim lighting for edge glow
- Fresnel effects for view-dependent color
- Inner glow to simulate light passing through
- Full opacity to avoid transparency sorting issues
- Proper culling to prevent missing faces

## Material Resources
Each gem type has its own material resource with appropriate colors:

1. **Ruby**: `res://assets/materials/gem_ruby_material.tres`
   - Color: Deep red (0.8, 0.1, 0.1)
   - Rim: Light red glow

2. **Sapphire**: `res://assets/materials/gem_sapphire_material.tres`
   - Color: Deep blue (0.1, 0.3, 0.9)
   - Rim: Light blue glow

3. **Emerald**: `res://assets/materials/gem_emerald_material.tres`
   - Color: Deep green (0.1, 0.8, 0.2)
   - Rim: Light green glow

## Import Settings
The gem GLB files are configured to use external materials via the `.import` files.
This allows the material to be shared and updated centrally.

Example from gem_ruby.glb.import:
```
_subresources={
"materials": {
"Gem_red": {
"use_external/enabled": true,
"use_external/path": "res://assets/materials/gem_ruby_material.tres"
}
}
}
```

## Testing
The test scenes should NOT override the material parameters. They should use the materials as configured in the import settings to ensure testing reflects actual game usage.

## Known Issues and Solutions
1. **Missing faces**: Fixed by using `cull_back` instead of `cull_disabled`
2. **Transparency sorting**: Fixed by using full opacity
3. **Different lighting conditions**: The shader is designed to work well in various lighting setups