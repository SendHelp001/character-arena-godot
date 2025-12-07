# Combat System Documentation

## Overview

The combat system implements Dota 2-style **attack windup** mechanics with cancellable animations.

---

## Attack Phases

```
┌──────────────────┐
│ IDLE             │  ← No target, waiting
└────────┬─────────┘
         │ (target acquired)
         ▼
┌──────────────────┐
│ MOVING_TO_TARGET │  ← Walking into attack range
└────────┬─────────┘
         │ (in range + facing)
         ▼
┌──────────────────┐
│ WINDING_UP       │  ← Attack point (CANCELLABLE)
│ (attack_point)   │     Move command cancels here
└────────┬─────────┘
         │ (timer finished)
         ▼
   ★ DAMAGE DEALT ★    ← Projectile spawned / damage applied
         │
         ▼
┌──────────────────┐
│ IN_BACKSWING     │  ← Recovery animation
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ATTACK_COOLDOWN  │  ← Wait for next attack
└────────┬─────────┘
         │
         ▼
     (loop back to IDLE or WINDING_UP)
```

---

## Key Properties (StatData)

```gdscript
attack_damage: int = 10       # Base damage per hit
attack_range: float = 1.5     # Distance to target (melee ~1.5, ranged ~6+)
attack_cooldown: float = 1.0  # Full attack cycle time
attack_point: float = 0.3     # Windup before damage (30% of 1.0s)
```

### Attack Point vs Backswing

```
|-------- attack_cooldown (1.0s) --------|
|-- attack_point --|---- backswing ------|
|      0.3s        |       0.7s          |
        ↑
   Damage happens here
```

---

## Melee vs Ranged

### Melee Units
- Direct damage on attack_point finish
- Short attack_range (~1.5)

### Ranged Units
```gdscript
# UnitCombat properties
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene
```

- Spawns projectile on attack_point finish
- Projectile travels to target
- Damage on projectile hit

---

## Auto-Targeting AI

```gdscript
# UnitCombat.gd
@export var auto_target_range := 15.0
@export var auto_target_interval := 0.5
```

### Behavior
1. **Right-click enemy**: Lock onto that target (highest priority)
2. **Attack-move**: Attack nearest enemy while moving
3. **Idle**: Attack nearest enemy in range

### Player Command Flag
```gdscript
var is_player_commanded: bool = false

func set_target(new_target: Node, from_player: bool = false):
    target = new_target
    is_player_commanded = from_player
```

When `is_player_commanded = true`, the unit will NOT auto-switch targets.

---

## Combat API

```gdscript
# Set attack target
unit.combat.set_target(enemy_unit, from_player: bool)

# Get current target
unit.combat.get_current_target() -> Node

# Cancel attack (move command)
unit.combat.cancel_attack()
```

---

## Damage Flow

```
Attacker                              Target
   │                                    │
   │ attack_point elapsed               │
   ├────────────────────────────────────▶
   │         deal damage                │
   │                                    ▼
   │                              Stats.take_damage()
   │                                    │
   │                              damage_taken signal
   │                                    │
   │                              DamageNumber spawned
   │                                    │
   │                              hp_changed signal
   │                                    │
   │                              HealthBar updated
```

---

## Comparison to Dota 2

| Mechanic            | This Project     | Dota 2    |
| ------------------- | ---------------- | --------- |
| Attack Point        | ✅ Yes            | ✅         |
| Backswing           | ✅ Yes            | ✅         |
| Move Cancel         | ✅ Yes            | ✅         |
| Turn to Attack      | ✅ Yes            | ✅         |
| Orb Walking         | ❌ No             | ✅         |
| Attack Speed        | ❌ Fixed cooldown | ✅ Dynamic |
| Projectile Disjoint | ❌ No             | ✅         |
