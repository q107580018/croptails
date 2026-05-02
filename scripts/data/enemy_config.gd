class_name EnemyConfig
extends Resource

@export var display_name: String = "Enemy"
@export var max_health: int = 30
@export var speed: float = 55.0
@export var reward: int = 8
@export var life_damage: int = 1
@export var enemy_scene: PackedScene
@export var sprite_texture: Texture2D
@export var sprite_region: Rect2 = Rect2(0, 0, 16, 16)
@export var sprite_scale: Vector2 = Vector2.ONE
@export var tint: Color = Color.WHITE
