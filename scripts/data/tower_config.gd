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
@export var menu_icon_texture: Texture2D
@export var idle_texture: Texture2D
@export var shoot_texture: Texture2D
@export var projectile_texture: Texture2D
