class_name WavePhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("Wave in progress.")
	game.spawn_current_wave()
