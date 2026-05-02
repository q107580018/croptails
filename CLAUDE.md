# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
# Open in Godot editor
godot --editor --path .

# Run the game
godot --path .

# Headless load check (catches parse/import errors fast)
godot --headless --path . --quit
```

Godot 4.6 with Jolt Physics. Target: Mobile + Desktop, 1080×720 viewport stretch.
Main scene: `res://scenes/Main.tscn`.

## Architecture

**State machine** — `scripts/state/state_machine.gd` drives all game phases. States are child nodes of the StateMachine node in Main.tscn. Phases: `BuildPhase` → `WavePhase` → (`BuildPhase` | `DefeatPhase` | `VictoryPhase`). Each state extends `State` (enter/exit/update). The machine auto-discovers states from its children by name.

**`Main` (`scripts/game/main.gd`)** — the central god object. Owns lives, coins, wave index, spawning state. Wires signals from TowerSlots, HUD, and enemies. Handles tower building, upgrading, recycling, coin/life tracking, and wave spawning.

**Towers** — `scripts/game/tower.gd` extends `Area2D`. Range detection via physics overlap with enemy hitboxes. Four roles defined in `TowerConfig.Role`:
- `ARROW` — single target, fires projectile
- `MULTI_SHOT` — hits N closest targets with projectile + instant damage
- `SLOW` — hits N targets with damage + slow debuff (speed multiplier, duration)
- `MELEE_LINE` — rectangle-shaped melee hitbox in attack direction, multi-target

Towers auto-target the enemy with the shortest remaining path via `distance_to_goal()`.

**Enemies** — `scripts/game/enemy.gd` extends `Node2D`. Children of a `Path2D`. Move by incrementing `path_progress` each frame, sampling the path curve. `HealthBar` is a `ProgressBar` child. Track `dead` flag to prevent double-death signals.

**Projectiles** — `scripts/game/arrow_projectile.gd`. Spawned by towers, fly toward a target position then queue_free. Parented to a `Projectiles` node in the world.

**Data resources** — plain `Resource` subclasses with `@export` fields:
- `TowerConfig` — tower stats, role, textures, upgrade params
- `EnemyConfig` — health, speed, reward, life_damage, sprite info, optional alternate scene
- `WaveConfig` — array of `WaveEntry` + coin_bonus
- `WaveEntry` — enemy config ref, count, spawn_interval, health_multiplier

**UI** — `scripts/ui/hud.gd` is the sole UI controller. Builds the tower action menu (upgrade/recycle popup) programmatically — it has no `.tscn` of its own. `BuildMenu` is a separate scene (`scenes/ui/BuildMenu.tscn`) instantiated by the HUD.

## Signal flow

```
TowerSlot.build_requested  →  Main  →  HUD.show_build_menu()
TowerSlot.tower_clicked    →  Main  →  HUD.show_tower_action_menu()
HUD.build_selected         →  Main  →  instantiate tower, deduct coins
HUD.tower_upgrade          →  Main  →  tower.upgrade(), deduct coins
HUD.tower_recycle          →  Main  →  refund, queue_free tower
Enemy.died                 →  Main  →  add reward, check wave end
Enemy.reached_goal         →  Main  →  lose life, check defeat/wave end
Main.stats_changed         →  HUD  →  update labels
Main.status_changed        →  HUD  →  update status text
```

## Key conventions

- Tabs for indentation. `snake_case` for functions/variables, `PascalCase` for class_name, `UPPER_CASE` for enums.
- `@export` for designer-tuned values, `@onready` for node references.
- `$NodePath` shorthand for child node access — keep scene node names stable.
- Chinese UI strings throughout (game is Chinese-localized).
- `.uid` and `.import` files are Godot-managed — don't regenerate or delete them.
- New data (towers, enemies, waves) goes into `.tres` files under `resources/`.
- Commit style: Conventional Commits (`feat:`, `fix:`).
