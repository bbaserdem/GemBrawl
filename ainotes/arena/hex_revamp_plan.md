# Hexagonal Prism Floor Tile Revamp Plan

## Overview
Transition the GemBrawl arena floor system from flat hexagonal shapes to thick hexagonal prisms, creating a more dynamic and visually appealing game environment.

## Project Context
- **Game**: GemBrawl (Godot 4.x project)
- **Main File to Modify**: `/gembrawl/arena/HexArena.gd`
- **Related Files**: 
  - `/gembrawl/arena/HexGrid.gd` (hex coordinate utilities)
  - `/gembrawl/arena/HazardTile.gd` (hazard system)
  - `/gembrawl/arena/ArenaBase.gd` (base arena class)
- **Current Working Directory**: Project root with arena worktree

## Current System Analysis

### Existing Implementation
- **Location**: `/gembrawl/arena/HexArena.gd`
- **Current Features**:
  - Flat hexagonal mesh generation (top face only)
  - Box collision shapes approximating hexagons
  - Random height variation for tiles
  - Hazard tile system (lava and spikes)
  - Material support but no texture mapping
  - Tile thickness parameter (`tile_thickness = 0.5`)

### Limitations
- Only renders top face of hexagons
- No side faces for 3D depth
- Limited texture support
- Box collision instead of proper hexagonal collision
- No visual variation between tile types

## Implementation Goals

### Phase 1: Core Hexagonal Prism Mesh
- [ ] Complete hexagonal prism mesh generation
  - [ ] Top face (existing)
  - [ ] Bottom face
  - [ ] 6 side faces
  - [ ] Proper vertex normals for lighting
  - [ ] UV mapping for all faces

### Phase 2: Texture Infrastructure
- [ ] Multi-face texture support
  - [ ] Top face texture slot
  - [ ] Side faces texture slot (can be shared)
  - [ ] Bottom face texture slot (rarely visible)
- [ ] Texture atlas support for performance
- [ ] Material variants system
  - [ ] Normal floor material
  - [ ] Hazard materials (lava, spikes)
  - [ ] Special tile materials

### Phase 3: Enhanced Visuals
- [ ] Edge beveling/highlighting
- [ ] Height variation system
  - [ ] Different base heights for tile types
  - [ ] Smooth transitions between heights
- [ ] Damaged/worn tile variants
- [ ] Ambient occlusion in tile gaps

### Phase 4: Collision System
- [ ] Replace box collision with hexagonal prism
- [ ] Options:
  - [ ] Custom hexagonal prism collision shape
  - [ ] Trimesh collision for exact matching
  - [ ] Optimized compound shape

### Phase 5: Advanced Features
- [ ] Dynamic tile states
  - [ ] Crumbling tiles
  - [ ] Rising/lowering platforms
- [ ] Special tile types
  - [ ] Power-up pedestals
  - [ ] Teleporter pads
  - [ ] Bounce pads
- [ ] Procedural wear and damage

## Technical Specifications

### Hexagonal Prism Geometry
```
Top vertices (y = tile_thickness/2):
- 6 outer vertices in hexagonal pattern
- 1 center vertex (for triangulation)

Bottom vertices (y = -tile_thickness/2):
- 6 outer vertices (mirrored positions)
- 1 center vertex

Total: 14 vertices minimum
```

### UV Mapping Strategy
```
Top face: Planar projection (0,0) to (1,1)
Side faces: Wrapped strip mapping
- Each face gets 1/6th of horizontal space
- Full vertical space (0,1)
Bottom face: Planar projection (rarely visible)
```

### Material Structure
```gdscript
@export var floor_material: StandardMaterial3D
@export var floor_top_texture: Texture2D
@export var floor_side_texture: Texture2D
@export var floor_normal_map: Texture2D
@export var floor_roughness_map: Texture2D
```

## Implementation Steps

### Step 1: Update Mesh Generation
1. Backup current `_create_hex_mesh()` function
2. Implement full prism mesh generation
3. Add proper UV coordinates for all faces
4. Test with solid colors first

**Key Code Location**: `HexArena.gd` lines 49-93 (_create_hex_mesh function)

### Step 2: Material System
1. Create material presets for different tile types
2. Implement texture loading system
3. Add material variation support
4. Test with placeholder textures

### Step 3: Collision Update
1. Research Godot's collision shape options
2. Implement hexagonal prism collision
3. Performance test vs box collision
4. Choose optimal solution

### Step 4: Visual Polish
1. Add edge highlighting shader
2. Implement height variation
3. Create tile damage states
4. Add particle effects for hazards

### Step 5: Integration
1. Update existing arena scenes
2. Migrate hazard system
3. Update spawn point positioning
4. Performance optimization

## Performance Considerations

### Mesh Optimization
- Use indexed vertices to reduce data
- Consider LOD system for distant tiles
- Batch similar tiles together
- Use GPU instancing where possible

### Texture Optimization
- Use texture atlases to reduce draw calls
- Implement texture streaming for large arenas
- Use compressed texture formats
- Share textures between similar tiles

### Collision Optimization
- Use simplified collision for non-gameplay tiles
- Implement spatial partitioning
- Consider using areas for hazard detection
- Profile different collision shape options

## Future Enhancements

### Dynamic Arena Features
- Destructible floor tiles
- Moving platforms
- Environmental hazards (rising lava, etc.)
- Weather effects on tiles

### Visual Upgrades
- PBR material support
- Dynamic lighting effects
- Reflective surfaces
- Particle systems for ambiance

### Gameplay Integration
- Tile-based power-ups
- Strategic tile placement
- Arena editor for custom layouts
- Procedural arena generation

## Testing Plan

### Unit Tests
- Mesh generation correctness
- UV mapping validation
- Collision shape accuracy
- Performance benchmarks

### Integration Tests
- Arena generation with new tiles
- Hazard system compatibility
- Player movement on prisms
- Visual consistency

### Performance Tests
- Frame rate with various arena sizes
- Memory usage profiling
- Draw call optimization
- Physics performance

## Timeline Estimate

- **Week 1**: Core prism mesh generation and basic texturing
- **Week 2**: Collision system and material variants
- **Week 3**: Visual polish and special effects
- **Week 4**: Integration, testing, and optimization

## Success Criteria

1. Hexagonal prism tiles render correctly with all faces
2. Texture support works for future art assets
3. Performance remains stable (60+ FPS)
4. Collision detection is accurate
5. Visual improvement is noticeable
6. System is extensible for future features

## Implementation Priority

**Start with Phase 1**: Focus on creating the complete hexagonal prism mesh with all faces (top, bottom, 6 sides) before moving to textures or advanced features. This establishes the foundation for all other improvements.

## AI Implementation Notes

When implementing:
1. The existing `_create_hex_mesh()` function only creates the top face
2. Pointy-top hexagon orientation is used (first vertex at top)
3. Keep `tile_thickness` parameter for prism height
4. Maintain compatibility with existing hazard and spawn systems
5. Test in the scene files: `TestArenaHex.tscn` or `Arena1.tscn`