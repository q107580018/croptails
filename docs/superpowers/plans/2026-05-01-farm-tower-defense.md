# Farm Tower Defense Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable Godot 4.6 farm-themed tower defense vertical slice with a TileMap-based snake path, fixed tower slots, three tower types, three enemy types, 10 waves, win/lose states, and restart.

**Architecture:** The game is scene-driven. Godot MCP creates and saves visible scene nodes first; scripts attach behavior to those nodes and use Resources for tunable tower, enemy, and wave data. A small node-based state machine owns Build, Wave, Victory, and Defeat phase transitions.

**Tech Stack:** Godot 4.6.2, GDScript, `.tscn` scenes, `.tres` Resources, Godot MCP scene/node tools, `TileMapLayer`, `Path2D`, `Area2D`, `CanvasLayer`.

---

## File Structure

- Create `scripts/data/tower_config.gd`: typed `Resource` for tower stats and role.
- Create `scripts/data/enemy_config.gd`: typed `Resource` for enemy stats.
- Create `scripts/data/wave_entry.gd`: typed `Resource` for a single enemy group in a wave.
- Create `scripts/data/wave_config.gd`: typed `Resource` for one wave.
- Create `resources/towers/arrow_tower.tres`: Arrow Tower config.
- Create `resources/towers/splash_tower.tres`: Splash Tower config.
- Create `resources/towers/slow_tower.tres`: Slow Tower config.
- Create `resources/enemies/normal_enemy.tres`: Normal Enemy config.
- Create `resources/enemies/fast_enemy.tres`: Fast Enemy config.
- Create `resources/enemies/tank_enemy.tres`: Tank Enemy config.
- Create `resources/waves/wave_01.tres` through `resources/waves/wave_10.tres`: 10 wave configs.
- Create `scripts/state/state.gd`: base state class.
- Create `scripts/state/state_machine.gd`: generic child-state manager.
- Create `scripts/state/build_phase.gd`: build phase behavior.
- Create `scripts/state/wave_phase.gd`: wave phase behavior.
- Create `scripts/state/victory_phase.gd`: victory behavior.
- Create `scripts/state/defeat_phase.gd`: defeat behavior.
- Create `scripts/game/enemy.gd`: enemy movement, health, reward, leaks, slow effect.
- Create `scripts/game/tower.gd`: targeting and attack behavior for all tower roles.
- Create `scripts/game/tower_slot.gd`: fixed build point interaction.
- Create `scripts/game/main.gd`: level orchestration, economy, wave spawning, restart.
- Create `scripts/ui/hud.gd`: HUD signal wiring and display updates.
- Create `scenes/Enemy.tscn`: reusable enemy scene.
- Create `scenes/Tower.tscn`: reusable tower scene.
- Create `scenes/TowerSlot.tscn`: reusable fixed slot scene.
- Create `scenes/Main.tscn`: main playable level.
- Modify `project.godot`: set `application/run/main_scene="res://scenes/Main.tscn"`.

## Task 1: Data Resource Classes

**Files:**
- Create: `scripts/data/tower_config.gd`
- Create: `scripts/data/enemy_config.gd`
- Create: `scripts/data/wave_entry.gd`
- Create: `scripts/data/wave_config.gd`

- [ ] **Step 1: Create data directories**

Run:

```bash
mkdir -p scripts/data resources/towers resources/enemies resources/waves
```

Expected: command exits with code 0.

- [ ] **Step 2: Add `TowerConfig`**

Create `scripts/data/tower_config.gd`:

```gdscript
class_name TowerConfig
extends Resource

enum Role { ARROW, SPLASH, SLOW }

@export var display_name: String = "Tower"
@export var role: Role = Role.ARROW
@export var cost: int = 50
@export var range: float = 96.0
@export var fire_rate: float = 1.0
@export var damage: int = 8
@export var splash_radius: float = 0.0
@export_range(0.1, 1.0) var slow_multiplier: float = 1.0
@export var slow_duration: float = 0.0
@export var marker_color: Color = Color.WHITE
```

- [ ] **Step 3: Add `EnemyConfig`**

Create `scripts/data/enemy_config.gd`:

```gdscript
class_name EnemyConfig
extends Resource

@export var display_name: String = "Enemy"
@export var max_health: int = 30
@export var speed: float = 55.0
@export var reward: int = 8
@export var life_damage: int = 1
@export var sprite_texture: Texture2D
@export var sprite_region: Rect2 = Rect2(0, 0, 16, 16)
@export var sprite_scale: Vector2 = Vector2.ONE
@export var tint: Color = Color.WHITE
```

- [ ] **Step 4: Add wave Resources**

