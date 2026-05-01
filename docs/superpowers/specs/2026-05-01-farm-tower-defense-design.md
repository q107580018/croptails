# Farm Tower Defense Vertical Slice Design

## Goal

Build a playable Godot 4.6 vertical slice for Croptails: a farm-themed Warcraft-like tower defense with a TileMap-based map, fixed tower slots, 10 enemy waves, three tower roles, three enemy roles, win/lose states, and restart.

## Confirmed Scope

- Use Godot MCP first for visible scene creation and node placement where the tool supports it.
- Use Godot-native scene structure instead of generating the scene tree from gameplay scripts.
- Use a TileMap-based map with one single-entry snake path.
- Use fixed tower slots rather than free building.
- Include 10 waves in the first version.
- Include three tower types:
  - Arrow Tower: single-target damage.
  - Splash Tower: area damage.
  - Slow Tower: low damage with movement slow.
- Include three enemy types:
  - Normal Enemy: baseline health and speed.
  - Fast Enemy: lower health and higher speed.
  - Tank Enemy: higher health and lower speed.
- Include basic economy, lives, wave display, tower selection, victory, defeat, and restart.

Out of scope for the first version:

- Free tower placement.
- Path blocking.
- Hero units.
- Complex armor and damage type tables.
- Tower upgrade trees.
- Multiple maps.
- Save/load progression.

## Architecture

The first version will be scene-driven. `Main.tscn` is the entry point and owns the visible game layout. Gameplay scripts attach to scene nodes that are visible and adjustable in the Godot editor.

Primary scene nodes:

- `Main` (`Node2D`): root node for the level.
- `Map` (`TileMapLayer` or TileMap-compatible fallback if MCP cannot create a TileMapLayer directly): farm terrain, snake path, water, and decorative boundaries.
- `EnemyPath` (`Path2D`): fixed movement route from entrance to farm target.
- `TowerSlots` (`Node2D`): fixed build points placed near the path.
- `Towers` (`Node2D`): runtime parent for tower instances.
- `Enemies` (`Node2D`): runtime parent for enemy instances.
- `Projectiles` (`Node2D`): runtime parent for projectiles or impact effects.
- `GameStateMachine` (`Node`): state machine coordinating build, wave, victory, and defeat phases.
- `UI` (`CanvasLayer`): HUD for lives, coins, wave count, selected tower, start wave, and restart.

The implementation should keep visible structure in scenes and resources. Scripts should not create the whole map, tower slots, or UI hierarchy at runtime.

## State Machine

Use a small reusable state machine rather than scattered boolean flags.

States:

- `BuildPhase`: player can select tower slots, build towers, and start the next wave.
- `WavePhase`: enemies spawn and towers attack. Building can remain allowed only if it does not complicate UI; the default first version should allow building between waves only.
- `Victory`: entered after wave 10 is cleared and no enemies remain.
- `Defeat`: entered when lives reach zero.

State transitions:

- `BuildPhase -> WavePhase`: player starts the next wave.
- `WavePhase -> BuildPhase`: current wave is cleared and waves remain.
- `WavePhase -> Victory`: wave 10 is cleared.
- `WavePhase -> Defeat`: lives reach zero.
- `Victory/Defeat -> BuildPhase`: player restarts the level.

## Gameplay Data

Use Godot Resource files where practical for data that should be tuned in the editor:

- Tower stats: cost, range, fire rate, damage, splash radius, slow amount, slow duration.
- Enemy stats: health, speed, reward, life damage.
- Wave composition: enemy type, count, spawn interval.

If the first implementation can be kept simpler by defining constants in one script, that is acceptable only for data not exposed in the editor yet. The plan should prefer Resources for tower, enemy, and wave data.

## Combat Rules

Towers acquire targets from enemies in range. Default targeting is first enemy nearest the exit, because that is simple and predictable for tower defense.

Tower behavior:

- Arrow Tower deals direct damage to one target.
- Splash Tower deals direct damage to the target and reduced area damage around the impact.
- Slow Tower deals minor damage and applies a temporary speed multiplier to the target.

Enemy behavior:

- Enemies move along `EnemyPath`.
- When an enemy reaches the end, it is removed and lives decrease.
- When an enemy dies, it grants coins and is removed.
- Slow effects stack by refreshing the strongest active slow rather than multiplying repeatedly.

## UI

The HUD should be compact and functional:

- Lives.
- Coins.
- Current wave out of 10.
- Selected tower type.
- Start Wave button.
- Restart button shown or enabled on victory/defeat.
- A small status label for build prompts, victory, and defeat.

Tower slot interaction:

- Clicking an empty tower slot builds the currently selected tower if the player has enough coins.
- Clicking a filled tower slot does nothing in the first version, except optionally show its type.
- If coins are insufficient, the status label briefly reports that the tower cannot be built.

## Assets

Use existing assets under `assets/game`:

- Terrain and path visuals from `assets/game/tilesets`.
- Tower visuals use farm object sprites from `assets/game/objects/basic_tools_and_meterials.png` and `assets/game/objects/basic_grass_biom_things.png`, with a small colored range/role marker added in the tower scene to distinguish Arrow, Splash, and Slow towers.
- Enemy visuals use `assets/game/characters/basic_charakter_spritesheet.png` for Normal Enemy, `assets/game/characters/free_chicken_sprites.png` for Fast Enemy, and `assets/game/characters/free_cow_sprites.png` for Tank Enemy.

Do not edit `.import` files manually.

## Verification

Implementation is complete when:

- Godot opens the project without parse errors.
- `Main.tscn` is configured as the runnable main scene.
- Starting the project shows the TileMap farm map and fixed tower slots.
- Player can select and build all three tower types.
- Starting waves spawns enemies on the snake path.
- Towers attack and can kill enemies.
- Enemies reaching the end reduce lives.
- Coins increase when enemies die.
- The game reaches victory after clearing 10 waves.
- The game reaches defeat when lives hit zero.
- Restart returns the level to the initial state.

Verification commands:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Manual verification:

1. Run the project from Godot.
2. Build each tower type on different tower slots.
3. Start waves until at least wave 3 and confirm enemies move, towers attack, and coins/lives update.
4. Let enemies leak to verify defeat behavior.
5. Complete or fast-forward through wave 10 to verify victory behavior.
