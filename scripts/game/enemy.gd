class_name Enemy
extends PathFollow2D

signal died(enemy: Enemy, reward: int)
signal reached_goal(enemy: Enemy, life_damage: int)

@export var config: EnemyConfig

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int = 1
var base_speed: float = 50.0
var slow_multiplier: float = 1.0
var slow_remaining: float = 0.0
var escaped: bool = false
var dead: bool = false

func _ready() -> void:
	if config:
		apply_config(config)

func _process(delta: float) -> void:
	if slow_remaining > 0.0:
		slow_remaining = maxf(slow_remaining - delta, 0.0)
		if slow_remaining == 0.0:
			slow_multiplier = 1.0
	var previous_position := global_position
	progress += base_speed * slow_multiplier * delta
	_update_facing(global_position - previous_position)
	if progress_ratio >= 1.0 and not escaped:
		escaped = true
		reached_goal.emit(self, config.life_damage if config else 1)
		queue_free()

func apply_config(new_config: EnemyConfig) -> void:
	config = new_config
	health = config.max_health
	base_speed = config.speed
	if is_node_ready():
		sprite.scale = config.sprite_scale
		sprite.modulate = config.tint
		sprite.play(&"run")
		health_bar.max_value = config.max_health
		health_bar.value = health

func take_damage(amount: int) -> void:
	if dead:
		return
	health = max(health - amount, 0)
	health_bar.value = health
	if health <= 0:
		dead = true
		died.emit(self, config.reward if config else 0)
		queue_free()

func apply_slow(multiplier: float, duration: float) -> void:
	if multiplier < slow_multiplier or slow_remaining <= 0.0:
		slow_multiplier = multiplier
	slow_remaining = maxf(slow_remaining, duration)

func distance_to_goal() -> float:
	return 1.0 - progress_ratio

func _update_facing(movement: Vector2) -> void:
	if movement.length_squared() <= 0.0001:
		return
	if absf(movement.x) > absf(movement.y):
		sprite.flip_h = movement.x < 0.0
	else:
		sprite.flip_h = movement.y > 0.0
