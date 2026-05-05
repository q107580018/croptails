class_name StatusHud
extends Control

const HEART_COUNT := 10
const HEALTH_PER_HEART := 2
const HEART_FULL_TEXTURE: Texture2D = preload("res://assets/ui/health/heart_full.png")
const HEART_HALF_TEXTURE: Texture2D = preload("res://assets/ui/health/heart_half.png")
const HEART_EMPTY_TEXTURE: Texture2D = preload("res://assets/ui/health/heart_empty.png")

@onready var heart_row: HBoxContainer = $BackgroundPanel/Content/HeartLine/HeartRow
@onready var coins_label: Label = $BackgroundPanel/Content/InfoLine/StatsRow/CoinsBadge/Label
@onready var wave_label: Label = $BackgroundPanel/Content/InfoLine/StatsRow/WaveBadge/Label
@onready var status_label: Label = $BackgroundPanel/Content/StatusLabel
@onready var start_wave_button: Button = $BackgroundPanel/Content/InfoLine/Actions/StartWaveButton
@onready var restart_button: Button = $BackgroundPanel/Content/InfoLine/Actions/RestartButton

var heart_icons: Array[TextureRect] = []


func _ready() -> void:
	_cache_heart_icons()
	_update_lives(HEART_COUNT * HEALTH_PER_HEART)


func set_stats(lives: int, coins: int, wave: int, max_waves: int) -> void:
	_update_lives(lives)
	coins_label.text = "金币 %d" % coins
	wave_label.text = "波次 %d/%d" % [wave, max_waves]


func set_status(text: String) -> void:
	status_label.text = text


func set_start_wave_enabled(enabled: bool) -> void:
	start_wave_button.disabled = not enabled


func show_restart(should_show: bool) -> void:
	restart_button.visible = should_show


func _cache_heart_icons() -> void:
	heart_icons.clear()
	for child: Node in heart_row.get_children():
		if child is TextureRect:
			heart_icons.append(child as TextureRect)


func _update_lives(lives: int) -> void:
	var clamped_lives := clampi(lives, 0, HEART_COUNT * HEALTH_PER_HEART)
	for i: int in heart_icons.size():
		var remaining_for_heart := clamped_lives - i * HEALTH_PER_HEART
		if remaining_for_heart >= HEALTH_PER_HEART:
			heart_icons[i].texture = HEART_FULL_TEXTURE
		elif remaining_for_heart == 1:
			heart_icons[i].texture = HEART_HALF_TEXTURE
		else:
			heart_icons[i].texture = HEART_EMPTY_TEXTURE