Create `scripts/data/wave_entry.gd`:

```gdscript
class_name WaveEntry
extends Resource

@export var enemy: EnemyConfig
@export var count: int = 5
@export var spawn_interval: float = 0.7
```

Create `scripts/data/wave_config.gd`:

```gdscript
class_name WaveConfig
extends Resource

@export var wave_number: int = 1
@export var entries: Array[WaveEntry] = []
@export var coin_bonus: int = 10
```

- [ ] **Step 5: Verify data scripts parse**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and no GDScript parse errors for `scripts/data`.

- [ ] **Step 6: Commit**

```bash
git add scripts/data
git commit -m "feat: add tower defense data resources"
```

## Task 2: Tower, Enemy, And Wave Resource Files

**Files:**
- Create: `resources/towers/arrow_tower.tres`
- Create: `resources/towers/splash_tower.tres`
- Create: `resources/towers/slow_tower.tres`
- Create: `resources/enemies/normal_enemy.tres`
- Create: `resources/enemies/fast_enemy.tres`
- Create: `resources/enemies/tank_enemy.tres`
- Create: `resources/waves/wave_01.tres` through `resources/waves/wave_10.tres`

- [ ] **Step 1: Create tower configs**

Use Godot editor or text Resources. The three `.tres` files must use these values:

```text
arrow_tower: display_name="Arrow Tower", role=ARROW, cost=50, range=110, fire_rate=1.2, damage=12, splash_radius=0, slow_multiplier=1, slow_duration=0, marker_color=#d9c46a
splash_tower: display_name="Splash Tower", role=SPLASH, cost=80, range=95, fire_rate=0.75, damage=16, splash_radius=42, slow_multiplier=1, slow_duration=0, marker_color=#d96b3b
slow_tower: display_name="Slow Tower", role=SLOW, cost=65, range=100, fire_rate=0.9, damage=4, splash_radius=0, slow_multiplier=0.55, slow_duration=1.8, marker_color=#6ab7d9
```

- [ ] **Step 2: Create enemy configs**

The three `.tres` files must use these values and textures:

```text
normal_enemy: display_name="Normal Enemy", max_health=36, speed=58, reward=8, life_damage=1, sprite_texture=res://assets/game/characters/basic_charakter_spritesheet.png, sprite_region=(0,0,16,16), sprite_scale=(1,1), tint=#ffffff
fast_enemy: display_name="Fast Enemy", max_health=24, speed=86, reward=7, life_damage=1, sprite_texture=res://assets/game/characters/free_chicken_sprites.png, sprite_region=(0,0,16,16), sprite_scale=(1,1), tint=#ffffff
tank_enemy: display_name="Tank Enemy", max_health=90, speed=38, reward=14, life_damage=2, sprite_texture=res://assets/game/characters/free_cow_sprites.png, sprite_region=(0,0,16,16), sprite_scale=(1,1), tint=#ffffff
```

- [ ] **Step 3: Create 10 wave configs**

Create wave files with these compositions:

```text
wave_01: Normal x6 interval 0.85 bonus 8
wave_02: Normal x9 interval 0.75 bonus 10
wave_03: Fast x7 interval 0.65 bonus 10
wave_04: Normal x8 interval 0.65, Fast x5 interval 0.6 bonus 12
wave_05: Tank x4 interval 1.0, Normal x6 interval 0.65 bonus 14
wave_06: Fast x12 interval 0.5 bonus 14
wave_07: Tank x5 interval 0.85, Fast x8 interval 0.55 bonus 16
wave_08: Normal x14 interval 0.45, Tank x4 interval 0.75 bonus 18
wave_09: Fast x14 interval 0.45, Tank x6 interval 0.7 bonus 20
wave_10: Normal x12 interval 0.4, Fast x12 interval 0.4, Tank x8 interval 0.65 bonus 30
```

- [ ] **Step 4: Verify resource loading**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and no resource load errors.

- [ ] **Step 5: Commit**

```bash
git add resources
git commit -m "feat: add tower defense tuning resources"
```

## Task 3: State Machine Scripts

**Files:**
- Create: `scripts/state/state.gd`
- Create: `scripts/state/state_machine.gd`
- Create: `scripts/state/build_phase.gd`
- Create: `scripts/state/wave_phase.gd`
- Create: `scripts/state/victory_phase.gd`
- Create: `scripts/state/defeat_phase.gd`

- [ ] **Step 1: Create state directory**

Run:

```bash
mkdir -p scripts/state
```

Expected: command exits with code 0.

- [ ] **Step 2: Add base state**

Create `scripts/state/state.gd`:

```gdscript
class_name State
extends Node

var state_machine: StateMachine
var game: Main

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass
```

