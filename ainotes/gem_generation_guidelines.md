# Gem Generation Guidelines

This document describes the process and best practices for creating gem templates and generating gem assets for GemBrawl.

## Overview

The gem generation system consists of:
- **Blender templates** (e.g., `gem_template_round.blend`) - 3D models with proper topology
- **Python script** (`generate_gems.py`) - Automated color variation generation
- **Output** - GLB files ready for game use (e.g., `gem_round_red.glb`)

## Creating a Gem Template

### 1. Basic Geometry Requirements

- **Symmetry**: Gems should be symmetric across the horizontal plane
- **Flat faces**: All faces must be flat (no curved surfaces)
- **Watertight**: No holes or gaps in the mesh
- **Thickness**: Approximately 0.8 units tall for gameplay visibility
- **Diameter**: 2.0 units wide (standard size)

### 2. Topology Structure

For a round brilliant cut gem:
- **64 vertices** distributed across 6 levels:
  - Top table: 8 vertices
  - Crown mid: 8 vertices (offset by π/8)
  - Girdle top: 16 vertices
  - Girdle bottom: 16 vertices
  - Pavilion mid: 8 vertices (offset by π/8)
  - Bottom table: 8 vertices
- **130 faces** (after filling all holes) - or **344 faces** with double-sided geometry
- **192 edges** (all marked as sharp)

### 3. Crystalline Appearance Settings

To ensure gems look properly faceted and crystalline:

1. **Flat Shading**
   ```python
   for poly in mesh.polygons:
       poly.use_smooth = False
   ```

2. **Sharp Edges**
   - Select all edges in Edit mode
   - Mark as sharp: `Mesh → Edges → Mark Sharp`
   - This preserves facet boundaries

3. **Edge Split Modifier**
   - Add Edge Split modifier
   - Set to use sharp edges only (not angle-based)
   - This ensures proper normal calculation for export

4. **No Subdivision**
   - Avoid Subdivision Surface modifiers
   - Keep geometry explicitly defined

### 4. Material Setup

Materials are applied during generation, not in the template:
- Base template should have no materials
- Materials include:
  - Base color (varies by gem type)
  - Metallic: 0.0
  - Roughness: 0.0
  - IOR: 2.4 (diamond-like)
  - Transmission: 0.95

## Using the Generation Scripts

### Single Gem Generation

Generate a single gem with specific cut and color:

```bash
blender gem_template_<cut>.blend --background --python generate_gem_color.py -- <cut_name> <color_name>
```

Example:
```bash
blender gem_template_round.blend --background --python generate_gem_color.py -- round red
```

### Batch Generation

Generate all color variations for a specific cut:

```bash
blender gem_template_<cut>.blend --background --python generate_gems.py -- <cut_name>
```

Example:
```bash
blender gem_template_round.blend --background --python generate_gems.py -- round
```

### Available Colors

Both scripts support 12 color variations:
- `red` - Ruby red (0.8, 0.1, 0.1)
- `blue` - Sapphire blue (0.1, 0.3, 0.8)
- `green` - Emerald green (0.1, 0.7, 0.2)
- `purple` - Amethyst purple (0.5, 0.2, 0.7)
- `yellow` - Topaz yellow (0.9, 0.7, 0.1)
- `white` - Diamond white (0.95, 0.95, 0.95)
- `cyan` - Aquamarine cyan (0.3, 0.7, 0.8)
- `orange` - Citrine orange (0.9, 0.6, 0.2)
- `black` - Onyx black (0.1, 0.1, 0.1)
- `pink` - Rose quartz pink (0.9, 0.5, 0.7)
- `brown` - Smoky quartz brown (0.4, 0.2, 0.1)
- `gray` - Gray diamond (0.5, 0.5, 0.5)

### Output

Files are saved to `templates/gem/output/` with naming convention:
- `gem_<cut>_<color>.glb` (e.g., `gem_round_red.glb`)

## Creating New Gem Cuts

When creating templates for other cuts (e.g., emerald, princess, pear):

1. **Follow naming convention**: `gem_template_<cut_name>.blend`
2. **Maintain consistent scale**: Same diameter and height ratios
3. **Apply all crystalline settings**: Flat shading, sharp edges, edge split
4. **Test generation**: Ensure the script can find and process the gem mesh
5. **Verify exports**: Check that GLB files render correctly in-game

## Common Issues and Solutions

### Issue: Gems appear smooth/rounded
- **Solution**: Ensure flat shading is applied to all faces
- Mark all edges as sharp
- Add Edge Split modifier

### Issue: Dark faces or incorrect normals
- **Solution**: Recalculate normals (face outside)
- Check face winding order
- Ensure no inverted faces
- **Alternative Solution**: Apply Solidify modifier with zero thickness
  - This duplicates all faces with opposite normals
  - Ensures visibility from any viewing angle
  - Eliminates normal direction issues in game engines

### Issue: Holes in the mesh
- **Solution**: Use boundary edge selection to find gaps
- Fill triangular holes first, then quadrilateral
- Verify watertight with boundary edge count (should be 0)

### Issue: Generation script can't find gem
- **Solution**: Ensure mesh object name contains "gem" or "cut"
- Object must be of type 'MESH'
- Check that object is visible in scene

### Issue: Single gem generation fails
- **Solution**: Check that both cut and color arguments are provided
- Verify color name is in the supported list
- Ensure template file matches the cut name

## Best Practices

1. **Save incrementally** while working on templates
2. **Test exports** frequently during development
3. **Keep geometry clean** - remove duplicate vertices
4. **Document changes** to topology or structure
5. **Maintain consistency** across different cut types

## File Organization

```
templates/
└── gem/
    ├── gem_template_round.blend     # Template files
    ├── gem_template_emerald.blend   # (future cuts)
    ├── generate_gem_color.py        # Single gem generation
    ├── generate_gems.py             # Batch generation script
    └── output/                      # Generated GLB files
        ├── gem_round_red.glb
        ├── gem_round_blue.glb
        └── ...
```

## Script Architecture

- **`generate_gem_color.py`** - Core functionality for single gem generation
  - Defines color palette (`GEM_COLORS`)
  - Material creation function
  - Export logic
  - Command-line argument parsing

- **`generate_gems.py`** - Batch processing script
  - Imports core functions from `generate_gem_color.py`
  - Iterates through all colors
  - Provides summary and file listing

## Future Enhancements

Potential improvements for the gem system:
- Additional cut types (princess, emerald, pear, marquise)
- Size variations (small, medium, large)
- Quality levels (flawed, regular, flawless)
- Special effects (glowing, enchanted)
- Procedural imperfections for realism