# Combat Control System - Summary

## New Combat Behavior

### **Passive Mode (Default)**
- Units start in **PASSIVE** mode
- Will NOT auto-attack or search for enemies
- Only responds to explicit commands

### **Aggressive Mode (After Attack Command)**
- Activated when you right-click on an **enemy unit**
- Unit will auto-target and attack enemies within range
- Continues until another command is issued

## Commands

### Attack Command
- **Right-click on enemy unit** to issue attack command
- Unit enters aggressive mode
- Will auto-attack and pursue the target
- If target dies, will find next nearest enemy automatically

### Move Command
- **Right-click on ground** to move
- Switches unit to **PASSIVE mode** (stops auto-attacking)
- Unit will only move, won't attack enemies en route

### Stop Command
- **Press "S" key** to stop all actions
- Stops movement AND combat
- Switches to **PASSIVE mode**
- Unit becomes idle

### Select/Deselect
- **Left-click unit**: Select
- **Shift + Left-click**: Multi-select
- **Left-click ground**: Deselect all

## Code Changes

### UnitCombat.gd
- Added `CombatMode` enum (PASSIVE/AGGRESSIVE)
- Added `set_aggressive_mode(bool)` method
- Auto-targeting only works in AGGRESSIVE mode
- Added `stop_all_actions()` method

### Unit.gd
- Added `stop_all_actions()` method
- `set_move_target()` now switches to passive mode
- `set_combat_target()` switches to aggressive mode

### selectionController.gd
- Added "S" key handler for stop command
- Right-click on enemy now issues attack command
- Right-click on ground issues move command (as before)

## Signals
New signal added: `combat_mode_changed(is_aggressive: bool)`
- Emitted when combat mode changes
- Can be used for UI indicators (e.g., show sword icon when aggressive)
