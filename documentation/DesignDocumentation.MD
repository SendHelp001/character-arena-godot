# Project Codex: Artifact Arena

**Genre:** Looter / PvP / Extraction Arena

**Perspective:** Third-Person / Hero-Shooter Hybrid

**Inspirations:** * **Atlyss** — Dungeon crawling & loot-driven progression

* **Deadlock / Marvel Rivals** — Verticality, momentum-based mobility, and readable combat
* **Grand Piece Online** — Rarity tiers, boss drops, and awakening logic

---

## 1. Core Gameplay Loop — *The Vault Incursion*

1. **The Drop:** Teams deploy into procedurally generated dungeon biomes known as **The Vaults** (Outer Map).
2. **The Hunt (PvE):** Players fight AI creeps for **Essence** and **Mastery**. Defeat Biome Bosses to loot **Artifacts**, shaping builds mid-run.
3. **The Convergence:** Dungeon layers collapse, forcing surviving teams via **Gravity Rails** into the central, high-verticality **Hub Arena** for PvP combat.
4. **The Prime Siege:** The **Prime Artifact** activates in the Hub. Holding it grants massive power but marks the team as a global **Bounty** target visible on the HUD.
5. **Extraction:** Portals open on the map’s rim. Players must fight out of the center to "Bind" their loot to their account permanently.

---

## 2. Match Chronology (The Four Acts)

* **Act 1: Infiltration (0-7m):** Scavenging & Survival. Focus on powering **Vessel Binds** from Level 1 (Dormant) to Level 2.
* **Act 2: Escalation (7-15m):** Biome Bosses active. Hunt for Mythic Artifacts. Reach Level 3 (Restored).
* **Act 3: Convergence (15-22m):** Global Migration. World verticality (Lifts/Rails) activates. PvP team-fighting ramps up.
* **Act 4: The Siege (22-30m):** Prime Artifact Event. Extraction portals open. **Awakened Forms** unleashed.

---
### **3. The Vessel System (Race = Biological Foundation)**

*Characters are defined by their biological foundation, which dictates movement and physics. These traits bias playstyles but do not lock you into rigid roles.*

#### **Humans (The Adaptables)**

* **Passive:** Gain **+1 Tuning Socket** (3 total) for permanent customization.
* **Hook:** Ally-targeted Artifact use refunds a small amount of resource (Mana/Stamina/Heat).
* **Read:** Flexible / Tactical Support Bias.

#### **Automata (The Clockwork)**

* **Passive:** Use **Heat** instead of Mana. Higher base Defense.
* **Venting:** Venting Heat grants brief defensive resistance to nearby allies.
* **Read:** Tank / Defensive Support.

#### **Aerians (The Light-Footed)**

* **Passive:** **-20% Max HP**. Permanent Air Dash (Fuel-based) and Slow Fall.
* **Wake:** Allies passing through the dash wake gain a brief Move Speed boost.
* **Read:** DPS / Mobility Support.

#### **Jotunn (The Colossal)**

* **Passive:** **-25% Stun Duration**, **-20% Critical Damage Taken**. Massive knockback resistance.
* **Gravity Mastery:** **Immune to Fall Damage.**
* **High/Very High Fall:** Does not suffer a Stun/Stagger; instead, receives a **2s Slow** upon landing. Unlike other races, the Jotunn can still attack, block, and use Artifacts while slowed.
* **Seismic Impact:** Landing from High/Very High heights deals Area-of-Effect (AoE) damage and a minor knockback to nearby enemies.


* **Penalty:** **-15% Movement Speed**; large hitbox.
* **Read:** Frontline Anchor / High-Verticality Initiator.

#### **Spriggan (The Fleet-Footed)**

* **Passive:** Microscopic hitbox. Innate wall-climbing and zero fall damage.
* **Penalty:** **+15% Movement Speed**; **+20% Damage Taken** and high knockback vulnerability.
* **Read:** DPS / Harassment.

#### **Undead (The Deathbound)**

* **Passive:** **Deathbound State (3s):** Upon lethal damage, can act but cannot be healed.
* **Hook:** Killing an enemy during Deathbound restores partial HP.
* **Read:** DPS / Anti-Support Pressure.

#### **Draconid (The Scale-Blooded)**

* **Passive:** Choose an **Elemental Aspect** (Fire / Ice / Lightning) for bonus resistance/damage.
* **Read:** Tank / Elemental Bruiser.

#### **Beastman (The Wildblooded)**

* **Passive:** **+5% Movement Speed**. Heavy Armor penalties increased by **10%**.
* **Aspects:** Must choose **ONE** (Feline: Dodge, Canine: Execute, Ursine: HP, Avian: Team Glide, Lizard: Shadow Regen).
* **Read:** Emergent Flex.

---

## 4. Leveling & Progression

### **In-Match Progression (The Run)**

* **Artifact Mastery (Levels 1-3):** Earned by using the item. Unlocks sub-skills (M2) and faster frame-data.
* **Essence Infusion:** Spent mid-match to "Restore" Artifacts.
* **Level 1 (Dormant):** Starter state for Binds.
* **Level 3 (Restored):** Full Mythic power.
* **Level 4 (Awakened):** Requires **Player Essence (PvP)**. Grants 30s of "God Mode."



### **Account Progression (The Hub)**

* **Vessel Binds:** Blueprints of Mythic items. Allows you to spawn with a specific item (Dormant state) to skip RNG.
* **Tuning Sockets:** Permanent passive gems (e.g., *Essence Magnet* for +10% gain) slotted into your Race.
* **Archaic Marks:** Currency earned by "Burning" extracted loot with **The Archivist (NPC)** or trading with players.

