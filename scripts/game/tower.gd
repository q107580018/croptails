class_name Tower
extends Area2D

const ARROW_PROJECTILE_SCENE: PackedScene = preload("res://scenes/ArrowProjectile.tscn")
const ARCHER_FRAME_SIZE := Vector2(192.0, 192.0)
const IDLE_FRAME_COUNT := 6
const SHOOT_FRAME_COUNT := 8

@export var config: TowerConfig

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var marker: ColorRect = $Marker
@onready var range_shape: CollisionShape2D = $RangeShape

var cooldown: float = 0.0
var level: int = 1
var built_on_slot: TowerSlot

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	if config:
		apply_config(config)

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
		marker.color = config.marker_color
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
	sprite.flip_h = target.global_position.x < global_position.x
	sprite.play(&"shoot")
	match config.role:
		TowerConfig.Role.MULTI_SHOT:
			var targets := _find_targets(config.multi_arrow_count)
			for t: Enemy in targets:
				_spawn_projectile(t.global_position)
				t.take_damage(_effective_damage())
		TowerConfig.Role.SLOW:
			_spawn_projectile(target.global_position)
			target.take_damage(_effective_damage())
			target.apply_slow(config.slow_multiplier, config.slow_duration)
		_:
			_spawn_projectile(target.global_position)
			target.take_damage(_effective_damage())

func _spawn_projectile(target_position: Vector2) -> void:
	if config.projectile_texture == null:
		return
	var projectile := ARROW_PROJECTILE_SCENE.instantiate() as ArrowProjectile
	_projectile_parent().add_child(projectile)
	projectile.setup(to_global(Vector2(0, -6)), target_position, config.projectile_texture)

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
	return int(roundi(config.damage * pow(config.upgrade_factor, level - 1)))

func _effective_range() -> float:
	return config.range * pow(1.08, level - 1)

func _effective_fire_rate() -> float:
	return config.fire_rate * pow(1.06, level - 1)

func can_upgrade() -> bool:
	return level < config.max_level

func get_upgrade_cost() -> int:
	return config.upgrade_cost * level

func get_upgrade_preview() -> String:
	if not can_upgrade():
		return ""
	var next_dmg := int(roundi(config.damage * pow(config.upgrade_factor, level)))
	var next_range := config.range * pow(1.08, level)
	var next_rate := config.fire_rate * pow(1.06, level)
	return "伤%d→%d  射%d→%d  速%.1f→%.1f" % [_effective_damage(), next_dmg, int(_effective_range()), int(next_range), _effective_fire_rate(), next_rate]

func get_refund_value() -> int:
	return int(config.cost * 0.8 + (level - 1) * config.upgrade_cost * 0.8)

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
	_add_frames(frames, &"idle", config.idle_texture, IDLE_FRAME_COUNT)
	frames.add_animation(&"shoot")
	frames.set_animation_loop(&"shoot", false)
	frames.set_animation_speed(&"shoot", 16.0)
	_add_frames(frames, &"shoot", config.shoot_texture, SHOOT_FRAME_COUNT)
	return frames

func _add_frames(frames: SpriteFrames, animation: StringName, texture: Texture2D, frame_count: int) -> void:
	if texture == null:
		return
	for i: int in frame_count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(ARCHER_FRAME_SIZE.x * i, 0, ARCHER_FRAME_SIZE.x, ARCHER_FRAME_SIZE.y)
		frames.add_frame(animation, frame)

func _on_sprite_animation_finished() -> void:
	if sprite.animation == &"shoot":
		sprite.play(&"idle")
