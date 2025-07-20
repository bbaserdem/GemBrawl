# Hex Tile Texture Manifest

## Overview
This document lists all texture placeholders created for the hex tile system. Each .txt file describes the visual specifications for textures that need to be generated.

## Meadow Tiles
### Base Textures
- `base/grass/hex_top_01.png` - Base grass texture
- `base/grass/hex_top_02.png` - Grass with flower patches
- `base/grass/hex_top_03.png` - Grass with dark/worn spots
- `base/grass/hex_side.png` - Earth/soil colored sides

### Overlay Variations
- `overlays/details/meadow_flowers_01.png` - Wildflower scatter overlay
- `overlays/details/meadow_flowers_02.png` - Different flower varieties
- `overlays/details/meadow_puddle.png` - Water puddle overlay
- `overlays/details/meadow_dark_patches.png` - Worn grass overlay
- `overlays/details/meadow_clover.png` - Clover patch overlay

## Rocky Elevated Tiles
### Base Textures
- `base/rock/hex_top_rock.png` - Rocky surface
- `base/rock/hex_side_rock.png` - Cliff-like rocky sides
- `base/rock/hex_top_rock_moss.png` - Mossy rock variation

### Detail Overlays
- `overlays/details/rock_cracks.png` - Additional crack details
- `overlays/details/rock_lichen.png` - Lichen growth patches

## Water Hazard Tiles
### Base Textures
- `special/hazards/hex_top_water.png` - Water surface
- `special/hazards/hex_side_wetmud.png` - Wet mud sides

### Feature Masks & Effects
- `special/hazards/water_rock_border_mask.png` - Blend mask for edges
- `special/hazards/water_rock_border_texture.png` - Rocky edge texture
- `special/hazards/water_foam.png` - Foam/ripple effects

## Implementation Notes

### Texture Resolutions
- Top faces: 512x512 pixels
- Side faces: 256x512 pixels
- All overlays: 512x512 with alpha transparency

### UV Mapping Strategy
1. **Top Face**: Standard 0-1 UV space
2. **Side Faces**: Horizontal tiling (U wraps, V doesn't)
3. **Overlays**: Same UV as base, blend via shader

### Shader Implementation
For water hazard tiles:
```gdscript
# Pseudo-code for water tile shader
var final_color = mix(water_texture, rock_texture, border_mask)
final_color += foam_texture * foam_alpha
```

### Next Steps
1. Generate actual PNG textures from these specifications
2. Create normal maps for each base texture
3. Implement shader with multi-texture blending
4. Test tiling and seamless patterns
5. Create texture atlases for optimization