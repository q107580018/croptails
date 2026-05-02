class_name Tower
extends Area2D

const ARROW_PROJECTILE_SCENE: PackedScene = preload("res://scenes/ArrowProjectile.tscn")
const MELEE_VERTICAL_ANGLE_RATIO := 1.35
const MELEE_DIAGONAL_ANGLE_RATIO := 0.45
const PROJECTILE_SPAWN_OFFSET := Vector2(0, -6)
const RANGE_UPGRADE_FACTOR := 1.08
const RATE_UPGRADE_FACTOR := 1.06
const MIN_SLOW_MULTIPLIER := 0.1
const REFUND_RATIO := 0.8
const MELEE_DIRECTION_EPSILON := 0.0001

@export var config: TowerConfig
@export var use_scene_animations: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var range_shape: CollisionShape2D = $RangeShape
@onready var melee_hitbox: Area2D = get_node_or_null("MeleeHitbox") as Area2D
@onready var melee_hitbox_shape: CollisionShape2D = get_node_or_null("MeleeHitbox/CollisionShape2D") as CollisionShape2D

var cooldown: float = 0.0
var level: int = 1
var built_on_slot: TowerSlot

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	if config:
		apply_config(config)

func _exit_tree() -> void:
	if built_on_slot:
		built_on_slot.reset_slot()
		built_on_slot = null

func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0 or config == null:
		return
	var target := _find_target()
	if target:
		_attack(target)
		cooldown = 1.0 / _effective_fire_rate()

func apply_config(new_config: TowerConfig) -> void:
	config = new_config
	if is_node_ready():
		if not use_scene_animations:
			sprite.sprite_frames = _build_sprite_frames()
		sprite.play(&"idle")
		var circle := CircleShape2D.new()
		circle.radius = _effective_range()
		range_shape.shape = circle

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

func _find_targets(count: int) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for area: Area2D in get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy:
			enemies.append(enemy)
	enemies.sort_custom(func(a: Enemy, b: Enemy): return a.distance_to_goal() < b.distance_to_goal())
	return enemies.slice(0, count)

func _attack(target: Enemy) -> void:
	_play_attack_animation(target.global_position)
	match config.role:
		TowerConfig.Role.MULTI_SHOT:
			var targets := _find_targets(config.multi_arrow_count)
			for t: Enemy in targets:
				_spawn_projectile(t.global_position)
				t.take_damage(_effective_damage())
		TowerConfig.Role.MELEE_LINE:
			_attack_melee_line(target.global_position)
		TowerConfig.Role.SLOW:
			var targets := _find_targets(_effective_slow_target_count())
			for t: Enemy in targets:
				_spawn_projectile(t.global_position)
				t.take_damage(_effective_damage())
				t.apply_slow(_effective_slow_multiplier(), config.slow_duration)
		_:
			_spawn_projectile(target.global_position)
			target.take_damage(_effective_damage())

