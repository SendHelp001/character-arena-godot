# moba-project-godot
 
Character Wars Arena

**Genre**: Co-op "Solo MMO" Looter Arena
**Inspirations**: *Atlyss*, *Marvel Rivals*, *Deadlock*

### Concept
Experience the depth of a "Solo MMO" like *Atlyss* but designed for cooperative play with friends. This is an artifact-driven looter where your build is defined by what you find.

### Key Mechanics
- **Artifact System**: Artifacts are not just stat sticks—they grant unique active abilities and modify your playstyle, featuring dynamic mechanics inspired by *Marvel Rivals* and *Deadlock*.
- **Arena Looter**: Fight through dynamic arenas, defeat bosses, and loot powerful artifacts to craft your ultimate build.

## Technical Overview

The project follows a **Feature-Based Architecture** to ensure modularity and scalability.

### Directory Structure (`src/`)
- **`core/`**: Global systems (Game Loop, Debug tools).
- **`features/`**: Self-contained game modules.
    - **`units/`**: Logic for all characters (Players, Enemies) and their components.
    - **`abilities/`**: Ability definitions and casting mechanics.
    - **`combat/`**: Combat systems, including Projectiles and Hitboxes.
- **`shared/`**: Shared data types and resources (e.g., `Stat`, `StatData`).
- **`ui/`**: User Interface logic and scenes.
- **`maps/`**: Level scenes (e.g., `World.tscn`).

### Core Systems
Under the hood, all characters (heroes, mobs, bosses) are defined via `StatData` resources, so stats, abilities, resistances, and loot drops are data-driven and easily extensible.
