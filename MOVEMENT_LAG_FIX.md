# Multi-Unit Movement Lag Fix

## Problem

When selecting multiple units and issuing a move command, severe lag occurred because:
1. All units tried to move to the **exact same position**
2. Units collided and pushed each other constantly
3. Physics calculations caused frame drops

## Solution

### 1. Formation Movement System ✅

**File**: [`selectionController.gd`](file:///c:/000%20JONARD/Projects/test/moba-project-godot/Scripts/selectionController.gd)

Added `_move_units_with_formation()` function that:
- **Single unit**: Moves directly to target (no change)
- **Multiple units**: Spreads them in a **circle formation** around the target

**How it works**:
```gdscript
var spread_radius = 1.5  # Distance between units
var angle_step = TAU / units.size()  # Divide circle evenly

for i in range(units.size()):
    var angle = angle_step * i
    var offset = Vector3(cos(angle), 0, sin(angle)) * spread_radius
    var target_pos = center_pos + offset
    units[i].set_move_target(target_pos)
```

**Result**: Units arrive at evenly spaced positions around the click point, preventing stacking.

---

### 2. Navigation Avoidance ✅

**File**: [`Unit.tscn`](file:///c:/000%20JONARD/Projects/test/moba-project-godot/Scenes/Unit.tscn)

Enabled `avoidance_enabled = true` on NavigationAgent3D to reduce collisions during pathfinding.

---

## Testing

### Before Fix:
- Select 3 units
- Right-click to move
- **Result**: Severe lag, units stack on same position

### After Fix:
- Select 3 units
- Right-click to move
- **Result**: No lag, units arrive in circle formation around target

---

## Adjustable Parameters

In `selectionController.gd`, line 92:
```gdscript
var spread_radius = 1.5  # Increase for wider spread
```

- `1.5` = Tight formation
- `3.0` = Loose formation
- `5.0` = Very spread out

---

## Future Enhancements

- **Formation types**: Line, box, wedge formations
- **Smart spacing**: Adjust radius based on unit count
- **Preserve formation**: Maintain formation while moving
- **Custom formations**: Let players define formation shapes