- [ ] **Step 3: Add state machine**

Create `scripts/state/state_machine.gd`:

```gdscript
class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state_name: StringName = &"BuildPhase"

var current_state: State
var states: Dictionary[StringName, State] = {}

func setup(game_node: Main) -> void:
	for child: Node in get_children():
		if child is State:
			var state := child as State
			states[state.name] = state
			state.state_machine = self
			state.game = game_node
			state.set_process(false)
	if states.has(initial_state_name):
		current_state = states[initial_state_name]
		current_state.set_process(true)
		current_state.enter()

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("State '%s' not found" % state_name)
		return
	var previous := current_state
	if current_state:
		current_state.exit()
		current_state.set_process(false)
	current_state = states[state_name]
	current_state.set_process(true)
	current_state.enter(msg)
	if previous:
		state_changed.emit(previous.name, current_state.name)
```

- [ ] **Step 4: Add concrete states**

Create `scripts/state/build_phase.gd`:

```gdscript
class_name BuildPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(true)
	game.set_status("Build towers, then start the next wave.")
	game.set_start_wave_enabled(game.has_more_waves())
```

Create `scripts/state/wave_phase.gd`:

```gdscript
class_name WavePhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("Wave in progress.")
	game.spawn_current_wave()
```

Create `scripts/state/victory_phase.gd`:

```gdscript
class_name VictoryPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("Victory! The farm is safe.")
	game.show_restart(true)
```

Create `scripts/state/defeat_phase.gd`:

```gdscript
class_name DefeatPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("Defeat. The farm was overrun.")
	game.show_restart(true)
```

- [ ] **Step 5: Verify state scripts parse**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and no state script parse errors. If `Main` is unresolved before `main.gd` exists, temporarily change `var game: Main` and `func setup(game_node: Main)` to untyped `Node`, then restore the typed references in Task 7 after creating `main.gd`.

- [ ] **Step 6: Commit**

```bash
git add scripts/state
git commit -m "feat: add game phase state machine"
```

## Task 4: Enemy Scene And Script

**Files:**
- Create: `scripts/game/enemy.gd`
- Create: `scenes/Enemy.tscn`

- [ ] **Step 1: Create game script directory**

Run:

```bash
mkdir -p scripts/game scenes
```

Expected: command exits with code 0.

- [ ] **Step 2: Add enemy script**

Create `scripts/game/enemy.gd`:

```gdscript
class_name Enemy
extends PathFollow2D

signal died(enemy: Enemy, reward: int)
signal reached_goal(enemy: Enemy, life_damage: int)

@export var config: EnemyConfig

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int = 1
var base_speed: float = 50.0
var slow_multiplier: float = 1.0
var slow_remaining: float = 0.0
var escaped: bool = false

func _ready() -> void:
	if config:
		apply_config(config)

func _process(delta: float) -> void:
	if slow_remaining > 0.0:
		slow_remaining = maxf(slow_remaining - delta, 0.0)
		if slow_remaining == 0.0:
			slow_multiplier = 1.0
	progress += base_speed * slow_multiplier * delta
	if progress_ratio >= 1.0 and not escaped:
		escaped = true
		reached_goal.emit(self, config.life_damage if config else 1)
		queue_free()

func apply_config(new_config: EnemyConfig) -> void:
	config = new_config
	health = config.max_health
	base_speed = config.speed
	if is_node_ready():
		sprite.texture = config.sprite_texture
		sprite.region_enabled = true
		sprite.region_rect = config.sprite_region
		sprite.scale = config.sprite_scale
		sprite.modulate = config.tint
		health_bar.max_value = config.max_health
		health_bar.value = health

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	health_bar.value = health
	if health <= 0:
		died.emit(self, config.reward if config else 0)
		queue_free()

func apply_slow(multiplier: float, duration: float) -> void:
	if multiplier < slow_multiplier or slow_remaining <= 0.0:
		slow_multiplier = multiplier
	slow_remaining = maxf(slow_remaining, duration)

func distance_to_goal() -> float:
	return 1.0 - progress_ratio
```

- [ ] **Step 3: Create enemy scene with Godot MCP**

Use Godot MCP:

```text
create_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/Enemy.tscn", rootNodeType="PathFollow2D")
add_node(scenePath="scenes/Enemy.tscn", parentNodePath="root", nodeType="Sprite2D", nodeName="Sprite2D")
add_node(scenePath="scenes/Enemy.tscn", parentNodePath="root", nodeType="ProgressBar", nodeName="HealthBar", properties={"position":{"x":-12,"y":-22},"size":{"x":24,"y":4},"max_value":1,"value":1,"show_percentage":false})
save_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/Enemy.tscn")
```

