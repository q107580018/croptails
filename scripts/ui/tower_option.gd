class_name TowerOption
extends Button

signal selected(index: int)
signal hover_started(config: TowerConfig)
signal hover_ended

var tower_icon: TextureRect
var icon_frame: Control
var title_label: Label
var description_label: Label

var tower_index: int = -1
var tower_config: TowerConfig


func _ready() -> void:
	_bind_nodes()
	pressed.connect(func() -> void: selected.emit(tower_index))
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(config: TowerConfig, index: int, coins: int) -> void:
	_bind_nodes()
	tower_config = config
	tower_index = index
	tower_icon.texture = config.menu_icon_texture if config.menu_icon_texture else _first_idle_frame(config.idle_texture, config.frame_size)
	if tower_icon.texture == null:
		push_warning("Tower option '%s' has no menu icon texture." % config.display_name)
	icon_frame.custom_minimum_size = Vector2(64.0, 64.0)
	icon_frame.size = Vector2(64.0, 64.0)
	tower_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tower_icon.show()
	tower_icon.queue_redraw()
	title_label.text = "%s  $%d" % [config.localized_name(), config.cost]
	description_label.text = _tower_description(config)
	update_affordability(coins)


func update_affordability(coins: int) -> void:
	if tower_config == null:
		return
	var can_afford := coins >= tower_config.cost
	disabled = not can_afford
	title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72) if can_afford else Color(0.58, 0.58, 0.52))
	description_label.add_theme_color_override("font_color", Color(0.83, 0.84, 0.77) if can_afford else Color(0.48, 0.5, 0.46))


func _bind_nodes() -> void:
	if icon_frame == null:
		icon_frame = %IconFrame
	if tower_icon == null:
		tower_icon = %Icon
	if title_label == null:
		title_label = %TitleLabel
	if description_label == null:
		description_label = %DescriptionLabel


func _tower_description(config: TowerConfig) -> String:
	var parts: Array[String] = [
		"伤%d" % config.damage,
		"射%d" % int(config.range),
		"速%.1f" % config.fire_rate,
	]
	if config.role == TowerConfig.Role.MULTI_SHOT:
		parts.append("矢%d" % config.multi_arrow_count)
	elif config.role == TowerConfig.Role.SLOW:
		parts.append("减%.0f%% %.1fs" % [(1.0 - config.slow_multiplier) * 100.0, config.slow_duration])
	elif config.role == TowerConfig.Role.MELEE_LINE:
		parts.append("线宽%d" % int(config.line_attack_width))
	return "  ".join(parts)


func _first_idle_frame(texture: Texture2D, frame_size: Vector2) -> Texture2D:
	if texture == null:
		return null
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = Rect2(Vector2.ZERO, frame_size)
	return frame


func _on_mouse_entered() -> void:
	if tower_config:
		hover_started.emit(tower_config)


func _on_mouse_exited() -> void:
	hover_ended.emit()
