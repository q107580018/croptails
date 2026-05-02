class_name Hud
extends Control

signal build_selected(slot: TowerSlot, tower_index: int)
signal tower_upgrade(tower: Tower)
signal tower_recycle(tower: Tower)

@export var build_menu_scene: PackedScene = preload("res://scenes/ui/BuildMenu.tscn")

@onready var lives_label: Label = $TopBar/LivesLabel
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var tower_buttons: HBoxContainer = $TowerButtons
@onready var start_wave_button: Button = $StartWaveButton
@onready var restart_button: Button = $RestartButton
@onready var status_label: Label = $StatusLabel

var game: Main
var build_menu: BuildMenu
var tower_action_menu: PanelContainer
var tower_action_backdrop: ColorRect
var tower_action_upgrade: Button
var tower_action_recycle: Button
var tower_action_close: Button
var tower_action_title: Label
var current_tower: Tower

const ACTION_MENU_SIZE := Vector2(200, 140)
const ACTION_MENU_MARGIN := 12.0
const ACTION_MENU_OFFSET := Vector2(18.0, -120.0)


func setup(game_node: Main) -> void:
	game = game_node
	game.stats_changed.connect(_on_stats_changed)
	game.status_changed.connect(_on_status_changed)
	tower_buttons.visible = false
	start_wave_button.text = "开始进攻"
	restart_button.text = "重新开始"
	start_wave_button.pressed.connect(game.start_wave)
	restart_button.pressed.connect(game.restart)
	_apply_hud_style()
	_create_build_menu_instance()
	_create_tower_action_menu()


func set_start_wave_enabled(enabled: bool) -> void:
	start_wave_button.disabled = not enabled


func show_restart(should_show: bool) -> void:
	restart_button.visible = should_show


func show_build_menu(slot: TowerSlot, tower_configs: Array[TowerConfig], coins: int, target_position: Vector2) -> void:
	hide_tower_action_menu()
	build_menu.show_for_slot(slot, tower_configs, coins, target_position)


func hide_build_menu() -> void:
	if build_menu:
		build_menu.hide_menu()


func show_tower_action_menu(tower: Tower, coins: int, target_position: Vector2) -> void:
	current_tower = tower
	var can_up := tower.can_upgrade()
	var up_cost := tower.get_upgrade_cost()
	tower_action_title.text = "%s Lv.%d" % [_localized_name(tower.config), tower.level]
	tower_action_upgrade.text = "升级 $%d" % up_cost if can_up else "已满级"
	tower_action_upgrade.disabled = not can_up or coins < up_cost
	tower_action_recycle.text = "回收 $%d" % tower.get_refund_value()
	tower_action_menu.position = _clamped_action_position(target_position)
	tower_action_backdrop.visible = true
	tower_action_menu.visible = true
	tower_action_menu.move_to_front()


func hide_tower_action_menu() -> void:
	if tower_action_backdrop:
		tower_action_backdrop.visible = false
	if tower_action_menu:
		tower_action_menu.visible = false
	current_tower = null


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide_tower_action_menu()


func _style_close_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(0.85, 0.82, 0.7))
	button.add_theme_stylebox_override("normal", _style_box(Color(0.15, 0.12, 0.08, 0.0), Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.65, 0.18, 0.16, 0.8), Color(0.9, 0.3, 0.25), 1))


func _on_stats_changed(lives: int, coins: int, wave: int, max_waves: int) -> void:
	lives_label.text = "生命 %d" % lives
	coins_label.text = "金币 %d" % coins
	wave_label.text = "波次 %d/%d" % [wave, max_waves]
	if build_menu:
		build_menu.update_coins(coins)
	if tower_action_menu and tower_action_menu.visible and current_tower:
		var can_up := current_tower.can_upgrade()
		var up_cost := current_tower.get_upgrade_cost()
		tower_action_upgrade.text = "升级 $%d" % up_cost if can_up else "已满级"
		tower_action_upgrade.disabled = not can_up or coins < up_cost
		tower_action_recycle.text = "回收 $%d" % current_tower.get_refund_value()


func _on_status_changed(text: String) -> void:
	status_label.text = text


