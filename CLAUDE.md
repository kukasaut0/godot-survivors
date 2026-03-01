# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Godot Survivors** is a Vampire Survivors-style roguelike in Godot 4.6 (GL Compatibility renderer). All entities use `res://icon.svg` recolored via data files—no external assets needed.

## Build & Run

**Requirements:** Godot 4.6+ installed and accessible in PATH (or via direct launch)

- **Run game:** `godot`  (opens editor) or `godot --play` (plays from project root)
- **Run scene directly:** `godot res://scenes/main.tscn --play`
- **Export:** Use Godot editor → Project → Export (requires export templates)

No build step needed—Godot handles everything at runtime.

## Architecture Overview

The game is built on two core systems:

### 1. Data-Driven Design
All character/level/enemy stats live in `.tres` (Resource) files, not code. This enables rapid iteration without touching scripts:

- **CharacterData** (`scripts/data/character_data.gd`): Player speed, health, starting weapons, visuals
- **LevelData** (`scripts/data/level_data.gd`): Spawn rates, waves, difficulty scaling
- **EnemyData** (`scripts/data/enemy_data.gd`): Enemy stats, visuals, speed curves
- **Supporting data classes**: `WeaponEntry`, `EnemySpawnWave`, `EnemySpawnEntry`

Main.gd (`_ready`) loads character/level data via `@export` with fallback to `res://data/characters/default.tres` and `res://data/levels/default.tres`.

### 2. Modular Weapon System
Weapons inherit from `WeaponBase` and register with `WeaponRegistry` autoload:

- **WeaponBase** (`scripts/weapons/weapon_base.gd`): Abstract base with `level`, `upgrade()`, `_on_setup()`, `_on_upgrade()` hooks
- **Concrete weapons**:
  - `ProjectileWeapon` — fires projectiles from player position
  - `AuraWeapon` — stationary damage aura
  - `ThunderStrike` — area-of-effect damage
  - `KnifeFan` — rotating projectiles
- **Adding weapons**: Create new script extending WeaponBase, add entry to `WeaponRegistry.create_weapon()` match statement

## Key Gameplay Systems

### Player (`scripts/player.gd`)
- Extends CharacterBody2D; controlled via arrow keys / WASD
- Tracks `weapons`, `level`, `health`, `xp`
- Signals: `died`, `level_up(int)`
- Level-up multipliers: damage ×1.2, cooldown ×0.85 (min 0.15s), max_health + health_per_level

### Enemy (`scripts/enemy.gd`)
- Extends CharacterBody2D; chases player using `apply_enemy_data()` which scales speed over time
- Deals damage via distance check (contact_dist) every DAMAGE_COOLDOWN (1.0s)
- Drops XP gem on death via `died_at` signal
- Repositions if too far from viewport to prevent lag

### Spawn & Waves
Main._process() manages:
- Dynamic spawn interval that decays over time (min spawn_interval enforced)
- Wave selection by time_elapsed; weighted random picks among spawn_entries
- Spawn location: random angle + distance from player

### XP & Leveling
Player.collect_xp() → level_up if threshold reached → main._on_level_up() pauses game and shows weapon select UI

## Collision & Physics

| Entity     | Type        | Layer | Mask | Notes |
|------------|-------------|-------|------|-------|
| Player     | CharacterBody2D | 1 | 0 | Phases through enemies; damage via distance check |
| Enemy      | CharacterBody2D | 2 | 0 | Pushed by slide(); no area detection |
| Projectile | Area2D | 4 | 2 | Fires body_entered on enemies |
| XP Gem     | Area2D | 0 | 0 | Collected via distance check in _process |

## Visual Identity & Scaling

All entities use icon.svg scaled and recolored per EnemyData / CharacterData:

| Entity     | Color | Scale |
|------------|-------|-------|
| Player     | (0.3, 0.7, 1, 1) — cyan | (0.5, 0.5) |
| Enemy      | (1, 0.5, 0.2, 1) — orange | varies by type |
| Projectile | (1, 1, 0, 1) — yellow | (0.1, 0.1) |
| XP Gem     | (0, 1, 0.2, 1) — green | (0.12, 0.12) |

Visuals stored in .tres files; enemies flash red on hit via hardcoded modulate in take_damage().

## Adding Content

### New Character
1. Duplicate `res://data/characters/default.tres` → `my_character.tres`
2. Edit modulate, speed, health, starting_weapons array
3. In main.gd or via editor, set `character_data` to new file

### New Enemy Type
1. Create `res://data/enemies/my_enemy.tres` with EnemyData fields
2. Set modulate_color, base_speed, health, damage, etc.
3. Add to LevelData waves via EnemySpawnEntry with weight

### New Weapon
1. Create `scripts/weapons/my_weapon.gd` extending WeaponBase
2. Override `_on_setup()` to start timers/effects, `_on_upgrade()` to scale stats
3. Add match case to `WeaponRegistry.create_weapon()`:
   ```gdscript
   "my_weapon":
       return MyWeapon.new()
   ```
4. Add WeaponEntry to character_data.starting_weapons with weapon_id="my_weapon"

### New Level
1. Create `res://data/levels/my_level.tres` with LevelData
2. Define spawn_interval decay, count progression
3. Create EnemySpawnWave array with time ranges and weighted entries
4. Assign in main.gd via `level_data` export

## Scene Structure

- `main.tscn`: Root (Node2D with Camera2D); containers for Player, EnemiesContainer, ProjectilesContainer, GemsContainer
- `player.tscn`: CharacterBody2D with Sprite2D + CollisionShape2D
- `enemy.tscn`: CharacterBody2D with Sprite2D + CollisionShape2D
- `projectile.tscn`: Area2D with Sprite2D + CollisionShape2D
- `xp_gem.tscn`: Area2D with Sprite2D (no collision; distance-based pickup)
- `hud.tscn`: CanvasLayer with UI labels

Main scene (`run/main_scene` in project.godot) is `res://scenes/main.tscn`.

## Important Patterns

- **Signals over direct references**: Enemies emit `died_at(Vector2, int)` → main spawns gem; player emits `died` → game over
- **Speed scaling**: Enemy speed = base_speed + time_elapsed × speed_time_scale (from EnemyData)
- **Level-up UI pause**: `get_tree().paused = true` during weapon select; resumed after choice
- **Distance checks for damage/pickup**: Avoids Area2D overlap complexity; used for enemy→player damage and gem→player pickup
- **Weighted random**: `_weighted_pick()` in main.gd for spawn wave selection

## Godot-Specific Notes

- **Autoload**: WeaponRegistry is registered in project.godot `[autoload]`
- **Preloads**: main.gd preloads enemy and xp_gem scenes for instantiation
- **@onready**: Used for node references; cache player, containers, camera, hud in _ready
- **@export**: Character/level data exposed in editor for per-scene overrides
- **Signals/connects**: Heavy use of custom signals for decoupling (died, died_at, level_up, upgraded, etc.)
- **Physics**: CharacterBody2D.move_and_slide() for collision; Area2D.body_entered for projectile hits

## Common Editing Patterns

- **Tweak balance**: Edit .tres files (stats, colors, spawn weights) without touching code
- **Debug spawning**: Adjust LevelData wave times, spawn_count, intervals
- **Visual feedback**: Enemy takes damage → flash red (hardcoded) for 0.1s
- **Stat scaling**: Use time_elapsed from main._process() for progressive difficulty
- **New attack patterns**: Extend WeaponBase, use _process/_physics_process in weapon, spawn projectiles to container
