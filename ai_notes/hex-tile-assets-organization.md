# Hexagonal Tile Assets Organization Plan

## Overview
This document outlines the comprehensive asset organization strategy for the hexagonal tile system in GemBrawl. The system is designed to support multiple biomes, dynamic tile variations, and composable textures for creating visually diverse arenas.

## Core Design Principles

### 1. Modular Architecture
- **Base Components**: Reusable mesh and material templates
- **Variations**: Different tile shapes (flat, ramp, pit, elevated)
- **Biome Themes**: Swappable texture sets for different environments
- **Composable Layers**: Base textures + overlays for dynamic visuals

### 2. Performance Considerations
- **Triangle-based Rendering**: All hexagon faces use 6 triangles (GPU requirement)
- **Texture Atlasing**: Group related textures to reduce draw calls
- **LOD Support**: Multiple detail levels for distant tiles
- **Instanced Rendering**: Reuse base meshes with material variations

## Directory Structure

### Complete Asset Organization
```
gembrawl/assets/
├── meshes/
│   └── tiles/
│       ├── base/
│       │   ├── hex_prism.res              # Standard hexagonal prism
│       │   ├── hex_prism.tres             # Import settings
│       │   └── hex_prism_lod.res          # Low-detail version
│       ├── variations/
│       │   ├── hex_ramp_up.res            # Ascending ramp
│       │   ├── hex_ramp_down.res          # Descending ramp
│       │   ├── hex_corner_ramp.res        # Corner transition
│       │   ├── hex_pit.res                # Sunken hazard tile
│       │   ├── hex_raised.res             # Elevated platform
│       │   └── hex_bridge.res             # Bridge segment
│       └── procedural/
│           ├── HexMeshGenerator.gd         # Runtime mesh generation
│           └── TileShapeVariations.gd      # Variation parameters
│
├── materials/
│   └── tiles/
│       ├── biomes/
│       │   ├── grass_tile.tres            # Grass biome material
│       │   ├── snow_tile.tres             # Snow biome material
│       │   ├── cave_tile.tres             # Cave biome material
│       │   ├── desert_tile.tres           # Desert biome material
│       │   └── lava_tile.tres             # Lava biome material
│       ├── shaders/
│       │   ├── hex_tile_base.gdshader     # Base tile shader
│       │   ├── tile_blend.gdshader        # Multi-texture blending
│       │   └── tile_effects.gdshader      # Special effects (glow, etc)
│       └── presets/
│           ├── tile_material_base.tres     # Base material template
│           └── hazard_material_base.tres   # Hazard tile template
│
├── textures/
│   └── tiles/
│       ├── base/
│       │   ├── grass/
│       │   │   ├── hex_top_01.png         # Variation 1
│       │   │   ├── hex_top_02.png         # Variation 2
│       │   │   ├── hex_top_03.png         # Variation 3
│       │   │   ├── hex_side.png           # Side face texture
│       │   │   ├── hex_bottom.png         # Bottom face texture
│       │   │   └── hex_normal.png         # Normal map
│       │   ├── snow/
│       │   │   ├── hex_top_clean.png      # Fresh snow
│       │   │   ├── hex_top_dirty.png      # Trampled snow
│       │   │   ├── hex_top_ice.png        # Icy surface
│       │   │   ├── hex_side_snow.png      # Snowy sides
│       │   │   └── hex_normal_snow.png    # Snow normal map
│       │   ├── cave/
│       │   │   ├── hex_top_stone.png      # Stone floor
│       │   │   ├── hex_top_moss.png       # Mossy stone
│       │   │   ├── hex_top_wet.png        # Wet stone
│       │   │   └── hex_side_cave.png      # Cave wall texture
│       │   └── desert/
│       │       ├── hex_top_sand.png       # Sand texture
│       │       ├── hex_top_cracked.png    # Dry earth
│       │       └── hex_side_sandstone.png # Sandstone sides
│       │
│       ├── overlays/
│       │   ├── paths/
│       │   │   ├── path_straight.png      # Straight path overlay
│       │   │   ├── path_corner.png        # 60° turn
│       │   │   ├── path_junction.png      # Y-junction
│       │   │   ├── path_cross.png         # Crossroads
│       │   │   └── path_end.png           # Path termination
│       │   ├── details/
│       │   │   ├── cracks_01.png          # Surface damage
│       │   │   ├── cracks_02.png          # Alternative cracks
│       │   │   ├── moss_patches.png       # Moss growth
│       │   │   ├── blood_stains.png       # Battle damage
│       │   │   ├── scorch_marks.png       # Fire damage
│       │   │   └── water_puddles.png      # Water accumulation
│       │   └── edges/
│       │       ├── edge_wear.png          # Worn edges
│       │       ├── edge_damage.png        # Broken edges
│       │       └── edge_highlight.png     # Selection highlight
│       │
│       └── special/
│           ├── hazards/
│           │   ├── lava_top.png           # Lava surface
│           │   ├── lava_flow.png          # Animated lava
│           │   ├── spike_base.png         # Spike trap base
│           │   ├── ice_slippery.png       # Ice hazard
│           │   └── poison_swamp.png       # Toxic surface
│           └── interactive/
│               ├── button_inactive.png     # Pressure plate off
│               ├── button_active.png       # Pressure plate on
│               ├── teleporter_idle.png     # Teleporter inactive
│               └── teleporter_active.png   # Teleporter active
│
└── scenes/
    └── tiles/
        ├── prefabs/
        │   ├── tiles/
        │   │   ├── GrassTile.tscn        # Complete grass tile
        │   │   ├── SnowTile.tscn         # Complete snow tile
        │   │   ├── CaveTile.tscn         # Complete cave tile
        │   │   └── DesertTile.tscn       # Complete desert tile
        │   ├── hazards/
        │   │   ├── LavaTile.tscn         # Lava hazard tile
        │   │   ├── SpikeTile.tscn        # Spike trap tile
        │   │   └── IceTile.tscn          # Slippery ice tile
        │   └── special/
        │       ├── RampTile.tscn          # Ramp tile prefab
        │       ├── BridgeTile.tscn        # Bridge segment
        │       └── TeleporterTile.tscn   # Teleporter tile
        └── components/
            ├── TileBase.tscn              # Base tile template
            ├── TileVariation.gd           # Variation controller
            └── TileEffects.gd             # Visual effects handler
```

