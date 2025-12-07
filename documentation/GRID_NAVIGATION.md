# Grid Navigation System

## Overview

This project uses a **grid-based pathfinding system** similar to Dota 2, implemented with Godot's `AStarGrid2D` for high performance.

---

## How It Works

### 1. Grid Registration

When the game starts, `GridRegion` registers with `GridManager`:

```
GridRegion (Node3D in World.tscn)
    ↓ calls
GridManager.register_region(self)
    ↓ creates
AStarGrid2D with dimensions based on map_size
```

### 2. Grid Scanning

The grid scans the world to mark walkable/blocked cells:

```
For each cell (x, y):
    1. Shape cast (sphere) to check for obstacles (Layer 4)
    2. Raycast down to check for terrain (Layer 1)
    3. Check slope (normal.dot(UP) > 0.7)
    4. Mark as solid or walkable
```

### 3. Pathfinding

When a unit needs to move:

```gdscript
var path = GridManager.get_path_points(unit.position, target.position)
# Returns: PackedVector3Array of world positions
```

### 4. Path Smoothing

Raw grid paths are jagged. We smooth them:

```
Original:  A → B → C → D → E → F
           (many grid cells)

Smoothed:  A → → → → D → → F
           (straight lines where possible)
```

**Whisker raycasts** check if we can skip waypoints while maintaining clearance for unit width.

---

## Key Functions

### GridManager API

```gdscript
# Get path between two world positions
func get_path_points(from_world: Vector3, to_world: Vector3) -> PackedVector3Array

# Find walkable position near a blocked point (for Blink, etc.)
func get_closest_walkable_point(world_pos: Vector3) -> Vector3
```

### Coordinate Conversion

```gdscript
# World (X, Z) → Grid (X, Y)
func _world_to_grid(pos: Vector3) -> Vector2i

# Grid (X, Y) → World (X, Z) 
func _grid_to_world(id: Vector2i) -> Vector3
```

---

## Configuration

### GridRegion Properties

```gdscript
@export var map_size: Vector3 = Vector3(100, 1, 100)  # Width, Height, Depth
@export var cell_size: float = 1.0                    # Grid resolution
```

### Collision Masks

| Layer | Mask | Purpose                      |
| ----- | ---- | ---------------------------- |
| 1     | 1    | Terrain (walkable ground)    |
| 4     | 8    | Obstacles (walls, buildings) |

---

## Comparison to Dota 2

| Aspect      | This Project      | Dota 2          |
| ----------- | ----------------- | --------------- |
| Grid Type   | 2D overlaid on 3D | True 3D grid    |
| Cell Size   | 1.0 unit          | 64 hammer units |
| Pathfinding | AStarGrid2D       | Custom A*       |
| Diagonal    | 8-way movement    | 8-way movement  |
| Smoothing   | Line-of-sight     | Similar         |

---

## Debug Visualization

The grid draws a cyan line showing the current path. Enable in `GridManager._setup_debug_draw()`.

---

## Common Issues

### "Cannot get path: No GridRegion registered!"
- Add a `GridRegion` node to your World scene
- Ensure `GridManager` is an autoload

### Units walking into walls
- Check `collision_mask = 8` in grid scan
- Increase scan shape radius
- Verify wall is on Layer 4

### Choppy movement
- Increase `steer_force` in UnitMovement
- Check path smoothing is enabled