Then attach `res://scripts/game/enemy.gd` to the root node in the scene file or editor.

- [ ] **Step 4: Verify enemy scene opens**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and no missing script or node errors.

- [ ] **Step 5: Commit**

```bash
git add scripts/game/enemy.gd scenes/Enemy.tscn
git commit -m "feat: add enemy path follower"
```

## Task 5: Tower And Tower Slot Scenes

**Files:**
- Create: `scripts/game/tower.gd`
- Create: `scripts/game/tower_slot.gd`
- Create: `scenes/Tower.tscn`
- Create: `scenes/TowerSlot.tscn`

- [ ] **Step 1: Add tower script**

Create `scripts/game/tower.gd`:

```gdscript
class_name Tower
extends Area2D

@export var config: TowerConfig

@onready var sprite: Sprite2D = $Sprite2D
@onready var marker: ColorRect = $Marker
@onready var range_shape: CollisionShape2D = $RangeShape

var cooldown: float = 0.0

func _ready() -> void:
	if config:
		apply_config(config)

func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0 or config == null:
		return
	var target := _find_target()
	if target:
		_attack(target)
		cooldown = 1.0 / config.fire_rate

func apply_config(new_config: TowerConfig) -> void:
	config = new_config
	if is_node_ready():
		marker.color = config.marker_color
		var circle := CircleShape2D.new()
		circle.radius = config.range
		range_shape.shape = circle

func _find_target() -> Enemy:
	var best: Enemy
	var best_distance := INF
	for body: Node2D in get_overlapping_areas():
		if body is Enemy:
			var enemy := body as Enemy
			var distance := enemy.distance_to_goal()
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best

func _attack(target: Enemy) -> void:
	target.take_damage(config.damage)
	match config.role:
		TowerConfig.Role.SPLASH:
			_apply_splash(target.global_position)
		TowerConfig.Role.SLOW:
			target.apply_slow(config.slow_multiplier, config.slow_duration)
		_:
			pass

func _apply_splash(center: Vector2) -> void:
	if config.splash_radius <= 0.0:
		return
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy:
			var enemy := node as Enemy
			if enemy.global_position.distance_to(center) <= config.splash_radius:
				enemy.take_damage(maxi(1, int(config.damage * 0.5)))
```

- [ ] **Step 2: Add tower slot script**

Create `scripts/game/tower_slot.gd`:

```gdscript
class_name TowerSlot
extends Area2D

signal build_requested(slot: TowerSlot)

@onready var marker: ColorRect = $Marker

var occupied: bool = false
var building_enabled: bool = true

func _ready() -> void:
	input_event.connect(_on_input_event)

func set_enabled(enabled: bool) -> void:
	building_enabled = enabled
	modulate = Color.WHITE if enabled else Color(0.55, 0.55, 0.55)

func mark_occupied() -> void:
	occupied = true
	marker.color = Color(0.25, 0.25, 0.25, 0.85)

func reset_slot() -> void:
	occupied = false
	marker.color = Color(0.2, 0.7, 0.2, 0.65)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not building_enabled or occupied:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		build_requested.emit(self)
```

- [ ] **Step 3: Create tower scene with Godot MCP**

Use Godot MCP:

```text
create_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/Tower.tscn", rootNodeType="Area2D")
add_node(scenePath="scenes/Tower.tscn", parentNodePath="root", nodeType="Sprite2D", nodeName="Sprite2D")
add_node(scenePath="scenes/Tower.tscn", parentNodePath="root", nodeType="ColorRect", nodeName="Marker", properties={"position":{"x":-8,"y":-24},"size":{"x":16,"y":5}})
add_node(scenePath="scenes/Tower.tscn", parentNodePath="root", nodeType="CollisionShape2D", nodeName="RangeShape")
save_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/Tower.tscn")
```

Attach `res://scripts/game/tower.gd` to the root node. Configure the root collision layer/mask so it can detect enemies.

- [ ] **Step 4: Create tower slot scene with Godot MCP**

Use Godot MCP:

```text
create_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/TowerSlot.tscn", rootNodeType="Area2D")
add_node(scenePath="scenes/TowerSlot.tscn", parentNodePath="root", nodeType="ColorRect", nodeName="Marker", properties={"position":{"x":-12,"y":-12},"size":{"x":24,"y":24},"color":{"r":0.2,"g":0.7,"b":0.2,"a":0.65}})
add_node(scenePath="scenes/TowerSlot.tscn", parentNodePath="root", nodeType="CollisionShape2D", nodeName="CollisionShape2D")
save_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/TowerSlot.tscn")
```

