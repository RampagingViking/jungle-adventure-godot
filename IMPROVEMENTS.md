# Jungle Adventure v2.0 - Improvements

## Bug Fixes & Polish ✅

### PlayerController.gd
- **Coyote Time** - Jump shortly after leaving ledge (responsive)
- **Jump Buffering** - Queue jump if pressed before landing
- **Better Grounded Checks** - Improved edge detection

### Enemy.gd v2.0
- **Hitbox Frames** - Invincibility after being hit
- **Death Effects** - Particles, screen shake
- **State Machine** - Cleaner AI states (Idle, Patrol, Chase, Hit, Dead)
- **Flying/Ranged Variants** - New enemy types supported

### Banana.gd v2.0
- **Glow Effect** - Bananas glow when player is near
- **Sparkle Particles** - Collection effects
- **Score Popup** - Visual "+10" feedback
- **Banana Chains** - DKC-style floating collectible chains

## New Features 🎮

### New Enemy Types
1. **FlyingEnemy.gd** - Flying enemy with dive attacks
2. **Projectile.gd** - For ranged enemies

### Particle System
- **ParticleEffects.gd** - Reusable particle library
  - Dust clouds (running, landing)
  - Sparks (impacts)
  - Celebrations (collections)
  - Enemy death explosions

## How to Use

### Flying Enemy
1. Create new scene with FlyingEnemy.gd
2. Set enemy_type to "flying"
3. Adjust fly_range_x/y for patrol area

### Banana Chains
1. Create Banana scene
2. Set is_chain = true
3. Set chain_direction (Vector2.DOWN, UP, LEFT, etc.)
4. Set chain_count for number of bananas

### Particle Effects
```gdscript
# In any script
ParticleEffects.create_dust(get_parent(), global_position)
ParticleEffects.create_celebration(get_parent(), global_position)
ParticleEffects.create_enemy_death(get_parent(), global_position)
```

## Files Changed
- Scripts/PlayerController.gd - Bug fixes + polish
- Scripts/Enemy.gd - Complete rewrite v2.0
- Scripts/Banana.gd - Enhanced v2.0
- Scripts/FlyingEnemy.gd - NEW
- Scripts/Projectile.gd - NEW
- Scripts/ParticleEffects.gd - NEW

## What's Next?
- More enemy types (boss, mini-boss)
- Level design templates
- Sound effects integration
- Animation state machine
