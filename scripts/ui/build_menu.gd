class_name BuildMenu
extends PanelContainer

signal tower_selected(slot: TowerSlot, tower_index: int)

@export var tower_option_scene: PackedScene = preload("res://scenes/ui/TowerOption.tscn")
@export var menu_margin: float = 12.0
@export var menu_offset: Vector2 = Vector2(18.0, -135.0)

var close_button: Button
var options_list: VBoxContainer

var selected_slot: TowerSlot
var current_tower_configs: Array[TowerConfig] = []
var close_connected: bool = false


func _ready() -> void:
	_bind_nodes()
	visible = false


func show_for_slot(slot: TowerSlot, tower_configs: Array[TowerConfig], coins: int, target_position: Vector2) -> void:
	_bind_nodes()
	selected_slot = slot
	current_tower_configs = tower_configs
	_clear_options()
	for i: int in current_tower_configs.size():
		var option := tower_option_scene.instantiate() as TowerOption
		options_list.add_child(option)
		option.setup(current_tower_configs[i], i, coins)
		option.selected.connect(_on_option_selected)
	position = _clamped_position(target_position)
	visible = true
	move_to_front()


func update_coins(coins: int) -> void:
	_bind_nodes()
	for child: Node in options_list.get_children():
		if child is TowerOption:
			(child as TowerOption).update_affordability(coins)


func hide_menu() -> void:
	visible = false
	selected_slot = null
	current_tower_configs = []


func _bind_nodes() -> void:
	if close_button == null:
		close_button = get_node("Margin/Content/Header/CloseButton") as Button
	if options_list == null:
		options_list = get_node("Margin/Content/OptionsList") as VBoxContainer
	if not close_connected:
		close_button.pressed.connect(hide_menu)
		close_connected = true


func _clear_options() -> void:
	for child: Node in options_list.get_children():
		options_list.remove_child(child)
		child.queue_free()


func _on_option_selected(tower_index: int) -> void:
	tower_selected.emit(selected_slot, tower_index)


func _clamped_position(target_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var menu_size := size
	if menu_size == Vector2.ZERO:
		menu_size = custom_minimum_size
	var next_position := target_position + menu_offset
	next_position.x = clampf(next_position.x, menu_margin, viewport_size.x - menu_size.x - menu_margin)
	next_position.y = clampf(next_position.y, menu_margin, viewport_size.y - menu_size.y - menu_margin)
	return next_position