func _attack_melee_line(target_position: Vector2) -> void:
	if melee_hitbox == null or melee_hitbox_shape == null:
		return
	var direction := target_position - global_position
	if direction.length_squared() <= MELEE_DIRECTION_EPSILON:
		return
	direction = direction.normalized()
	var attack_range := _effective_range()
	var rectangle := melee_hitbox_shape.shape as RectangleShape2D
	if rectangle == null:
		return
	rectangle.size = Vector2(attack_range, config.line_attack_width)
	melee_hitbox.position = direction * attack_range * 0.5
	melee_hitbox.rotation = direction.angle()
	melee_hitbox.set_deferred(&"monitoring", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var damaged: Array[Enemy] = []
	for area: Area2D in melee_hitbox.get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy and not damaged.has(enemy):
			damaged.append(enemy)
	for enemy: Enemy in damaged:
		enemy.take_damage(_effective_damage())
	melee_hitbox.set_deferred(&"monitoring", false)

func _play_attack_animation(target_position: Vector2) -> void:
	var animation := _attack_animation_name(target_position)
	sprite.flip_h = target_position.x < global_position.x
	sprite.play(animation)

func _attack_animation_name(target_position: Vector2) -> StringName:
	if config.role != TowerConfig.Role.MELEE_LINE:
		return &"shoot"
	var direction := target_position - global_position
	if direction.length_squared() <= MELEE_DIRECTION_EPSILON:
		return &"shoot"
	var abs_x := absf(direction.x)
	var abs_y := absf(direction.y)
	if abs_y > abs_x * MELEE_VERTICAL_ANGLE_RATIO:
		return &"shoot_down" if direction.y > 0.0 else &"shoot_up"
	if abs_y > abs_x * MELEE_DIAGONAL_ANGLE_RATIO:
		return &"shoot_down_right" if direction.y > 0.0 else &"shoot_up_right"
	return &"shoot"

func _spawn_projectile(target_position: Vector2) -> void:
	if config.projectile_texture == null:
		return
	var projectile := ARROW_PROJECTILE_SCENE.instantiate() as ArrowProjectile
	_projectile_parent().add_child(projectile)
	projectile.setup(to_global(PROJECTILE_SPAWN_OFFSET), target_position, config.projectile_texture)

func _projectile_parent() -> Node:
	var towers_node := get_parent()
	if towers_node:
		var world := towers_node.get_parent()
		if world:
			var projectiles := world.get_node_or_null("Projectiles")
			if projectiles:
				return projectiles
	return get_parent()

func _effective_damage() -> int:
	if config.upgrade_damage_add > 0:
		return config.damage + config.upgrade_damage_add * (level - 1)
	return int(roundi(config.damage * pow(config.upgrade_factor, level - 1)))

func _effective_range() -> float:
	return config.range * pow(RANGE_UPGRADE_FACTOR, level - 1)

func _effective_fire_rate() -> float:
	if config.upgrade_rate_add > 0.0:
		return config.fire_rate + config.upgrade_rate_add * (level - 1)
	return config.fire_rate * pow(RATE_UPGRADE_FACTOR, level - 1)

func _effective_slow_target_count() -> int:
	return config.slow_target_count + config.slow_target_increment * (level - 1)

func _effective_slow_multiplier() -> float:
	return maxf(config.slow_multiplier - config.slow_upgrade_step * (level - 1), MIN_SLOW_MULTIPLIER)

func can_upgrade() -> bool:
	return level < config.max_level

func get_range_radius() -> float:
	return _effective_range()

func get_range_color() -> Color:
	return config.marker_color if config else Color.WHITE

func get_upgrade_cost() -> int:
	return config.upgrade_cost * level

func get_upgrade_preview() -> String:
	if not can_upgrade():
		return ""
	var next_dmg: int
	var next_rate: float
	if config.upgrade_damage_add > 0:
		next_dmg = config.damage + config.upgrade_damage_add * level
	else:
		next_dmg = int(roundi(config.damage * pow(config.upgrade_factor, level)))
	if config.upgrade_rate_add > 0.0:
		next_rate = config.fire_rate + config.upgrade_rate_add * level
	else:
		next_rate = config.fire_rate * pow(RATE_UPGRADE_FACTOR, level)
	var next_range := config.range * pow(RANGE_UPGRADE_FACTOR, level)
	if config.role == TowerConfig.Role.SLOW:
		var next_target_count := config.slow_target_count + config.slow_target_increment * level
		var next_slow_multiplier := maxf(config.slow_multiplier - config.slow_upgrade_step * level, MIN_SLOW_MULTIPLIER)
		return "伤%d→%d  射%d→%d  速%.1f→%.1f  目标%d→%d  减%.0f%%→%.0f%%" % [
			_effective_damage(),
			next_dmg,
			int(_effective_range()),
			int(next_range),
			_effective_fire_rate(),
			next_rate,
			_effective_slow_target_count(),
			next_target_count,
			(1.0 - _effective_slow_multiplier()) * 100.0,
			(1.0 - next_slow_multiplier) * 100.0,
		]
	return "伤%d→%d  射%d→%d  速%.1f→%.1f" % [_effective_damage(), next_dmg, int(_effective_range()), int(next_range), _effective_fire_rate(), next_rate]

func get_refund_value() -> int:
	return int(config.cost * REFUND_RATIO + (level - 1) * config.upgrade_cost * REFUND_RATIO)

func upgrade() -> void:
	level += 1
	var circle := CircleShape2D.new()
	circle.radius = _effective_range()
	range_shape.shape = circle

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 8.0)
	_add_frames(frames, &"idle", config.idle_texture, config.idle_frame_count)
	_add_shoot_animation(frames, &"shoot", config.shoot_texture)
	_add_shoot_animation(frames, &"shoot_up", config.shoot_up_texture)
	_add_shoot_animation(frames, &"shoot_down", config.shoot_down_texture)
	_add_shoot_animation(frames, &"shoot_up_right", config.shoot_up_right_texture)
	_add_shoot_animation(frames, &"shoot_down_right", config.shoot_down_right_texture)
	return frames

func _add_shoot_animation(frames: SpriteFrames, animation: StringName, texture: Texture2D) -> void:
	if texture == null:
		return
	frames.add_animation(animation)
	frames.set_animation_loop(animation, false)
	frames.set_animation_speed(animation, 16.0)
	_add_frames(frames, animation, texture, config.shoot_frame_count)

func _add_frames(frames: SpriteFrames, animation: StringName, texture: Texture2D, frame_count: int) -> void:
	if texture == null:
		return
	for i: int in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(config.frame_size.x * i, 0, config.frame_size.x, config.frame_size.y)
		frames.add_frame(animation, frame)

func _on_sprite_animation_finished() -> void:
	if String(sprite.animation).begins_with("shoot"):
		sprite.play(&"idle")
