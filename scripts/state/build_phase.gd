class_name BuildPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(true)
	game.set_status("Build towers, then start the next wave.")
	game.set_start_wave_enabled(game.has_more_waves())
