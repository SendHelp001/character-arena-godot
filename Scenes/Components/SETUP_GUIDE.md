# Unit Component Setup Guide

## Overview
The `Unit.gd` script has been modularized into 4 separate component scripts for better maintainability and code organization.

## Components Created

### 1. UnitMovement.gd
- **Location**: `Scenes/Components/UnitMovement.gd`
- **Responsibility**: Navigation and pathfinding
- **Signals**: `movement_finished`, `target_reached`

### 2. UnitCombat.gd
- **Location**: `Scenes/Components/UnitCombat.gd`
- **Responsibility**: Auto-targeting, attacking, combat logic
- **Exports**: `auto_target_range` (15.0), `auto_target_interval` (0.5)
- **Signals**: `target_acquired(target)`, `attack_executed(target)`

### 3. UnitSelection.gd
- **Location**: `Scenes/Components/UnitSelection.gd`
- **Responsibility**: Selection state and visual feedback
- **Signals**: `selection_changed(is_selected)`
- **Features**: Proper deselect functionality with group management

### 4. UnitUI.gd
- **Location**: `Scenes/Components/UnitUI.gd`
- **Responsibility**: Stats display updates (HP/MP labels)

## Scene Setup Instructions

To use the refactored Unit system, you need to add the component nodes to your Unit scene:

### Step-by-Step Setup

1. **Open your Unit scene** (e.g., `Hero.tscn`, `Minion.tscn`, etc.)

2. **Add Component Nodes**:
   - Right-click on the root Unit node
   - Select "Add Child Node"
   - Choose "Node" type
   - Rename it to match the component name exactly:
     - `UnitMovement`
     - `UnitCombat`
     - `UnitSelection`
     - `UnitUI`

3. **Attach Scripts**:
   - For each component node:
     - Select the node
     - In the Inspector, click the scroll icon next to "Script"
     - Choose "Load"
     - Navigate to `Scenes/Components/` and select the corresponding `.gd` file

4. **Configure UnitCombat** (optional):
   - Select the `UnitCombat` node
   - In the Inspector, you can adjust:
     - `Auto Target Range`: Detection range for enemies (default: 15.0)
     - `Auto Target Interval`: How often to scan for targets (default: 0.5 seconds)

### Expected Scene Structure

```
Unit (CharacterBody3D)
├── NavigationAgent3D
├── SelectionRing
├── StatsLabel
├── UnitMovement (Node)
├── UnitCombat (Node)
├── UnitSelection (Node)
└── UnitUI (Node)
```

## API Changes

The public API of Unit.gd remains mostly the same, with some additions:

### Existing Methods (unchanged)
- `set_move_target(pos: Vector3)` - Command unit to move
- `set_selected(state: bool)` - Select/deselect unit
- `take_damage(amount)` - Deal damage to unit
- `get_team_id() -> int` - Get unit's team ID

### New Methods
- `is_selected() -> bool` - Check if unit is currently selected
- `set_combat_target(target_node: Node)` - Manually set combat target
- `get_current_target() -> Node` - Get current combat target

## Benefits

✅ **Separation of Concerns**: Each component handles one responsibility
✅ **Reusability**: Components can be reused in other unit types
✅ **Maintainability**: Easier to find and fix bugs
✅ **Testability**: Each component can be tested independently
✅ **Cleaner Code**: Main Unit.gd reduced from 184 to 112 lines
✅ **Proper Deselect**: UnitSelection now properly removes units from selected_unit group

## Component Communication

Components communicate through:
- Direct method calls from Unit.gd
- Signals for event-driven updates
- Shared references to Stats and other core data

## Troubleshooting

**Error: "Invalid get index 'process_movement'"**
- Ensure all component nodes are added to the scene
- Verify scripts are attached correctly

**Units not moving/attacking:**
- Check that NavigationAgent3D is still a child of Unit
- Verify Stats component is being initialized

**Selection not working:**
- Ensure SelectionRing node exists
- Check that UnitSelection component is set up

## Migration Notes

All existing functionality has been preserved. The refactoring is purely structural - no behavior changes should occur.
