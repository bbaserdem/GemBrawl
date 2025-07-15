Here is a structured, detailed **Product Requirements Document (PRD)** for your game **Gembrawl**, based entirely on your provided prompt and design:

---

# 📄 Product Requirements Document (PRD)

## 🧠 Project Title: **Gembrawl**

## 👤 Author: Batuhan

## 🗓 Date: July 2025

## 📦 Version: 0.1 (Prototype)

---

## 📝 1. Overview

**Gembrawl** is a top-down, isometric multiplayer brawler where players control sentient gem avatars, each wielding unique powers. The core gameplay loop revolves around fast-paced arena combat, where players eliminate each other using a combination of evasive movement, defensive blocks, and special gem-based skills. The last surviving player wins the match.

---

## 🎯 2. Goals and Non-Goals

### ✅ Goals

* Create a functional local practice mode with player-vs-AI or dummy
* Implement core combat systems (movement, HP, death, respawn)
* Enable local and online multiplayer with lobby creation and matchmaking
* Support full controller-based gameplay (e.g. PS4 controller)
* Deliver visually distinct gems with unique abilities and stats
* Use isometric, hexagon-based arena maps with environmental hazards

### 🚫 Non-Goals (For v0.1)

* Full ranking or progression system
* Monetization or cosmetic systems
* Match replay or spectator mode
* Dedicated server deployment

---

## 🎮 3. Core Gameplay Mechanics

### 🔘 Controls

* Fully mappable for controller and optionally keyboard
* Movement: Analog stick or WASD
* Abilities:

  * `Glide`: Fast directional dodge (evasive)
  * `Refract`: Brief block (reduces or nullifies damage)
  * `Cut`: Primary damaging attack (e.g. melee, projectile)
  * `Polish`: Secondary situational attack (mobility or utility burst)
  * `Shine`: Area denial / zoning ability

### 🧱 Structure

* Each player has HP and a limited number of lives
* Upon reaching 0 HP:

  * Player dies and respawns (if lives remain)
* Game ends when only one player has lives remaining

### 📐 Geometry

* Arenas are built on **hexagonal isometric grids**
* Perspective: **Top-down, static isometric camera**
* Players spawn at fixed or randomized spawn points

---

## 🧙 4. Gems & Skills

### ✨ Base Skills (Shared Across Gems)

| Skill   | Type      | Description                                 |
| ------- | --------- | ------------------------------------------- |
| Glide   | Evasive   | Quick burst movement in any direction       |
| Refract | Defensive | Blocks incoming damage for a short duration |

### 💎 Main Skills (Unique Per Gem)

| Slot   | Purpose     | Description Example                      |
| ------ | ----------- | ---------------------------------------- |
| Cut    | Attack      | Fast strike or projectile (low cooldown) |
| Polish | Special     | Utility skill (mobility, stun, trap)     |
| Shine  | Area Denial | AoE attack or lasting effect zone        |

Each gem has:

* Unique visuals
* Stat distribution (e.g., Speed, Power, Durability)
* Distinct skill behavior and cooldowns

---

## 🖥 5. Game Experience Flow

### ▶️ Launcher

* Menu options:

  * Practice
  * Open Room
  * Join Room
  * Settings
  * Exit

### ⚙️ Settings

* Controller settings
* Audio (SFX/Music sliders)
* Graphics (Resolution, VSync)
* Optional: Key bindings

### ❌ Exit

* Quits the game

---

## 👊 Practice Mode (Single-player)

### Flow:

1. User selects a gem to play
2. User selects an opponent gem

   * Special option: **Coal** (stationary dummy)
3. User selects an arena
4. Game starts

### Features:

* Solo match vs AI or dummy
* Respawn when HP reaches 0
* Arena with hazards

---

## 🌐 Multiplayer System

### 🔓 Open Room

* Host creates a room by setting:

  * Lobby name
  * Arena
  * Max players (2–4)
  * Optional password
* Lobby shows:

  * Connected users
  * Chat area
  * Start Game (when full)

### 🔒 Join Room

* Players see list of joinable rooms
* Can filter/search by name or arena
* Enter password if required
* Join lobby, chat with host and others

---

## 🎭 Character Selection

### Flow:

* Each player selects a gem
* Shows:

  * Stats
  * Skill descriptions
  * Cooldown values
* Everyone sees others’ current selection
* Once all players lock in → Start game

---

## ⚔️ Main Game Screen

### UI Elements:

* Countdown ("3...2...1... Fight!")
* Player’s own HP bar (large)
* Other players’ HP bars (smaller)
* Skill cooldown indicators (bottom left)
* Gem indicator (highlight to distinguish own gem)

### Gameplay Features:

* Movement, skills, and dodging
* Gem respawning (if lives remain)
* Win condition: last player standing

### Arena Elements:

* Hex-tiled level
* Obstacles and traps (spike traps, knockback zones, lava tiles)

---

## 🔌 Networking Architecture (for future milestone)

* One player hosts (peer-hosted authoritative server)
* Other players connect via LAN or direct IP
* State sync: Player position, abilities used, damage dealt
* Use **Godot high-level networking API (MultiplayerAPI + ENet)**

---

## 📁 File Structure (Recommended)

```
game/
├── project.godot
├── main.tscn
├── scenes/
│   ├── launcher/
│   ├── player/
│   ├── arena/
│   ├── ui/
│   └── lobby/
├── scripts/
│   ├── gem.gd
│   ├── player.gd
│   ├── skill.gd (base)
│   └── skills/
│       ├── cut.gd
│       ├── polish.gd
│       └── shine.gd
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   └── audio/
└── networking/
```

---

## 🧪 MVP Milestone Definition

**Minimum Viable Prototype includes:**

* Isometric top-down movement (with controller)
* Practice mode against dummy
* One fully implemented gem with all 5 skills
* One arena with traps
* Basic UI (HP, cooldowns, launcher, gem select)
* Scene transitions (launcher → game)

---