Attach `res://scripts/game/tower_slot.gd` to the root node and set the collision shape to a `RectangleShape2D` of size `(28, 28)`.

- [ ] **Step 5: Verify tower scenes**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and no missing node errors for `Sprite2D`, `Marker`, or collision shapes.

- [ ] **Step 6: Commit**

```bash
git add scripts/game/tower.gd scripts/game/tower_slot.gd scenes/Tower.tscn scenes/TowerSlot.tscn
git commit -m "feat: add tower and tower slot scenes"
```

## Task 6: Main Scene Node Skeleton With Godot MCP

**Files:**
- Create: `scenes/Main.tscn`

- [ ] **Step 1: Create main scene**

Use Godot MCP:

```text
create_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/Main.tscn", rootNodeType="Node2D")
```

Expected: `scenes/Main.tscn` exists with a `Node2D` root.

- [ ] **Step 2: Add visible node skeleton**

Use Godot MCP to add these nodes:

```text
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="TileMapLayer", nodeName="Map")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="Path2D", nodeName="EnemyPath")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="Node2D", nodeName="TowerSlots")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="Node2D", nodeName="Towers")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="Node2D", nodeName="Enemies")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="Node2D", nodeName="Projectiles")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="Node", nodeName="GameStateMachine")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root", nodeType="CanvasLayer", nodeName="UI")
```

If MCP rejects `TileMapLayer`, use `TileMap` for the node name `Map` and record that fallback in the task commit message.

- [ ] **Step 3: Add state children**

Use Godot MCP:

```text
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/GameStateMachine", nodeType="Node", nodeName="BuildPhase")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/GameStateMachine", nodeType="Node", nodeName="WavePhase")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/GameStateMachine", nodeType="Node", nodeName="VictoryPhase")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/GameStateMachine", nodeType="Node", nodeName="DefeatPhase")
```

Attach `state_machine.gd` to `GameStateMachine`, and attach each concrete state script to its matching child.

- [ ] **Step 4: Add UI skeleton**

Use Godot MCP:

```text
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI", nodeType="Control", nodeName="Hud")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud", nodeType="HBoxContainer", nodeName="TopBar")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud/TopBar", nodeType="Label", nodeName="LivesLabel")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud/TopBar", nodeType="Label", nodeName="CoinsLabel")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud/TopBar", nodeType="Label", nodeName="WaveLabel")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud", nodeType="HBoxContainer", nodeName="TowerButtons")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud/TowerButtons", nodeType="Button", nodeName="ArrowButton")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud/TowerButtons", nodeType="Button", nodeName="SplashButton")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud/TowerButtons", nodeType="Button", nodeName="SlowButton")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud", nodeType="Button", nodeName="StartWaveButton")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud", nodeType="Button", nodeName="RestartButton")
add_node(scenePath="scenes/Main.tscn", parentNodePath="root/UI/Hud", nodeType="Label", nodeName="StatusLabel")
```

- [ ] **Step 5: Save scene**

Use Godot MCP:

```text
save_scene(projectPath="/Users/qiuwen/Documents/godot_game/croptails", scenePath="scenes/Main.tscn")
```

- [ ] **Step 6: Verify scene exists**

Run:

```bash
rg -n "Map|EnemyPath|TowerSlots|GameStateMachine|Hud" scenes/Main.tscn
```

Expected: all node names appear in `scenes/Main.tscn`.

- [ ] **Step 7: Commit**

```bash
git add scenes/Main.tscn
git commit -m "feat: add main tower defense scene skeleton"
```

## Task 7: Main Game Orchestration

**Files:**
- Create: `scripts/game/main.gd`
- Modify: `scenes/Main.tscn`
- Modify: `project.godot`

- [ ] **Step 1: Add main game script**

Create `scripts/game/main.gd`:

