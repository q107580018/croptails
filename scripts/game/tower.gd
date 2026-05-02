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
		cooldown = 1.0 / config.fire_rate

func apply_config(new_config: TowerConfig) -> void:
	config = new_config
	if is_node_ready():
		marker.color = config.marker_color
		sprite.sprite_frames = _build_sprite_frames()
		sprite.play(&"idle")
		var circle := CircleShape2D.new()
		circle.radius = config.range
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

func _attack(target: Enemy) -> void:
	sprite.flip_h = target.global_position.x < global_position.x
	sprite.play(&"shoot")
	_spawn_projectile(target.global_position)
	target.take_damage(config.damage)
	match config.role:
		TowerConfig.Role.SPLASH:
			_apply_splash(target.global_position, target)
		TowerConfig.Role.SLOW:
			target.apply_slow(config.slow_multiplier, config.slow_duration)
		_:
			pass

func _apply_splash(center: Vector2, target: Enemy) -> void:
	if config.splash_radius <= 0.0:
		return
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy:
			var enemy := node as Enemy
			if enemy != target and enemy.global_position.distance_to(center) <= config.splash_radius:
				enemy.take_damage(maxi(1, int(config.damage * 0.5)))


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
