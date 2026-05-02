class_name TowerConfig
extends Resource

enum Role { ARROW, MULTI_SHOT, SLOW, MELEE_LINE }

@export var display_name: String = "Tower"
@export var role: Role = Role.ARROW
@export_file("*.tscn") var tower_scene_path: String = ""
@export var cost: int = 50
@export var range: float = 96.0
@export var fire_rate: float = 1.0
@export var damage: int = 8
@export var splash_radius: float = 0.0
@export var multi_arrow_count: int = 3
@export var line_attack_width: float = 28.0
@export_range(0.1, 1.0) var slow_multiplier: float = 1.0
@export var slow_duration: float = 0.0
@export var slow_target_count: int = 1
@export var slow_target_increment: int = 1
@export var slow_upgrade_step: float = 0.08
@export var marker_color: Color = Color.WHITE
@export var menu_icon_texture: Texture2D
@export var idle_texture: Texture2D
@export var shoot_texture: Texture2D
@export var shoot_up_texture: Texture2D
@export var shoot_down_texture: Texture2D
@export var shoot_up_right_texture: Texture2D
@export var shoot_down_right_texture: Texture2D
@export var projectile_texture: Texture2D
@export var frame_size: Vector2 = Vector2(192.0, 192.0)
@export var idle_frame_count: int = 6
@export var shoot_frame_count: int = 8
@export var max_level: int = 3
@export var upgrade_cost: int = 40
@export var upgrade_factor: float = 1.25
