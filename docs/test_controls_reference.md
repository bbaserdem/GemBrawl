# GemBrawl Test Controls - Quick Reference

## Combat Test Scene Controls

### 🎮 Player Movement
| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD / Arrow Keys | Left Stick |
| Jump | Space | A Button |
| Switch Player | Tab | - |

### ⚔️ Combat Actions
| Action | Keyboard | Gamepad | Description |
|--------|----------|---------|-------------|
| Melee Attack | Enter | X Button | Close-range attack in front |
| Fire Projectile | Q | Square | Ranged attack in facing direction |
| AoE Attack | E | Circle | Area damage around player |

### 📷 Camera Controls
| Action | Keyboard | Mouse | Gamepad |
|--------|----------|-------|---------|
| Zoom In/Out | - | Scroll Wheel | Right Stick Y |
| Rotate | Q/E | Middle Drag | Right Stick X |
| Tilt | Page Up/Down | - | L1/R1 |
| Toggle Follow | - | - | R3 |

### 🐛 Debug Keys
| Key | Action |
|-----|--------|
| Page Up | Print combat debug info |
| F1 | Toggle collision shape visibility |
| F2 | Toggle FPS counter |

---

## Testing Sequence

### Quick Combat Test (2 minutes)
1. Start: `godot --scene res://scenes/test_combat_collision.tscn`
2. **Melee**: Walk to Player 2, press Enter
3. **Ranged**: Back up, press Q
4. **AoE**: Press E with both players nearby
5. **Switch**: Press Tab, repeat from Player 2's perspective

### Full Test (5-10 minutes)
Follow the complete workflow in `testing_workflow.md`

---

## Visual Indicators

### Damage Numbers
- **White**: Normal damage
- **Yellow**: Critical hit
- **Gray**: Blocked/Reduced damage

### Player States
- **Flashing**: Invulnerable (just took damage)
- **Red Tint**: Low health
- **Transparent**: Dead/Spectating

### Attack Visuals
- **Red Box**: Melee hitbox (brief)
- **Blue Sphere**: Projectile
- **Yellow Circle**: AoE effect 