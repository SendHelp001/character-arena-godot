# Ally Follow Feature

## Overview

Units can now follow allied units by right-clicking on them. This is useful for:
- Escort missions
- Coordinated movement
- Protecting weaker allies
- Formation-based tactics

---

## How to Use

### Basic Follow Command

1. **Select** a unit (left-click)
2. **Right-click** on a friendly unit
3. The selected unit will continuously follow the target

### Multi-Unit Follow

1. Select **multiple units** (Shift + click)
2. Right-click on a friendly unit
3. All selected units will follow the target

### Stop Following

Press **S** key to stop all actions (including following)

---

## Implementation Details

### Files Modified

1. **[`UnitMovement.gd`](file:///c:/000%20JONARD/Projects/test/moba-project-godot/Scenes/Components/UnitMovement.gd)**
   - Added `follow_target` variable
   - Added `set_follow_target()` method
   - Updated `process_movement()` to continuously update path to follow target
   - Updated `stop_movement()` to clear follow target

2. **[`Unit.gd`](file:///c:/000%20JONARD/Projects/test/moba-project-godot/Scenes/Unit.gd)**
   - Added `set_follow_target()` public API
   - Sets unit to passive mode when following (no auto-attacking)

3. **[`selectionController.gd`](file:///c:/000%20JONARD/Projects/test/moba-project-godot/Scripts/selectionController.gd)**
   - Changed ally right-click behavior from ignore to follow command
   - Prints "Follow command issued on ally: [name]"

---

## Behavior

### Follow Logic

- **Continuous Tracking**: The follower constantly updates its path to the target's current position
- **No Range Limit**: Units will follow indefinitely until commanded otherwise
- **Auto-Updates**: If the followed unit moves, the follower automatically adjusts its path
- **Passive Mode**: Following units switch to passive combat mode (won't auto-attack)

### Edge Cases Handled

- **Target Dies**: If the followed unit is destroyed, following stops automatically
- **Manual Commands Override**: Any move command or attack command cancels following
- **Stop Command**: Pressing **S** key stops following
- **Follow Self**: Units cannot follow themselves (no logic prevents this yet - could be added)

---

## Example Use Cases

### 1. Protect the Mage
```
1. Select Warrior
2. Right-click on Mage
3. Warrior follows Mage everywhere, providing protection
```

### 2. Formation Movement
```
1. Select all ranged units
2. Right-click on the frontline Warrior
3. Ranged units stay behind the tank
```

### 3. Escort Mission
```
1. Select multiple guards
2. Right-click on VIP unit
3. Guards follow and protect the VIP
```

---

## Testing

### Test 1: Basic Follow
1. Run the game
2. Select the **Warrior** (left unit)
3. Right-click on **Archer** (center unit)
4. **Expected**: Warrior moves to Archer's position
5. Move the Archer elsewhere
6. **Expected**: Warrior follows the Archer

### Test 2: Stop Follow
1. While following, press **S** key
2. **Expected**: Warrior stops moving and stops following

### Test 3: Override Follow
1. Start following
2. Right-click on ground (move command)
3. **Expected**: Following stops, unit moves to location

### Test 4: Multi-Unit Follow
1. Select both Warrior and Mage (Shift+click)
2. Right-click on Archer
3. **Expected**: Both units follow Archer

---

## Future Enhancements

- **Follow Distance**: Option to maintain a specific distance from target
- **Formation Following**: Multiple units follow in a formation pattern
- **Follow Queue**: String together multiple follow commands
- **Guard Mode**: Follow + auto-attack enemies near the followed unit
- **Visual Indicator**: Show a line or icon indicating follow relationship

---

## Known Limitations

- No minimum/maximum follow distance
- Units try to pathfind to exact position (may crowd)
- No collision avoidance between followers
- Following does not persist through save/load (not implemented yet)
