class_name TowerSlot
extends Area2D

signal build_requested(slot: TowerSlot)
signal tower_clicked(slot: TowerSlot)

@onready var marker: ColorRect = $Marker

var occupied: bool = false
var building_enabled: bool = true
var current_tower: Tower

func _ready() -> void:
	input_event.connect(_on_input_event)

func set_enabled(enabled: bool) -> void:
	building_enabled = enabled
	marker.visible = enabled or occupied
	modulate = Color.WHITE if enabled else Color(0.55, 0.55, 0.55)

func mark_occupied() -> void:
	occupied = true
	marker.color = Color(0.25, 0.25, 0.25, 0.85)

func reset_slot() -> void:
	occupied = false
	current_tower = null
	marker.color = Color(0.2, 0.7, 0.2, 0.65)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not building_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if occupied:
			tower_clicked.emit(self)
		else:
			build_requested.emit(self)
