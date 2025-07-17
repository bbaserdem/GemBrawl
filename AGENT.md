# AGENT.md - GemBrawl Development Guide

## Build/Test Commands
- **Run game**: Open Godot Editor and run main scene 
  `game/scenes/hex_arena_3d_gameplay.tscn`
- **Nix shell**: `nix develop` - Enter development shell with Godot 4.3
- **Task Master**: `tm` command or 
  `npx --yes --package=task-master-ai task-master` - Project management

## Architecture & Structure
- **Engine**: Godot 4.3 game with 3D hex-based arena combat
- **Main scene**: `game/scenes/hex_arena_3d_gameplay.tscn`
- **Core systems**: Player3D (CharacterBody3D), HexArena3D, HexGrid3D utilities, 
  Gem resources
- **Skills**: Modular skill system in `game/scripts/skills/` with base Skill class
- **Resources**: Gem class defines stats, health, combat properties
- **Input**: WASD/arrows movement, Space for skills/jump, Q/E camera rotation

## Code Style (from .cursor/rules)
- **Files**: snake_case filenames (player_character.gd, main_menu.tscn)
- **Classes**: PascalCase with class_name (PlayerCharacter)
- **Variables/Functions**: snake_case (health_points, move_player())
- **Constants**: ALL_CAPS_SNAKE_CASE (MAX_HEALTH)
- **Nodes**: PascalCase in scene tree (PlayerCharacter, MainCamera)
- **Signals**: snake_case past tense (health_depleted, enemy_defeated)
- **Types**: Use strict typing, @onready annotations, explicit super() calls
- **Documentation**: Docstrings with ## comments for complex functions
- **Composition**: Prefer composition over inheritance, use signals for 
  loose coupling

## Project Integration
- **Task Master**: Integrated with `CLAUDE.md` context and MCP server
- **Nix**: Development environment with scripts and Godot 4.3 export templates
