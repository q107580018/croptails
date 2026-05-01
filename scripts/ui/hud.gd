class_name Hud
extends Control

@onready var lives_label: Label = $TopBar/LivesLabel
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var arrow_button: Button = $TowerButtons/ArrowButton
@onready var splash_button: Button = $TowerButtons/SplashButton
@onready var slow_button: Button = $TowerButtons/SlowButton
@onready var start_wave_button: Button = $StartWaveButton
@onready var restart_button: Button = $RestartButton
@onready var status_label: Label = $StatusLabel

var game: Main


func setup(game_node: Main) -> void:
	game = game_node
	game.stats_changed.connect(_on_stats_changed)
	game.status_changed.connect(_on_status_changed)
	arrow_button.text = "Arrow $50"
	splash_button.text = "Splash $80"
	slow_button.text = "Slow $65"
	start_wave_button.text = "Start Wave"
	restart_button.text = "Restart"
	arrow_button.pressed.connect(func() -> void: game.select_tower(0))
	splash_button.pressed.connect(func() -> void: game.select_tower(1))
	slow_button.pressed.connect(func() -> void: game.select_tower(2))
	start_wave_button.pressed.connect(game.start_wave)
	restart_button.pressed.connect(game.restart)


func set_start_wave_enabled(enabled: bool) -> void:
	start_wave_button.disabled = not enabled


func show_restart(visible: bool) -> void:
	restart_button.visible = visible


func _on_stats_changed(lives: int, coins: int, wave: int, max_waves: int) -> void:
	lives_label.text = "Lives: %d" % lives
	coins_label.text = "Coins: %d" % coins
	wave_label.text = "Wave: %d/%d" % [wave, max_waves]


func _on_status_changed(text: String) -> void:
	status_label.text = text
