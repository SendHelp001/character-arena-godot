# Roadmap: Co-op Artifact Arena

## Vision
A "Solo MMO" experience designed for cooperative play. Players enter dynamic arenas, fight waves of enemies, and loot **Artifacts** which define their abilities and playstyle (Marvel Rivals / Deadlock style mechanics).

## Current State Analysis
- ✅ **Infrastructure**: Feature-based folder structure established.
- ✅ **Core Unit**: Basic movement and combat exist.
- ❌ **Missing Core Loop**: No artifact system, no looting, no real arena waves.
- ❌ **Old Path**: Previous roadmap focused on "Character Selection". **New Path**: Focus on "Artifact Loadouts".

---

## Development Phases

### Phase 1: The Artifact System (The "Soul") ⭐ **START HERE**
**Goal**: Shift from "Class-based" to "Item-based" progression.
1. **Artifact Resource**: Create `ArtifactData` (icon, stats, attached ability).
2. **Inventory Manager**: System to pick up, hold, and equip artifacts.
3. **Ability Injection**: When an artifact is equipped, the player GAINS that ability.
    - *Example*: Equipping "Gale Boots" grants a Dash ability.
    - *Example*: Equipping "Void Staff" grants a Black Hole projectile.

### Phase 2: The Arena Loop (The "Game")
**Goal**: Create the core gameplay loop (Enter -> Fight -> Loot -> Extract/Win).
1. **Wave Spawner**: Dynamic enemy spawning logic (increasing difficulty).
2. **Loot Drops**: Enemies drop Artifacts on death.
3. **Win Condition**: Defeat the Boss or Survive X Waves.

### Phase 3: Co-op Foundation
**Goal**: Ensure mechanics work with multiple players.
1. **Multiplayer Spawning**: Spawn multiple players in the arena.
2. **Sync**: Ensure projectiles and abilities sync across clients (Godot High-Level Multiplayer).

### Phase 4: Content Expansion
1. **Bosses**: Unique mechanical bosses.
2. **Biomes**: Different visuals for the arena.
3. **Artifact Variety**: Create 10+ distinct artifacts to test build variety.

---

## Detailed Tasks (Phase 1)
- [ ] Create `Artifact.gd` (inherits Resource).
- [ ] Create `InventoryComponent.gd` for Units.
- [ ] Modify `AbilityCasting` to read from Inventory instead of hardcoded stats.
- [ ] Create 3 test artifacts:
    - **Movement Artifact**: Blink / Dash.
    - **Offensive Artifact**: Fireball / Snipe.
    - **Utility Artifact**: Shield / Heal.

## Summary: Priorities
| Priority | Phase | Why |
|----------|-------|-----|
| 🔴 **Critical** | Phase 1: Artifact System | This is the core mechanic of the new genre. |
| � **High** | Phase 2: Arena Loop | Need a game to play with the artifacts. |
| 🟡 **Medium** | Phase 3: Co-op Sync | "With friends" is key, but mechanics come first. |
| 🟢 **Low** | Phase 4: Content | Content comes after systems work. |
