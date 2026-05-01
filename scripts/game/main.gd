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
	if spawning or enemy_path.get_child_count() > 0:
		return
	if lives <= 0:
		state_machine.transition_to(&"DefeatPhase")
	elif not has_more_waves():
		state_machine.transition_to(&"VictoryPhase")
	else:
		coins += waves[current_wave_index - 1].coin_bonus
		state_machine.transition_to(&"BuildPhase")

func _emit_stats() -> void:
	stats_changed.emit(lives, coins, current_wave_index, waves.size())