```gdscript
class_name Main
extends Node2D

signal stats_changed(lives: int, coins: int, wave: int, max_waves: int)
signal status_changed(text: String)

@export var tower_scene: PackedScene = preload("res://scenes/Tower.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@export var tower_configs: Array[TowerConfig] = [
	preload("res://resources/towers/arrow_tower.tres"),
	preload("res://resources/towers/splash_tower.tres"),
	preload("res://resources/towers/slow_tower.tres"),
]
@export var waves: Array[WaveConfig] = [
	preload("res://resources/waves/wave_01.tres"),
	preload("res://resources/waves/wave_02.tres"),
	preload("res://resources/waves/wave_03.tres"),
	preload("res://resources/waves/wave_04.tres"),
	preload("res://resources/waves/wave_05.tres"),
	preload("res://resources/waves/wave_06.tres"),
	preload("res://resources/waves/wave_07.tres"),
	preload("res://resources/waves/wave_08.tres"),
	preload("res://resources/waves/wave_09.tres"),
	preload("res://resources/waves/wave_10.tres"),
]

@onready var enemy_path: Path2D = $EnemyPath
@onready var tower_slots: Node2D = $TowerSlots
@onready var towers: Node2D = $Towers
@onready var enemies: Node2D = $Enemies
@onready var state_machine: StateMachine = $GameStateMachine
@onready var hud: Hud = $UI/Hud

var lives: int = 20
var coins: int = 180
var current_wave_index: int = 0
var selected_tower_index: int = 0
var spawning: bool = false

func _ready() -> void:
	hud.setup(self)
	for slot_node: Node in tower_slots.get_children():
		if slot_node is TowerSlot:
			var slot := slot_node as TowerSlot
			slot.build_requested.connect(_on_slot_build_requested)
	state_machine.setup(self)
	_emit_stats()
	show_restart(false)

func has_more_waves() -> bool:
	return current_wave_index < waves.size()

func select_tower(index: int) -> void:
	selected_tower_index = clampi(index, 0, tower_configs.size() - 1)
	set_status("Selected %s." % tower_configs[selected_tower_index].display_name)

func start_wave() -> void:
	if has_more_waves():
		state_machine.transition_to(&"WavePhase")

func spawn_current_wave() -> void:
	if spawning or not has_more_waves():
		return
	spawning = true
	var wave := waves[current_wave_index]
	current_wave_index += 1
	_emit_stats()
	await _spawn_wave_entries(wave)
	spawning = false
	await get_tree().create_timer(0.3).timeout
	_check_wave_end()

func set_building_enabled(enabled: bool) -> void:
	for slot_node: Node in tower_slots.get_children():
		if slot_node is TowerSlot:
			(slot_node as TowerSlot).set_enabled(enabled)

func set_start_wave_enabled(enabled: bool) -> void:
	hud.set_start_wave_enabled(enabled)

func set_status(text: String) -> void:
	status_changed.emit(text)

func show_restart(visible: bool) -> void:
	hud.show_restart(visible)

func restart() -> void:
	get_tree().reload_current_scene()

func _spawn_wave_entries(wave: WaveConfig) -> void:
	for entry: WaveEntry in wave.entries:
		for i: int in entry.count:
			_spawn_enemy(entry.enemy)
			await get_tree().create_timer(entry.spawn_interval).timeout

func _spawn_enemy(config: EnemyConfig) -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.config = config
	enemy.add_to_group("enemies")
	enemy.died.connect(_on_enemy_died)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	enemy_path.add_child(enemy)

func _on_slot_build_requested(slot: TowerSlot) -> void:
	var config := tower_configs[selected_tower_index]
	if coins < config.cost:
		set_status("Not enough coins for %s." % config.display_name)
		return
	coins -= config.cost
	var tower := tower_scene.instantiate() as Tower
	tower.config = config
	tower.global_position = slot.global_position
	towers.add_child(tower)
	slot.mark_occupied()
	_emit_stats()

func _on_enemy_died(_enemy: Enemy, reward: int) -> void:
	coins += reward
	_emit_stats()
	_check_wave_end.call_deferred()

func _on_enemy_reached_goal(_enemy: Enemy, life_damage: int) -> void:
	lives = max(lives - life_damage, 0)
	_emit_stats()
	if lives <= 0:
		state_machine.transition_to(&"DefeatPhase")
	else:
		_check_wave_end.call_deferred()

func _check_wave_end() -> void:
	if spawning or enemies.get_child_count() > 0 or enemy_path.get_child_count() > 0:
		return
	if lives <= 0:
		state_machine.transition_to(&"DefeatPhase")
	elif not has_more_waves():
		state_machine.transition_to(&"VictoryPhase")
	else:
		state_machine.transition_to(&"BuildPhase")

func _emit_stats() -> void:
	stats_changed.emit(lives, coins, current_wave_index, waves.size())
```

- [ ] **Step 2: Attach main script to scene**

Attach `res://scripts/game/main.gd` to the root node of `scenes/Main.tscn`.

- [ ] **Step 3: Set main scene**

Modify `project.godot` under `[application]`:

```ini
run/main_scene="res://scenes/Main.tscn"
```

- [ ] **Step 4: Verify parse**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0. If `Hud` is unresolved before Task 8, temporarily type `@onready var hud: Node = $UI/Hud`, then restore `Hud` after Task 8.

- [ ] **Step 5: Commit**

```bash
git add scripts/game/main.gd scenes/Main.tscn project.godot
git commit -m "feat: add tower defense game orchestration"
```