func _apply_hud_style() -> void:
	var panel := $HudPanel as ColorRect
	panel.offset_right = 360.0
	panel.offset_bottom = 66.0
	panel.color = Color(0.06, 0.08, 0.07, 0.82)
	$TopBar.add_theme_constant_override("separation", 12)
	_style_label(lives_label)
	_style_label(coins_label)
	_style_label(wave_label)
	status_label.offset_top = 74.0
	status_label.offset_right = 460.0
	status_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	start_wave_button.position = Vector2(374, 14)
	start_wave_button.custom_minimum_size = Vector2(104, 36)
	restart_button.position = Vector2(486, 14)
	restart_button.custom_minimum_size = Vector2(86, 36)
	_style_button(start_wave_button, Color(0.23, 0.49, 0.27))
	_style_button(restart_button, Color(0.45, 0.18, 0.16))


func _create_build_menu_instance() -> void:
	build_menu = build_menu_scene.instantiate() as BuildMenu
	build_menu.tower_selected.connect(func(slot: TowerSlot, tower_index: int) -> void: build_selected.emit(slot, tower_index))
	add_child(build_menu)


func _create_tower_action_menu() -> void:
	tower_action_menu = PanelContainer.new()
	tower_action_menu.custom_minimum_size = ACTION_MENU_SIZE
	tower_action_menu.visible = false

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.06, 0.94)
	panel_style.border_color = Color(0.79, 0.69, 0.45, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	tower_action_menu.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var header := HBoxContainer.new()
	tower_action_title = Label.new()
	tower_action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_action_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_action_title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.78))
	header.add_child(tower_action_title)

	tower_action_close = Button.new()
	tower_action_close.text = "✕"
	tower_action_close.custom_minimum_size = Vector2(24, 24)
	tower_action_close.pressed.connect(hide_tower_action_menu)
	_style_close_button(tower_action_close)
	header.add_child(tower_action_close)
	vbox.add_child(header)

	tower_action_upgrade = Button.new()
	tower_action_upgrade.custom_minimum_size = Vector2(0, 34)
	tower_action_upgrade.pressed.connect(_on_upgrade_pressed)
	_style_button(tower_action_upgrade, Color(0.23, 0.42, 0.55))
	vbox.add_child(tower_action_upgrade)

	tower_action_recycle = Button.new()
	tower_action_recycle.custom_minimum_size = Vector2(0, 34)
	tower_action_recycle.pressed.connect(_on_recycle_pressed)
	_style_button(tower_action_recycle, Color(0.45, 0.18, 0.16))
	vbox.add_child(tower_action_recycle)

	margin.add_child(vbox)
	tower_action_menu.add_child(margin)
	add_child(tower_action_menu)

	tower_action_backdrop = ColorRect.new()
	tower_action_backdrop.color = Color(0, 0, 0, 0.01)
	tower_action_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	tower_action_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	tower_action_backdrop.gui_input.connect(_on_backdrop_input)
	tower_action_backdrop.visible = false
	add_child(tower_action_backdrop)
	move_child(tower_action_backdrop, tower_action_menu.get_index())


func _on_upgrade_pressed() -> void:
	if current_tower:
		tower_upgrade.emit(current_tower)


func _on_recycle_pressed() -> void:
	if current_tower:
		tower_recycle.emit(current_tower)


func _localized_name(config: TowerConfig) -> String:
	match config.role:
		TowerConfig.Role.MULTI_SHOT:
			return "群攻塔"
		TowerConfig.Role.SLOW:
			return "减速塔"
		_:
			return "箭塔"


func _clamped_action_position(target_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var menu_size := ACTION_MENU_SIZE
	var next_position := target_position + ACTION_MENU_OFFSET
	next_position.x = clampf(next_position.x, ACTION_MENU_MARGIN, viewport_size.x - menu_size.x - ACTION_MENU_MARGIN)
	next_position.y = clampf(next_position.y, ACTION_MENU_MARGIN, viewport_size.y - menu_size.y - ACTION_MENU_MARGIN)
	return next_position


func _style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.84))


func _style_button(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", _style_box(color, Color(0.79, 0.69, 0.45, 1.0), 1))
	button.add_theme_stylebox_override("hover", _style_box(color.lightened(0.12), Color(0.9, 0.8, 0.52, 1.0), 2))
	button.add_theme_stylebox_override("pressed", _style_box(color.darkened(0.15), Color(0.9, 0.8, 0.52, 1.0), 2))
	button.add_theme_color_override("font_color", Color(0.98, 0.94, 0.78))


func _style_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style
