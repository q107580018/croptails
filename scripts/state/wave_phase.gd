class_name WavePhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(true)
	game.set_start_wave_enabled(false)
	game.set_status("Wave in progress. You can keep building.")
	game.spawn_current_wave()
