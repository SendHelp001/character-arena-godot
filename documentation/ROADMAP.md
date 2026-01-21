# Roadmap: Artifact Arena (Deadlock/Extraction Hybrid)

## 📌 Vision
A **PvPvE Extraction Arena** where players (Vessels) raid procedural vaults, loot abilities (Artifacts) that define their class mid-run, and fight to extract via a high-stakes central arena.
**Core Feel:** *Deadlock* Movement + *Risk of Rain* Loot + *Tarkov* Extraction.

---

## 🚧 Phase 0: The "Feel" Foundation (Current Status)
**Goal:** Establish the "Deadlock" movement and combat baseline.
- [x] **Hero Controller**: Movement, Sprint, Jump, Crouch.
- [x] **Race System**: Human (Standard), Aerian (Glide), Jotunn (Heavy/No Fall Dmg).
- [x] **Camera System**: Deadlock-style offset, dynamic lag, dash distortion.
- [x] **Ability Foundation**: `Blink` and `FireWand` artifacts working.
- [x] **UI**: Dash Indicator, FPS, Debug Stats.

---

## 📅 Phase 1: The "Vault" Loop (Immediate Next Steps)
**Goal:** Create a playable single-player "Vertical Slice" of the extraction loop.
### 1.1 The Map & Hazards
- [ ] **Test Level Expansion**: Replace flat plane with a "Gym" containing:
    - **Verticality**: Ramps, Ledges (for Glide/Climb testing).
    - **Hazards**: Lava/Pit (Reset trigger).
- [ ] **Landing Mechanics**: Implement the "Impact/Stagger" system from Design Doc (Fall damage = Stamin/Momentum loss).

### 1.2 The Inventory & Looting
- [ ] **Interaction System**: "Press F to Pickup" (currently auto-pickup?).
- [ ] **Inventory UI**: Drag-and-drop or slot swapping for Artifacts.
- [ ] **Artifact Stacking**: Logic for duplicate artifacts (Level up vs Stack?).

### 1.3 The Extraction Mockup
- [ ] **Extraction Zone**: A visual zone that triggers "Win/Menu" after a timer.
- [ ] **Session Timer**: A simplified 5-minute timer to force extraction.

---

## ⚔️ Phase 2: Combat & Enemies
**Goal:** Give the player something to shoot.
### 2.1 Enemy AI (The Creeps)
- [ ] **Basic Melee Grunts**: NavMeshAgent chasing player.
- [ ] **Ranged Turrets**: Static enemies testing "Deflection/Block" mechanics.
- [ ] **Loot Drops**: Enemies dropping "Essence" or Artifacts.

### 2.2 Advanced Combat
- [ ] **Melee System**: Sword hitboxes, parry logic (referenced in finding `HeroController`).
- [ ] **Status Effects**: Burn, Slow, Stun implementation.

---

## 🏗️ Phase 3: The "Macro" Game (Structure)
**Goal:** Account persistence and progression.
### 3.1 The Hub
- [ ] **Main Menu**: Character Select (Race Select).
- [ ] **Loadout Screen**: Equip "Vessel Binds" (Starting Artifacts).
- [ ] **Persistence**: Save/Load system for unlocked Binds.

### 3.2 Procedural Generation (Sprawl)
- [ ] **Room Tiles**: Design 3-4 distinct rooms (Combat, Loot, Boss).
- [ ] **Generation Logic**: Connect rooms via "Gravity Rails" or corridors.

---

## 🌐 Phase 4: Networking (The "Arena")
**Goal:** Multiplayer synchronization.
- [ ] **Lobby System**: Host/Join.
- [ ] **Replication**: Sync Movement, Projectiles, and Artifact states.
- [ ] **PvP Damage**: Friendly Fire toggles/Team logic.

---

## 🛑 Current Blockers / Technical Debt
1.  **Weapon System**: Currently hardcoded (`WeaponMode.GUN`). Needs to be fully Artifact-driven.
2.  **Animation**: Player is a Capsule. Need a basic rig for "Cast," "Slash," "Run" visual feedback.
