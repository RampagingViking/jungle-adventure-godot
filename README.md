# 🌴 Jungle Adventure - Godot Version

A DKC-inspired rolling platformer prototype, now in **Godot Engine 4.x**!

## 🎮 Features Implemented

### Core Mechanics
- **Rolling** - Quick roll to dodge attacks and slide under obstacles
- **Ground Pound** - Dive downward to break enemies and activate switches
- **Double Jump** - Jump again in mid-air
- **Barrel Cannons** - Launch in arc patterns to reach new areas

### Game Elements
- **Enemy stomping** - Defeat enemies by jumping on them
- **Banana collection** - Collectibles with visual feedback
- **Patrolling enemies** - Basic AI behavior
- **Smooth camera** - Follows player with bounds

## 📁 Project Structure

```
jungle-adventure-godot/
├── project.godot              # Godot project file
├── icon.svg                   # Project icon
├── README.md                  # This file
├── Assets/
│   └── (sprites, sounds, etc.)
├── Scenes/
│   └── Main.tscn              # Main game scene
└── Scripts/
    ├── PlayerController.gd    # Core player movement and abilities
    ├── Enemy.gd              # Basic enemy AI
    ├── BarrelCannon.gd       # Barrel cannon mechanic
    ├── Banana.gd             # Collectible items
    └── CameraController.gd   # Smooth camera follow
```

## 🚀 Setup Instructions

### 1. Download Godot
1. Go to **https://godotengine.org/download**
2. Download **Godot 4.x** (Standard version)
3. Install and open

### 2. Import Project
1. Click **"Import"** button
2. Navigate to `jungle-adventure-godot/project.godot`
3. Click **"Import & Edit"**

### 3. Create Scenes

#### Player Scene
1. Create new Scene → **CharacterBody2D** → Rename to "Player"
2. Add **Sprite2D** (your player sprite)
3. Add **CollisionShape2D** → Circle shape
4. Add **Script** → Load `Scripts/PlayerController.gd`
5. Add to group: "Player" (Node → Groups → Add "Player")

#### Enemy Scene
1. Create new Scene → **Node2D** → Rename to "Enemy"
2. Add **Sprite2D** (enemy sprite)
3. Add **CollisionShape2D** (optional, for player detection)
4. Add **Script** → Load `Scripts/Enemy.gd`

#### Banana Scene
1. Create new Scene → **Area2D** → Rename to "Banana"
2. Add **Sprite2D** (banana sprite)
3. Add **CollisionShape2D** → Circle shape
4. Add **Script** → Load `Scripts/Banana.gd`

#### Barrel Cannon Scene
1. Create new Scene → **Area2D** → Rename to "BarrelCannon"
2. Add **Sprite2D** (barrel sprite)
3. Add **CollisionShape2D** → Rectangle/Circle shape
4. Add **Script** → Load `Scripts/BarrelCannon.gd`

#### Main Scene
1. Create new Scene → **Node2D** → Rename to "Main"
2. Add **Camera2D** → Add Script `Scripts/CameraController.gd`
3. Add **TileMap** or **StaticBody2D** platforms
4. Add instances of Player, Enemies, Bananas, Barrels

## 🎮 Controls

| Input | Action |
|-------|--------|
| Arrow Keys / WASD | Move |
| Space | Jump |
| X / Shift | Roll |
| Down (in air) | Ground Pound |
| Up/Down (in barrel) | Aim barrel |
| Fire (in barrel) | Launch |

## 📝 Script Configuration

### PlayerController Settings (Editable in Inspector)
```
Move Speed: 8
Jump Force: 14
Roll Speed: 12
Roll Duration: 0.4s
Ground Pound Force: 25
```

## 🔧 Adjusting the Feel

- Increase `acceleration` for snappier movement
- Decrease `roll_duration` for quicker rolls
- Adjust `fall_multiplier` for better jump feel

## 🎨 Art Style Tips

Since this is DKC-inspired but original:
- Create YOUR character (not Donkey Kong)
- Design YOUR enemies (not DKC enemies)
- Make YOUR levels (similar feel, different content)
- Compose YOUR music (tropical, jungle themes)

## 📚 Resources

### Godot Learning
- docs.godotengine.org (Official documentation)
- youtube.com/@GDQuest
- youtube.com/@KidsCanCode

### Art Tools
- Aseprite (pixel art)
- Piskel (free pixel art)
- Kenney Assets (free game assets)

### Sound
- Bfxr (retro SFX)
- Freesound.org (general sounds)

---

*Built with Godot 4.x*
*Created: February 2, 2026*
*Ported from Unity to Godot*