---

## 5. Artifact System — *Items = Skills*

### **I. Primordial Artifacts (Ultimates)**

* **The Sun-Eater:** Solar flare dash. **Ultimate:** Gravity sun dealing burn damage.
* **The Hollow King:** Wall phasing. **Ultimate:** Shadow clones mimic weapon attacks.
* **The Verdant Heart:** Ally life-tethers. **Ultimate:** Arena floor becomes rooting jungle terrain.

### **II. Weapon Artifacts (M1 / M2)**

* **Arc-Caster:** Chain lightning / stun shock.
* **Heavy Cleaver:** Wide melee / parry-reset. Evolves from rusted slab to obsidian blade.
* **Twin Reapers:** Rapid slashes / blink strike.

---

## 6. Combat & Mobility (Deadlock Style)

### **Gravity & Impact Dynamics**

Gravity is a tactical obstacle; there is **no lethal fall damage**, but poor landing management is punished via momentum loss.

| Height Tier   | Damage        | Status Effect           | Recovery Options                                           |
| ------------- | ------------- | ----------------------- | ---------------------------------------------------------- |
| **Low-Mid**   | 0%            | None                    | Smooth transition into run/combat.                         |
| **High**      | 0%            | **Staggered** (1s)      | Cannot shoot/cast; holding **Crouch** converts to a Slide. |
| **Very High** | 10–15% Max HP | **Stun + Stagger** (2s) | Forced "Hard Landing" animation; leaves player wide open.  |

### **Melee vs. Range Balance**

* **Block (Hold M2):** Consumes Stamina to reduce frontal damage.
* **Deflection (Timed M2):** Nullifies a projectile and grants **Kinetic Momentum**.
* **Kinetic Momentum:** After 3 deflections, your next dash becomes a long-range **Lunge** to close the gap.

---

## 7. Visual Hierarchy & Economy

1. **VFX Overlays:** Gameplay effects use "Neon" glow shaders that render over all clothing.
2. **Silhouettes:** Cosmetics cannot alter the core skeletal shape of a Race.
3. **Bounty System:** Carrying rare loot increases your "Threat Level," making you a visible target for other teams (Headhunters).
4. **Trading Hub:** A social zone where players exchange "Bound" Artifacts and Tuning Sockets.

---

**Project Codex: Artifact Arena** *Power is found. Survival is earned. Builds are never final.*

---
## 8. The Extraction & Binding System

*To turn match-found loot into permanent account progression, players must navigate the "Binding" risk.*

* **Extraction Portals:** Open during Act 4 at the map’s periphery. Portals allow players to leave with **Archaic Marks**, **Scrap**, and **Consumables**.
* **The Binding Altar (Hub Center):** To convert a Mythic Artifact into a permanent **Vessel Bind** (Blueprint), it must be "Anchored" at the central Altar.
* **Channeling:** Binding takes 10 seconds of uninterrupted channeling.
* **Global Alert:** Activating the Altar alerts all surviving teams, making the "Binder" the primary target of the Hub.


* **The Risk of Loss:** Failing to extract results in the loss of all match-found Artifacts. Only **Vessel Binds** and **Tuning Sockets** equipped before the match are retained.

---

## 9. Weight & Armor System

*Equipment weight modifies base Race physics and gravity interactions.*

* **Armor Tiers:**
* **Light:** Increases **Air Control** (+20%) and reduces Stamina consumption for dashes.
* **Medium:** Balanced stats; no modifiers to Race physics.
* **Heavy:** Provides **Passive Poise** (prevents stagger from small-arms fire) but increases **Fall Velocity**.


* **Gravity Interaction:** Heavy Armor players reach "Very High" fall speeds 30% faster than Light Armor players, making "Impact Management" (Sliding) critical for heavy builds.

---

## 10. Biome-Locked Loot (The Vault Regions)

*The Vault is procedurally generated but always contains three distinct biomes with exclusive loot tables.*

| Biome                   | Environmental Hazard        | Grand Boss           | Exclusive Artifact Type                  |
| ----------------------- | --------------------------- | -------------------- | ---------------------------------------- |
| **The Sunken Labs**     | Deep Water (Slows movement) | *The Hydro-Colossus* | **Abyssal / Water** (Mobility & Stealth) |
| **The Overgrown Spire** | High-Verticality Vines      | *Spriggan Queen*     | **Verdant / Nature** (Healing & CC)      |
| **The Iron Forge**      | Lava / Extreme Heat         | *The Great Automata* | **Ignis / Kinetic** (Raw Damage & Heat)  |

---

## 11. Cursed Artifacts

*Forbidden power for players who embrace the "Glass Cannon" playstyle.*

* **Illegal Tier:** Cursed items provide stats that exceed Mythic limitations (e.g., +100% Lifesteal or Wall-Vision).
* **The Mark of the Accursed:**
* **No Binding:** Cursed items cannot be turned into Vessel Binds; they are destroyed upon extraction.
* **Permanent Reveal:** Carrying a Cursed Artifact reveals your exact position on the mini-map to all players in the Hub.
* **Extraction Penalty:** Portals take twice as long to activate for Cursed players.



---

## 12. Economy & The Archivist

*Post-match management of the "Binding" economy.*

* **The Archivist (Social Hub NPC):** Used to "Burn" unwanted Vessel Binds into **Archaic Marks**.
* **Marketplace:** Players can trade successfully extracted Vessel Binds and Tuning Sockets with others in the Social Hub.
* **Vessel Insurance:** Players can spend Archaic Marks to "Insure" a match-found item, allowing them to keep it even if they die, provided they reached at least Act 3.