## Texture Specifications

### Base Tile Textures
- **Resolution**: 512x512 for top faces, 256x512 for sides
- **Format**: PNG with alpha channel where needed
- **Naming Convention**: `hex_[face]_[variant].png`

### Overlay Textures
- **Resolution**: 512x512 with alpha transparency
- **Purpose**: Composited over base textures for variation
- **Blending**: Multiplicative or overlay blend modes

### Normal Maps
- **Suffix**: `_normal.png`
- **Purpose**: Surface detail without geometry

## Material System

### Shader Features
1. **Multi-texture Support**: Blend up to 3 textures
2. **Overlay Compositing**: Dynamic detail layers
3. **Vertex Color**: For team colors or damage indication
4. **Emission Maps**: For glowing hazards

### Material Inheritance
```
BaseTileMaterial
├── BiomeTileMaterial (per biome)
│   └── TileVariantMaterial (per variant)
└── HazardTileMaterial
    └── SpecificHazardMaterial
```

## Implementation Phases

### Phase 1: Basic System
- Create hex_prism.res mesh
- Implement single biome (grass)
- Basic material with diffuse texture only

### Phase 2: Biome Variety
- Add 3-4 biome texture sets
- Implement texture swapping system
- Add normal maps

### Phase 3: Advanced Features
- Overlay system for paths/details
- Mesh variations (ramps, pits)
- Shader effects (emission, animation)

### Phase 4: Optimization
- Texture atlasing
- LOD implementation
- Instanced rendering setup

## Usage Guidelines

### Texture Creation
1. Maintain consistent art style across biomes
2. Ensure tileable side textures
3. Test overlays with all base textures
4. Keep detail density appropriate for camera distance

### Performance Best Practices
1. Reuse materials via inheritance
2. Batch tiles by material type
3. Use texture atlases for small details
4. Implement frustum culling for large arenas

### Biome Switching
```gdscript
# Example biome switching code
func set_arena_biome(biome_name: String):
    var material = load("res://gembrawl/assets/materials/tiles/biomes/" + biome_name + "_tile.tres")
    for tile in arena_tiles:
        tile.material_override = material
```

## Future Expansions

### Planned Features
1. **Seasonal Variations**: Summer/Winter versions of biomes
2. **Weather Effects**: Wet surfaces, snow accumulation
3. **Destruction States**: Damaged tile variations
4. **Animated Tiles**: Moving platforms, rotating sections

### Asset Scalability
- System supports unlimited biome additions
- Easy integration of new tile shapes
- Modular overlay system for endless combinations

## Notes for Artists

### Texture Guidelines
- Use power-of-2 dimensions
- Minimize alpha usage (performance)
- Create variations that tile seamlessly
- Consider color-blind friendly palettes

### Optimization Tips
- Share textures between similar tiles
- Use channel packing for effects
- Create efficient UV layouts
- Test on minimum spec hardware