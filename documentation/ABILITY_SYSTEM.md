# Ability System Documentation

## Overview

This project uses an **event-driven ability system** modeled after Dota 2's cast point and channeling mechanics.

---

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Ability.gd    │────▶│ AbilityInstance  │────▶│ FireballAbility │
│   (Resource)    │     │ (State Machine)  │     │ (Event Handler) │
│   Data + Signals│     │ Timing Logic     │     │ Actual Effects  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### Components

1. **Ability.gd** (Resource) - Data container with lifecycle signals
2. **AbilityInstance.gd** (Node) - State machine that handles timing
3. **\*Ability.gd** (Scripts) - Specific ability implementations

---

## Lifecycle Signals

```gdscript
signal on_cast_begin(caster, target_pos, target_unit)
signal on_cast_point_finish(caster, target_pos, target_unit)
signal on_channel_tick(caster, tick_count)
signal on_channel_finish(caster)
signal on_channel_interrupted(caster)
signal on_cooldown_ready()
```

### Timeline

```
Player presses Q
       │
       ▼
┌─────────────────┐
│ on_cast_begin   │  ← Unit starts turn animation
└────────┬────────┘
         │ (turn to face target)
         ▼
┌─────────────────┐
│ CAST_POINT      │  ← Unit is winding up (interruptible)
│ (0.5s default)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ on_cast_point_finish│  ← DAMAGE/EFFECT HAPPENS HERE
└────────┬────────────┘
         │ (if has channel)
         ▼
┌─────────────────┐
│ CHANNELING      │  ← Tick every channel_tick_rate
│ (ticks every    │     on_channel_tick emitted
│  0.5s default)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ on_channel_finish│  ← Channel completed
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ COOLDOWN        │  ← Wait cooldown seconds
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ on_cooldown_ready│  ← Can cast again
└─────────────────┘
```

---

## Cast States

```gdscript
enum CastState {
    IDLE,           # Ready to cast
    TURNING,        # Rotating to face target
    CAST_POINT,     # Wind-up animation (cancellable)
    CHANNELING,     # Holding the spell
    COOLDOWN        # Waiting to cast again
}
```

---

## Key Properties (Ability.gd)

```gdscript
@export var ability_name: String
@export var icon: Texture2D
@export var mana_cost: float = 0.0
@export var cooldown: float = 5.0
@export var cast_range: float = 10.0
@export var cast_radius: float = 0.0      # AoE size
@export var cast_point: float = 0.5       # Wind-up time
@export var channel_duration: float = 0.0 # 0 = no channel
@export var channel_tick_rate: float = 0.5

# Targeting
@export var target_type: TargetType  # NONE, POINT, UNIT, AREA
@export var target_team: TargetTeam  # ALLY, ENEMY, BOTH

# Behavior Flags
@export var can_move_while_channeling: bool = false
@export var can_cast_while_channeling: bool = false
```

---

## Creating a New Ability

### Step 1: Create Script

```gdscript
# Scripts/Abilities/FrostNovaAbility.gd
extends Ability

func _init():
    ability_name = "Frost Nova"
    cast_point = 0.3
    cooldown = 8.0
    mana_cost = 100
    cast_range = 600
    cast_radius = 300
    target_type = TargetType.POINT

func _ready():
    on_cast_point_finish.connect(_on_cast)

func _on_cast(caster, target_pos, _target_unit):
    # Spawn AoE effect at target_pos
    # Deal damage to enemies in radius
    # Apply slow debuff
    pass
```

### Step 2: Create Resource

Create `Resources/Abilities/FrostNova.tres`:
- Set script to `FrostNovaAbility.gd`
- Configure values in inspector
- Assign icon texture

### Step 3: Add to Unit

In the unit's `StatData.tres`:
```gdscript
abilities = [
    preload("res://Resources/Abilities/Fireball.tres"),
    preload("res://Resources/Abilities/FrostNova.tres")
]
```

---

## Interruption Mechanics

### What Interrupts Casting/Channeling

| Action          | Interrupts Cast Point | Interrupts Channel |
| --------------- | --------------------- | ------------------ |
| Move command    | ✅ Yes                 | ✅ Yes              |
| Attack command  | ✅ Yes                 | ✅ Yes              |
| Stun/CC         | ✅ Yes                 | ✅ Yes              |
| Another ability | Depends               | ✅ Usually          |

### Code Location

```gdscript
# AbilityInstance.gd
func _should_interrupt_channel() -> bool:
    # Checks movement, attacks, stun status
```

---

## Comparison to Dota 2

| Mechanic    | This Project      | Dota 2 |
| ----------- | ----------------- | ------ |
| Cast Point  | ✅ Same            | ✅      |
| Channeling  | ✅ Same            | ✅      |
| Turn Rate   | ✅ Same            | ✅      |
| Interrupts  | ✅ Similar         | ✅      |
| Backswing   | ❌ Not implemented | ✅      |
| Shift-queue | ❌ Not implemented | ✅      |
