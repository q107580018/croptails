class_name ArrowProjectile
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var start_position: Vector2
var target_position: Vector2
var projectile_texture: Texture2D
var duration: float = 0.22
var elapsed: float = 0.0

func setup(from_position: Vector2, to_position: Vector2, texture: Texture2D) -> void:
	start_position = from_position
	target_position = to_position
	projectile_texture = texture
	global_position = from_position
	if is_node_ready():
		_apply_setup()

func _ready() -> void:
	_apply_setup()

func _process(delta: float) -> void:
	elapsed += delta
	var weight := clampf(elapsed / duration, 0.0, 1.0)
	global_position = start_position.lerp(target_position, weight)
	if weight >= 1.0:
		queue_free()

func _apply_setup() -> void:
	sprite.texture = projectile_texture
	rotation = start_position.angle_to_point(target_position)
