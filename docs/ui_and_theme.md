# Gembrawl – UI and Theme Guidelines

This document defines the **visual style**, **combat feedback**, and **UI behavior** for both singleplayer and multiplayer contexts in *Gembrawl*. It is intended to guide UI/UX designers, technical artists, and developers working on frontend and HUD systems.

---

## 🎨 Visual Art & Theme

- **Art Style**: 
  - Hybrid pixel-art aesthetic.
  - Visual style lies between *Stardew Valley* (chunky pixel shading) and *Terra Nil* (painterly pixel precision).

- **Gem Player Characters**:
  - Floating/faceless gem entities.
  - Default designs feature **faceted crystals** with subtle floating animations.
  - Each gem type corresponds to an elemental theme or power.

- **Effects**:
  - **Attacks** use **realistic particle effects** (e.g. spark showers, glow bursts).
  - **Damage feedback**: Players flash with a **white strobe effect** during invincibility frames (i-frames).
  - **Own gem indicator**: A **white underlight glow** distinguishes the local player’s gem in multiplayer.

---

## 🧩 HUD & Combat UI

- **General Layout**:
  - **Player HUDs** are **statically overlaid** on the game view.
  - Each HUD displays:
    - Current HP
    - Skill cooldown indicators
    - Gem name or class icon (optional)

- **Online Multiplayer**:
  - The **current user's HUD** is placed in the **top-left** corner.
  - This HUD is **larger and more prominent** than the others.
  - Other players’ HUDs are smaller and less emphasized.
  - **Directional markers** indicate off-screen players or enemies.
  - **Own gem** is highlighted with an **underlight effect** for quick visual ID.

- **Local Multiplayer**:
  - All HUDs are rendered at **equal size** for fairness.
  - **Viewport** is locked to an **arena-wide view** (no split or follow cam).
  - If multiple players use the **same gem type**, each gem is **recolored with unique hues** to distinguish them.

---

## ⏸ Game State Behavior

- **Pause Behavior**:
  - Pausing the game **freezes gameplay for all players**, both in local and online multiplayer.

- **View Mode Rules**:
  - **Online Multiplayer**:
    - Camera follows the current player’s view.
    - Off-screen entities are tracked via **screen-edge markers**.
  - **Local Multiplayer**:
    - Only **arena view mode** is allowed.
    - The camera is zoomed and centered to frame the entire arena and all players at once.

---

## 🎯 Accessibility Notes

- Flashing and underlight effects should respect **reduced motion / flash** accessibility settings.
- All HUD elements should be **screen-reader labeled** or structured for alternate input/output if used in accessibility overlays.

---

## 🔄 Future Extensions (Optional)

- Dynamic theme recoloring for specific gem skins
- Toggle HUD minimization for streamers
- Rebindable UI positions per player

---

