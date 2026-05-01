class_name VictoryPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("Victory! The farm is safe.")
	game.show_restart(true)
