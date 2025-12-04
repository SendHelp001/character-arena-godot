# Character Roster

## Overview

Three distinct hero archetypes, each with unique stat distributions designed for different playstyles.

---

## 🛡️ Warrior (hero1.tres)

**Role**: Melee Tank  
**Resource**: `res://ResourceStats/hero1.tres`

| Stat | Value | Notes |
|------|-------|-------|
| **Name** | Warrior | |
| **Max HP** | 600 | Highest durability |
| **Move Speed** | 10.0 | Standard mobility |
| **Attack Damage** | 55 | Moderate damage |
| **Attack Range** | 2.5 | Melee range |
| **Attack Cooldown** | 1.2s | Fast attack speed |
| **Armor** | 15.0 | High physical defense |
| **Mana** | 150 | Low mana pool |
| **Mana Regen** | 1.5/s | Low regen |
| **Gold Worth** | 100 | Kill reward |

**Playstyle**: Frontline bruiser who can sustain in prolonged fights. High armor makes them effective against physical damage. Limited mana means abilities should be used sparingly.

---

## 🏹 Archer (hero_archer.tres)

**Role**: Ranged DPS  
**Resource**: `res://ResourceStats/hero_archer.tres`

| Stat | Value | Notes |
|------|-------|-------|
| **Name** | Archer | |
| **Max HP** | 420 | Medium-low HP |
| **Move Speed** | 11.0 | Fastest movement |
| **Attack Damage** | 75 | High damage |
| **Attack Range** | 8.0 | Long range |
| **Attack Cooldown** | 1.5s | Slower attacks |
| **Armor** | 6.0 | Very low defense |
| **Mana** | 200 | Medium mana |
| **Mana Regen** | 2.0/s | Medium regen |
| **Gold Worth** | 120 | Higher reward |

**Playstyle**: Kiting ranged damage dealer. Relies on positioning and long range to stay safe. Vulnerable in melee combat due to low HP and armor. Fast movement helps with repositioning.

---

## 🔮 Mage (hero_mage.tres)

**Role**: Glass Cannon Caster  
**Resource**: `res://ResourceStats/hero_mage.tres`

| Stat | Value | Notes |
|------|-------|-------|
| **Name** | Mage | |
| **Max HP** | 350 | Lowest HP |
| **Move Speed** | 9.5 | Slowest movement |
| **Attack Damage** | 95 | Highest damage |
| **Attack Range** | 10.0 | Longest range |
| **Attack Cooldown** | 2.0s | Slowest attacks |
| **Armor** | 3.0 | Minimal defense |
| **Mana** | 500 | Massive mana pool |
| **Mana Regen** | 4.0/s | Highest regen |
| **Gold Worth** | 150 | Premium target |

**Playstyle**: Ultimate glass cannon - devastating damage from extreme range, but extremely fragile. Large mana pool supports frequent ability usage. Slow movement and attack speed require careful positioning.

---

## Character Comparison

```
                 Warrior    Archer    Mage
Durability       ████████   ████░░░   ██░░░░
Damage           █████░░░   ███████   █████████
Range            ██░░░░░░   ████████  ██████████
Speed            █████░░░   ███████   ████░░░
Mana Capacity    ███░░░░░   █████░░   ██████████
```

---

## Testing Characters

To test different characters in `World.tscn`:

1. Select a Unit node in the scene tree
2. In the Inspector, find **Stats Resource** property
3. Select from:
   - `hero1.tres` (Warrior)
   - `hero_archer.tres` (Archer)
   - `hero_mage.tres` (Mage)
4. Run the scene to test behavior

**Expected Differences:**
- Archer should die faster but deal more damage per hit
- Mage should have very low health but hit hardest from longest range
- Warrior should survive longest in combat

---

## Future Plans

- [ ] Create enemy mob variants (weak, elite, boss)
- [ ] Add visual differentiation (colors, meshes, models)
- [ ] Implement character selection UI
- [ ] Add abilities system (using mana)
- [ ] Create character spawning system
