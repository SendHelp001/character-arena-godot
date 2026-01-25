# Systems Breakdown & Implementation Matrix

Based on `DesignDocumentation.MD` and `ROADMAP.md`.

**Legend:**
*   🟢 **Easy**: Basic engine functionality or simple logic. (< 4 hours)
*   🟡 **Medium**: Requires custom systems or moderate scripting. (1-2 days)
*   🔴 **Hard**: Complex system interplay, math-heavy, or architectural challenges. (3-7 days)
*   🟣 **Very Hard**: Advanced networking, deep optimization, or risk of technical debt. (1+ weeks)

---

## 1. Core Foundation (The Skeleton)
*Essential systems required for the game to function at a basic level.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Game Manager** | Manages game state (Menu, Playing, Paused, GameOver) and global singletons. | 🟢 Easy | None |
| **Input Manager** | Centralized input handling (Keybindings, Context switching between UI/Game). | 🟢 Easy | Godot Input Map |
| **Race Data Structure** | ScriptableObjects/Resources defining Race stats (HP, Speed, Passives). | 🟢 Easy | None |
| **Vessel Controller (Base)** | Handling basic physics, collision, and state machine (Idle, Walk, Air). | 🟡 Medium | CharacterBody3D |
| **Camera System** | 3rd person camera with offset, smoothing, and "Dash Distortion" effects. | 🟡 Medium | Vessel Controller |
| **Scene Management** | Loading screens and transitions between Main Menu and Game Scenes. | 🟢 Easy | Game Manager |

---

## 2. Character & Mobility (The "Feel")
*The specific mechanics that define the *Deadlock* x *Risk of Rain* movement.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Momentum Physics** | Custom velocity handling for slides, dashes, and maintaining speed. | 🔴 Hard | Vessel Controller |
| **Race Specifics: Aerian** | Logic for Gliding, Fuel resource management, and Slow Fall. | 🟡 Medium | Vessel Controller |
| **Race Specifics: Jotunn** | Fall damage immunity logic and "Seismic Impact" AOE on landing. | 🟡 Medium | Vessel Controller |
| **Race Specifics: Spriggan** | Wall-climbing logic and surface normal detection. | 🔴 Hard | Physics Engine |
| **Gravity & Fall Damage** | Calculating fall height/velocity to apply Stagger, Stun, or Damage tiers. | 🟡 Medium | Momentum Physics |
| **Stamina/Heat System** | Resource management for sprinting/abilities (Heat for Automata). | 🟢 Easy | Vessel Controller |

---

## 3. Combat & Interaction (The Heart)
*Mechanics for fighting and interacting with the world.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Interaction System** | Raycast detection for "Press F" (Pickups, Doors, Levers). | 🟢 Easy | Vessel Controller |
| **Health & Damage ** | IDamageable interfaces, Health components, Death events. | 🟢 Easy | None |
| **Artifact System (Base)** | Architecture for Items as Abilities (Strategy Pattern for effects). | 🔴 Hard | Input Manager |
| **Projectile System** | Ballistics, hit detection, pooling for bullets/spells. | 🟡 Medium | Combat |
| **Melee System** | Hitbox activation, attack chaining/combos, parry windows. | 🔴 Hard | Animation |
| **Status Effects** | System to apply and tick DOTs (Burn) or CC (Stun, Slow, Root) over time. | 🟡 Medium | Vessel Controller |
| **Deflection Logic** | Timed parry mechanics to reflect projectiles. | 🔴 Hard | Projectile System |

---

