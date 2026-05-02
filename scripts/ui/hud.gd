class_name Hud
extends Control

signal build_selected(slot: TowerSlot, tower_index: int)

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


func set_start_wave_enabled(enabled: bool) -> void:
	start_wave_button.disabled = not enabled


func show_restart(should_show: bool) -> void:
	restart_button.visible = should_show


func show_build_menu(slot: TowerSlot, tower_configs: Array[TowerConfig], coins: int, target_position: Vector2) -> void:
	build_menu.show_for_slot(slot, tower_configs, coins, target_position)


func hide_build_menu() -> void:
	if build_menu:
		build_menu.hide_menu()


func _on_stats_changed(lives: int, coins: int, wave: int, max_waves: int) -> void:
	lives_label.text = "生命 %d" % lives
	coins_label.text = "金币 %d" % coins
	wave_label.text = "波次 %d/%d" % [wave, max_waves]
	if build_menu:
		build_menu.update_coins(coins)


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