## Task 8: HUD Script And UI Wiring

**Files:**
- Create: `scripts/ui/hud.gd`
- Modify: `scenes/Main.tscn`

- [ ] **Step 1: Create UI directory**

Run:

```bash
mkdir -p scripts/ui
```

Expected: command exits with code 0.

- [ ] **Step 2: Add HUD script**

Create `scripts/ui/hud.gd`:

```gdscript
class_name Hud
extends Control

@onready var lives_label: Label = $TopBar/LivesLabel
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var arrow_button: Button = $TowerButtons/ArrowButton
@onready var splash_button: Button = $TowerButtons/SplashButton
@onready var slow_button: Button = $TowerButtons/SlowButton
@onready var start_wave_button: Button = $StartWaveButton
@onready var restart_button: Button = $RestartButton
@onready var status_label: Label = $StatusLabel

var game: Main

func setup(game_node: Main) -> void:
	game = game_node
	game.stats_changed.connect(_on_stats_changed)
	game.status_changed.connect(_on_status_changed)
	arrow_button.text = "Arrow $50"
	splash_button.text = "Splash $80"
	slow_button.text = "Slow $65"
	start_wave_button.text = "Start Wave"
	restart_button.text = "Restart"
	arrow_button.pressed.connect(func() -> void: game.select_tower(0))
	splash_button.pressed.connect(func() -> void: game.select_tower(1))
	slow_button.pressed.connect(func() -> void: game.select_tower(2))
	start_wave_button.pressed.connect(game.start_wave)
	restart_button.pressed.connect(game.restart)

func set_start_wave_enabled(enabled: bool) -> void:
	start_wave_button.disabled = not enabled

func show_restart(visible: bool) -> void:
	restart_button.visible = visible

func _on_stats_changed(lives: int, coins: int, wave: int, max_waves: int) -> void:
	lives_label.text = "Lives: %d" % lives
	coins_label.text = "Coins: %d" % coins
	wave_label.text = "Wave: %d/%d" % [wave, max_waves]

func _on_status_changed(text: String) -> void:
	status_label.text = text
```

- [ ] **Step 3: Attach HUD script and set layout**

Attach `res://scripts/ui/hud.gd` to `root/UI/Hud` in `scenes/Main.tscn`.

Set `Hud` anchors to full rect. Position `TopBar` at `(12, 12)`, `TowerButtons` at `(12, 48)`, `StartWaveButton` at `(12, 86)`, `RestartButton` at `(120, 86)`, and `StatusLabel` at `(12, 124)` with enough width for status text.

- [ ] **Step 4: Verify HUD wiring**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and no missing child node errors from `hud.gd`.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/hud.gd scenes/Main.tscn
git commit -m "feat: add tower defense HUD"
```

## Task 9: Map, Path, And Fixed Tower Slots

**Files:**
- Modify: `scenes/Main.tscn`

- [ ] **Step 1: Configure map visual**

In `scenes/Main.tscn`, configure `Map` with a TileSet using `assets/game/tilesets/grass.png` and `assets/game/objects/paths.png`. Paint a 24x14 tile farm field with a single snake path:

```text
Path cells:
(0,2) through (15,2)
(15,2) through (15,7)
(6,7) through (15,7)
(6,7) through (6,11)
(6,11) through (23,11)
```

If TileSet painting through MCP is not supported, use the Godot editor for the TileMap data and keep the `Map` node created by MCP.

- [ ] **Step 2: Configure enemy path curve**

Set `EnemyPath.curve` points in pixel coordinates for 16 px tiles:

```text
(0,40), (248,40), (248,120), (104,120), (104,184), (376,184)
```

Expected: enemies enter from the left, snake through the map, and exit near the right-side farm target.

- [ ] **Step 3: Instance fixed tower slots**

Instance `scenes/TowerSlot.tscn` as children of `TowerSlots` at these positions:

```text
Slot01 (80, 72)
Slot02 (160, 72)
Slot03 (216, 96)
Slot04 (176, 152)
Slot05 (72, 152)
Slot06 (136, 200)
Slot07 (232, 160)
Slot08 (304, 160)
```

- [ ] **Step 4: Add farm target decoration**

Use existing object sprites from `assets/game/objects/free_chicken_house.png` or `assets/game/tilesets/wooden_house.png` near `(392, 176)` to visually mark the endpoint. Use MCP `add_node` with `Sprite2D` where possible, then set texture and region in the editor or scene file.

- [ ] **Step 5: Verify map scene**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0 and `scenes/Main.tscn` loads with map, path, and 8 tower slot instances.

- [ ] **Step 6: Commit**

```bash
git add scenes/Main.tscn
git commit -m "feat: build first tower defense map"
```

## Task 10: Collision, Groups, And Runtime Verification Fixes

**Files:**
- Modify: `scenes/Enemy.tscn`
- Modify: `scenes/Tower.tscn`
- Modify: `scenes/TowerSlot.tscn`
- Modify: scripts touched by parse or runtime fixes from verification.

- [ ] **Step 1: Ensure enemy can be detected by towers**

If `Tower.get_overlapping_areas()` cannot detect `Enemy` because `Enemy` is a `PathFollow2D`, adjust `Enemy.tscn` by adding an `Area2D` child named `HitArea` with `CollisionShape2D`, then update tower targeting to inspect overlapping areas and use `area.get_parent()` when the area parent is an `Enemy`.

The tower targeting code should become:

```gdscript
func _find_target() -> Enemy:
	var best: Enemy
	var best_distance := INF
	for area: Area2D in get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy:
			var distance := enemy.distance_to_goal()
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best
```

- [ ] **Step 2: Ensure splash checks the right nodes**

If enemies are grouped on the `Enemy` root but positions come from `PathFollow2D`, keep `enemy.global_position` for splash distance. If grouping is moved to `HitArea`, use `area.get_parent()` before applying damage. Use one approach consistently.

- [ ] **Step 3: Run headless parse verification**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0.

- [ ] **Step 4: Run project for smoke test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --scene res://scenes/Main.tscn
```