## 4. Systems of "The Vault" (The Loop)
*The rules and flow of a single match.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Match Timer / Acts** | Logic handling the 4 Acts (time-based triggers for events). | 🟢 Easy | Game Manager |
| **Loot Spawner** | RNG logic for spawning Chests/Artifacts based on rarity tables. | 🟡 Medium | Artifact System |
| **Enemy AI: Grunts** | NavMeshAgent chasing, simple attacks. | 🟡 Medium | NavigationRegion3D |
| **Enemy AI: Bosses** | State machines for boss phases, special attacks, and aggro. | 🔴 Hard | Enemy AI |
| **Extraction Zone** | Area detection + Timer + UI feedback for leaving. | 🟢 Easy | Match Timer |
| **Binding Altar** | Logic for "Channeling" (hold to activate), triggering global alerts. | 🟡 Medium | Interaction System |
| **Cursed Artifacts** | Logic for distinct "Cursed" penalties (Map Reveal, etc.). | 🟡 Medium | Artifact System |

---

## 5. Procedural Generation & World (The World)
*Creating the play space.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Room Generation** | Grid-based or connector-based placement of pre-fab rooms. | 🔴 Hard | None |
| **Gravity Rails** | Spline-based movement paths connecting layers or rooms. | 🔴 Hard | Vessel Controller |
| **Verticality Logic** | Ensuring connections between "Layers" (Outer Map -> Hub). | 🟣 Very Hard | Room Generation |
| **Biome Variants** | Svapping environment assets/hazards based on Biome type. | 🟡 Medium | Room Generation |
| **Hazards** | Lava, Pits (Teleport/Damage triggers). | 🟢 Easy | Health System |

---

## 6. UI & Feedback (The Eyes)
*Visual communication to the player.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Player HUD** | Health, Stamina/Heat, Ammo, Ability Icons, CD Overlays. | 🟢 Easy | Player Stats |
| **Inventory UI** | Drag-and-drop slots, item tooltips, comparing stats. | 🟡 Medium | Artifact System |
| **Minimap / Map** | Top-down view, icon clamping (showing off-screen targets). | 🟡 Medium | UI |
| **Damage Numbers** | Floating text pooling and animation. | 🟢 Easy | Combat |
| **Bounty / Alert UI** | Dynamic markers for Prime Artifact carriers or Cursed players. | 🟡 Medium | Game State |
| **Crosshair Dynamics** | Hitmarkers, spread visualization, charging indicators. | 🟢 Easy | Combat |

---

## 7. Meta-Game & Persistence (The Soul)
*Long-term progression and economy.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Save/Load System** | Serializing JSON for Inventory, Unlocks, Currencies. | 🟡 Medium | None |
| **Hub World** | Passive zone for movement, vendors, and crafting. | 🟢 Easy | Scene Management |
| **Vendor Logic** | "The Archivist" - Trading items for currency. | 🟡 Medium | Inventory System |
| **Vessel Binds** | Logic for creating "Blueprints" from extracted items. | 🟡 Medium | Save/Load |
| **Loadout System** | Selecting Race + Starting Binds before a match. | 🟡 Medium | Inventory System |

---

## 8. Multiplayer / Networking (The Complexity)
*The most difficult layer, required for Phase 4.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **Lobby Management** | Host/Join, Steam ID or IP connection handling. | 🔴 Hard | Godot High-Level MP |
| **Movement Replication** | Predicting and interpolating player position/rotation. | 🟣 Very Hard | Vessel Controller |
| **State Sync** | Syncing HP, Anims, and Artifact usage across clients. | 🟣 Very Hard | All Systems |
| **Lag Compensation** | Rollback or server-side authority for hit detection. | 🟣 Very Hard | Combat |
| **Spawning Logic** | Syncing procedural map seeds so clients see the same world. | 🟡 Medium | ProcGen |

---

## 9. Visuals & Juice (The Skin)
*Aesthetics and feel.*

| System Name | Description | Difficulty | Dependencies |
| :--- | :--- | :--- | :--- |
| **VFX Manager** | Particle systems for abilities, hits, dashes. | 🟡 Medium | None |
| **Shake & Feedback** | Screen shake, controller rumble, FOV Lerps. | 🟢 Easy | Camera |
| **Material/Shader Ops** | "Neon" overlays, outline shaders for enemies/loot. | 🟡 Medium | Shaders |
| **Animation Rigging** | IK for feet placement, upper-body blending for aiming. | 🔴 Hard | Animation |
