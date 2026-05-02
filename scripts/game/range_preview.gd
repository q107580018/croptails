class_name RangePreview
extends Node2D

const SEGMENT_COUNT := 64
const FILL_ALPHA := 0.18
const OUTLINE_ALPHA := 0.72
const OUTLINE_WIDTH := 2.0

var radius: float = 0.0
var preview_color: Color = Color(0.85, 0.77, 0.42, 1.0)


func show_preview(world_position: Vector2, new_radius: float, color: Color) -> void:
	position = world_position
	radius = new_radius
	preview_color = color
	visible = true
	queue_redraw()


func hide_preview() -> void:
	if not visible:
		return
	visible = false


func _draw() -> void:
	if radius <= 0.0:
		return
	var fill := preview_color
	fill.a = FILL_ALPHA
	var outline := preview_color
	outline.a = OUTLINE_ALPHA
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, SEGMENT_COUNT, outline, OUTLINE_WIDTH)