Expected: the game window opens to the farm map with HUD and tower slots. Stop the process after confirming the window opens.

- [ ] **Step 5: Commit runtime fixes**

```bash
git add scenes scripts project.godot
git commit -m "fix: wire tower defense runtime collisions"
```

## Task 11: Manual Gameplay Verification And Balance Pass

**Files:**
- Modify: `resources/towers/*.tres`
- Modify: `resources/enemies/*.tres`
- Modify: `resources/waves/*.tres`
- Modify: scripts only for verified defects.

- [ ] **Step 1: Verify build phase**

Manual check:

```text
Open the project.
Confirm HUD shows Lives: 20, Coins: 180, Wave: 0/10.
Click Arrow, Splash, and Slow buttons.
Build each tower type on different slots.
Confirm coins decrease by 50, 80, and 65.
```

- [ ] **Step 2: Verify early waves**

Manual check:

```text
Start wave 1.
Confirm enemies follow the snake path.
Confirm towers attack enemies in range.
Confirm dead enemies increase coins.
Continue through wave 3.
Confirm fast enemies move faster than normal enemies.
```

- [ ] **Step 3: Verify leak and defeat**

Manual check:

```text
Restart.
Do not build towers.
Start waves until enough enemies reach the end.
Confirm lives decrease.
Confirm Defeat appears at 0 lives.
Confirm Restart reloads the initial state.
```

- [ ] **Step 4: Verify 10-wave victory**

Manual check:

```text
Restart.
Build a reasonable mix of Arrow, Splash, and Slow towers.
Play through all 10 waves.
If the game is too slow for verification, temporarily increase starting coins in main.gd to 999 for local testing, then restore it to 180 before committing.
Confirm Victory appears after wave 10 is cleared.
```

- [ ] **Step 5: Make one balance pass**

Adjust only Resource values if possible:

```text
If wave 1 cannot be cleared with two arrow towers, reduce normal_enemy.max_health to 30 or increase arrow_tower.damage to 14.
If splash tower is never useful, increase splash_radius to 52.
If slow tower trivializes tanks, raise slow_multiplier to 0.65 or lower slow_duration to 1.2.
If wave 10 is impossible with 8 filled slots, reduce tank_enemy.max_health to 75 or wave_10 tank count to 6.
```

- [ ] **Step 6: Final parse verification**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

Expected: exit code 0.

- [ ] **Step 7: Commit balance pass**

```bash
git add resources scripts scenes project.godot
git commit -m "tune: balance first tower defense slice"
```

## Self-Review

- Spec coverage: The plan covers MCP-created visible scenes, TileMap map, fixed tower slots, three tower types, three enemy types, 10 waves, state machine phases, UI, victory, defeat, restart, and verification.
- Placeholder scan: The plan contains no open placeholders. It includes exact file paths, exact Resource values, exact node names, and exact verification commands.
- Type consistency: `Main`, `Hud`, `Enemy`, `Tower`, `TowerSlot`, `TowerConfig`, `EnemyConfig`, `WaveEntry`, and `WaveConfig` are defined before or in the same task sequence where they are referenced. Temporary untyped fallbacks are explicitly restored once dependent scripts exist.

