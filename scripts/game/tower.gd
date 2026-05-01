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
	for area: Area2D in get_overlapping_areas():
		var enemy := area.get_parent() as Enemy
		if enemy:
			var distance := enemy.distance_to_goal()
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best

func _attack(target: Enemy) -> void:
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
