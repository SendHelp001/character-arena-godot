# MOBA Project - System Architecture Overview

## Quick Reference for AI Analysis

This document provides a high-level overview of all major systems to help AI assistants understand the codebase quickly.

---

## 1. Grid-Based Pathfinding (Similar to Dota 2)

**Location:** `Scripts/GridManager.gd`

### Implementation
- Uses Godot's `AStarGrid2D` (C++ performance)
- Maps 3D World (X, Z) → 2D Grid (X, Y)
- 8-way movement with diagonal support
- Cell size: 1.0 unit (configurable)

### Key Features
- **Obstacle Detection**: SphereShape3D volume check (not thin raycast)
- **Terrain Validation**: Raycast down to check walkability and slope
- **Path Smoothing**: Greedy line-of-sight with "whisker" raycasts for width
- **Blocked Target Handling**: Spiral search for nearest walkable cell

### Collision Layers
- Layer 1: Terrain (ground)
- Layer 4 (mask 8): Walls/Obstacles

### API
```gdscript
GridManager.get_path_points(from: Vector3, to: Vector3) -> PackedVector3Array
GridManager.get_closest_walkable_point(pos: Vector3) -> Vector3
```

---

## 2. Unit Movement (Dota 2 Turn Rate System)

**Location:** `Scripts/Units/Components/UnitMovement.gd`

### Implementation
- Context Steering with 8 ray directions
- Dota 2-style turn rate (degrees/second)
- Face requirement threshold before action

### Key Properties
```gdscript
turn_rate: float = 360.0      # Degrees per second
face_requirement: float = 0.7  # Dot product threshold (0.7 ≈ 45°)
steer_force: float = 15.0     # Smoothing
stop_distance: float = 0.5    # Waypoint arrival
```

### Signals
- `movement_finished` - Path complete
- `target_reached` - At destination

---

## 3. Combat System (Attack Windup like Dota 2)

**Location:** `Scripts/Units/Components/UnitCombat.gd`

### Attack Phases
1. **MOVING_TO_TARGET** - Walking into range
2. **WINDING_UP** - Attack point animation (cancellable)
3. **IN_BACKSWING** - Post-damage recovery
4. **IDLE** - Ready for next action

### Key Properties (from StatData)
```gdscript
attack_point: float = 0.3    # Windup before damage
attack_cooldown: float = 1.0 # Full attack time
attack_range: float = 1.5    # Melee/ranged
```

### Mechanics
- Attack windup cancellable by move command
- Turn to face target before attacking
- Ranged units spawn projectiles
- Auto-targeting when idle (configurable)

---

## 4. Ability System (Event-Driven like Dota 2)

**Location:** `Scripts/Abilities/`

### Architecture
```
Ability.gd (Resource)     - Data container with signals
AbilityInstance.gd (Node) - State machine for casting
*Ability.gd               - Specific ability logic
```

### Lifecycle Signals
1. `on_cast_begin` - Ability key pressed
2. `on_cast_point_finish` - Damage/effect happens here
3. `on_channel_tick` - Each tick during channel
4. `on_channel_finish` - Channel completed
5. `on_channel_interrupted` - Cancelled
6. `on_cooldown_ready` - Can cast again

### Cast States
```gdscript
enum CastState { IDLE, TURNING, CAST_POINT, CHANNELING, COOLDOWN }
```

### Key Properties
```gdscript
cast_point: float      # Wind-up time before effect
channel_duration: float # Post-cast channel time
cast_range: float      # Max targeting distance
cooldown: float        # Time until next cast
mana_cost: float       # Resource cost
```

### Interruption
- Movement cancels casting/channeling
- Stuns interrupt channels
- Configurable with `can_move_while_channeling`

---

## 5. Unit Structure

**Location:** `Scripts/Units/Unit.gd`

### Components (Child Nodes)
- `UnitMovement` - Pathfinding and movement
- `UnitCombat` - Attack logic
- `UnitSelection` - Click/selection handling
- `UnitUI` - Health text display
- `UnitAbilities` - Ability slots (6 max)

### Key Properties
```gdscript
stats_resource: StatData  # Assigned in inspector
team_id: int = 0          # 0=player, 1=enemy, 2=neutral
stats: Stats              # Runtime stats component
```

---

## 6. Stats System

**Location:** `Scripts/StatData.gd` (Resource), `Scripts/Stat.gd` (Runtime)

### StatData (Resource - Inspector Editable)
```gdscript
max_hp: float
max_mana: float
mana_regen: float        # Per second
move_speed: float
attack_damage: int
attack_range: float
attack_cooldown: float
attack_point: float
armor: float
portrait_icon: Texture2D # For UI
abilities: Array[Resource]
```

### Stats (Runtime Signals)
```gdscript
signal hp_changed(current, max)
signal mana_changed(current, max)
signal damage_taken(amount, type)
signal died()
```

---

## 7. Collision Layer Reference

| Layer | Purpose        | Used By                  |
| ----- | -------------- | ------------------------ |
| 1     | Terrain/Ground | Floor, walkable surfaces |
| 2     | Units          | CharacterBody3D units    |
| 4     | Walls          | Obstacles, buildings     |

**Important:** All units must have `collision_layer = 1` and `collision_mask = 1` to collide with each other.

---

## 8. UI Systems

### In-World UI
- `UnitHealthBar.tscn` - 3D billboard above units
- `DamageNumber.tscn` - Floating damage popups
- `CastingBar.tscn` - Cast/channel progress

### Screen UI
- `PlayerUI.tscn` - Bottom bar with HP/MP/abilities
- `SelectionBox.gd` - RTS-style box selection

---

## 9. File Naming Conventions

- `*.gd` - GDScript files
- `*.tscn` - Scene files
- `*.tres` - Resource files (StatData, Abilities)
- `*Ability.gd` - Specific ability implementations
- `Unit*.gd` - Unit component scripts

---

## 10. Common Patterns

### Adding a New Ability
1. Create `Scripts/Abilities/MyAbility.gd` extending `Ability.gd`
2. Create `Resources/Abilities/MyAbility.tres`
3. Connect to lifecycle signals in script
4. Add to unit's `StatData.abilities` array

### Adding a New Unit
1. Duplicate `Scenes/Units/Mage/Mage.tscn`
2. Create new `ResourceStats/hero_*.tres`
3. Assign stats resource in inspector
4. Set `collision_layer = 1`, `collision_mask = 1`

---

## Comparison to Dota 2

| Feature      | This Project | Dota 2          |
| ------------ | ------------ | --------------- |
| Grid Size    | 1.0 unit     | 64 hammer units |
| Turn Rate    | Degrees/sec  | Radians/sec     |
| Attack Point | Same concept | Same            |
| Cast Point   | Same concept | Same            |
| Channeling   | Event-driven | Similar         |
| Pathfinding  | AStarGrid2D  | Custom grid     |
