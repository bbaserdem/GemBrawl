# Gembrawl – Control Layout Specification

This document outlines the **default controller and keyboard mappings** for both **in-game actions** and **menu navigation**. It serves as a reference for UX design, accessibility testing, and gameplay input management.

---

## 🎮 In-Game Controls


| **Action**                 | **Controller Input**           | **Keyboard Input**         |
|---------------------------|---------------------------------|----------------------------|
| **== Gameplay ==**        |                                 |                            |
| Move                      | Left Stick / D-Pad (←↑↓→)       | Arrow Keys (←↑↓→)          |
| Glide (Dash)              | L2                              | Spacebar                   |
| Bounce (Jump)             | R2                              | Left Shift                 |
| Cut (Main Attack)         | X                               | Z                          |
| Polish (Secondary Attack) | Square                          | X                          |
| Shine (Area Denial)       | Circle                          | C                          |
| Refract (Block)           | Triangle                        | Tab                        |
| Tilt View (Up/Down)       | R1 / L1                         | Page Up / Page Down        |
| Rotate View (Left/Right)  | Right Stick (Lateral)           | A / D                      |
| Zoom In/Out               | Right Stick (Vertical)          | W / S                      |
| Cycle Camera Modes        | Right Stick Press (R3)          | Grave (\`)                 |

### Camera Modes

- *Player Focused* (default): Camera follows the player, fixed orientation.
- *Third person*: Camera follows the player, rotates so that the player always looks forward.
  Rotate view and move left/right is the same in this view mode.
- *Arena Focused*: Camera is static, zoom level is fixed and zoom buttons move the camera forward/backward.

---

## 🧭 Menu Navigation

### Gamepad (PS5 DualSense)
| **Action**                 | **Controller Input**           | **Keyboard Input**         |
|---------------------------|---------------------------------|----------------------------|
| Navigate Menu             | D-Pad (←↑↓→)                    | Arrow Keys (←↑↓→)          |
| Confirm Selection         | X                               | Enter / Spacebar           |
| Cancel / Go Back          | Square                          | Delete / Backspace         |
| Adjust Sliders            | D-Pad (← →)                     | Arrow Keys (← →)           |
| Open Menu Dialog          | Options / Start                 | Escape                     |


---

## 🔁 Notes & Design Considerations

- **Unified Input Mapping**: Ensure input events are abstracted so both keyboard and gamepad can trigger the same underlying actions.
- **Custom Remapping**: Leave room in settings for custom key/button remapping to support accessibility.
- **Camera Modes**: Consider modes like FollowCam, FreeCam, Top-Down. Cycling should feel intuitive and reversible.
- **UI Accessibility**: Button hints (e.g., "Press ⬜ to go back") should update dynamically based on input method.
- **Multiple Controller Support**: Essential for local multiplayer mode where 2-4 controllers connect to one machine.
- **Controller Assignment**: Each player should press any button to claim their controller with visual feedback (player colors, controller icons).
- **Local Multiplayer Navigation**: Menu navigation should work with any assigned controller, not just "Player 1".

---

## 🛠 Input Profile Identifiers

For implementation in your input system (e.g., `InputMap` in Godot), you can define input actions like:

```gdscript
InputMap.add_action("move_left")
InputMap.add_action("attack_cut")
InputMap.add_action("camera_zoom_in")
InputMap.add_action("menu_confirm")
```
