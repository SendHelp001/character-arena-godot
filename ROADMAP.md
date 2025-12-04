# Bare Minimum Requirements Before Character Loaders

## Current State Analysis

**What you have:**
- ✅ Core `Unit.gd` class with modular components (movement, combat, selection, UI)
- ✅ `StatData.gd` resource system for character stats
- ✅ One character resource (`hero1.tres`) - **only has move_speed defined!**
- ✅ Basic MOBA mechanics (selection, movement, combat)
- ✅ Two units in World.tscn (player team + enemy team)

**Critical Gap:**
- ❌ **Only ONE character exists** (`hero1.tres`)
- ❌ **Incomplete stat data** - `hero1.tres` only defines `move_speed`, missing all other stats!
- ❌ No character variety/diversity
- ❌ No way to spawn characters dynamically
- ❌ No character selection system

---

## Why Character Loaders Aren't Useful Yet

**Character loaders are for loading MULTIPLE characters**, but you currently have:
- Only 1 character definition
- That character is incomplete (missing HP, attack damage, etc.)
- No system to showcase different characters
- No way for players to choose between characters

**Analogy**: Building a character loader now is like building a car dealership when you only have one broken bicycle.

---

## Bare Minimum Roadmap

### Phase 1: Complete Your First Character ⭐ **START HERE**

**Goal**: Make `hero1.tres` a fully functional, complete character.

**Tasks**:
1. ✅ Add ALL missing stats to `hero1.tres`:
   ```
   name = "Warrior"
   max_hp = 500
   move_speed = 10.0 (already set)
   attack_damage = 50
   attack_range = 2.0
   attack_cooldown = 1.0
   armor = 10.0
   mana = 100
   mana_regen = 1.0
   ```

2. ✅ Test that the character works properly:
   - Can move (already working)
   - Can attack (should work with combat system)
   - Takes damage correctly
   - Dies when HP reaches 0

3. ✅ Verify Unit.tscn properly uses `hero1.tres`

**Why this matters**: You can't have a character loading system if your first character doesn't even work!

---

### Phase 2: Create 2-3 Distinct Characters

**Goal**: Build variety so there's something to SELECT from.

**Tasks**:
1. Create `hero_warrior.tres` - Melee tank
   - High HP (800)
   - High armor (20)
   - Low speed (8.0)
   - Medium damage (60)
   - Short range (2.0)

2. Create `hero_archer.tres` - Ranged DPS
   - Medium HP (400)
   - Low armor (5)
   - Medium speed (10.0)
   - High damage (80)
   - Long range (8.0)

3. Create `hero_mage.tres` - Magic caster
   - Low HP (300)
   - Low armor (2)
   - Medium speed (9.0)
   - Very high damage (100)
   - Long range (10.0)
   - High mana (500)

**Test**: Manually spawn all 3 characters in World.tscn, verify they feel different.

---

### Phase 3: Dynamic Character Spawning System

**Goal**: Be able to spawn characters at runtime (not just in editor).

**Tasks**:
1. Create `CharacterSpawner.gd` script:
   ```gdscript
   extends Node

   @export var unit_scene: PackedScene = preload("res://Scenes/Unit.tscn")
   @export var spawn_position: Vector3 = Vector3.ZERO

   func spawn_character(stat_resource: StatData, team: int) -> Unit:
       var unit = unit_scene.instantiate()
       unit.stats_resource = stat_resource
       unit.team_id = team
       get_tree().current_scene.add_child(unit)
       unit.global_position = spawn_position
       return unit
   ```

2. Test spawning characters via code/button press

**Why this matters**: Character loaders need a way to SPAWN loaded characters. This is that system.

---

### Phase 4: Basic Character Selection UI

**Goal**: Let players choose which character to play.

**Tasks**:
1. Create `CharacterPicker.tscn`:
   - Simple UI with 3 buttons (Warrior, Archer, Mage)
   - Shows character stats on hover
   - "Select" button spawns chosen character

2. Create `CharacterRegistry.gd` (autoload):
   ```gdscript
   extends Node

   var characters: Dictionary = {
       "warrior": preload("res://ResourceStats/hero_warrior.tres"),
       "archer": preload("res://ResourceStats/hero_archer.tres"),
       "mage": preload("res://ResourceStats/hero_mage.tres"),
   }

   func get_character(id: String) -> StatData:
       return characters.get(id)

   func get_all_characters() -> Array:
       return characters.values()
   ```

3. Wire UI to spawner system

**Why this matters**: This is the FOUNDATION that character loaders will extend. Instead of 3 hardcoded characters, loaders will add modded characters to this registry.

---

### Phase 5: Visual Differentiation (Optional but Recommended)

**Goal**: Make characters visually distinct.

**Options**:
- **Easy**: Different colored materials on the capsule mesh
- **Medium**: Different mesh shapes (capsule, cube, sphere)
- **Hard**: Custom 3D models per character

**Why this matters**: Players need to SEE the difference between characters. Currently all units look identical.

---

## Summary: Implementation Order

| Priority | Phase | Why | Estimated Work |
|----------|-------|-----|----------------|
| 🔴 **Critical** | Phase 1: Complete First Character | Nothing works without this | 30 minutes |
| 🔴 **Critical** | Phase 2: Create 2-3 Characters | Need variety to showcase system | 1 hour |
| 🟡 **Important** | Phase 3: Dynamic Spawning | Required for loaders | 1-2 hours |
| 🟡 **Important** | Phase 4: Selection UI + Registry | Foundation for loaders | 2-3 hours |
| 🟢 **Nice to Have** | Phase 5: Visual Differentiation | Polish | 1-4 hours |
| ⚪ **Future** | Character Loader System | Once above is done | 4-8 hours |

---

## Decision Time

**Which phase should we start with?**

**My recommendation**: 
1. **Phase 1** (30 min) - Complete `hero1.tres` with all stats
2. **Phase 2** (1 hour) - Create 2 more characters
3. **Quick test**: Manually place all 3 in World.tscn and verify they work differently

This gives you a solid foundation to build everything else on.

**Alternative**: If you want to prototype quickly, just do Phase 1 + 2, then jump straight to character loaders with the 3 characters as examples.
