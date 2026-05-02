class_name VictoryPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("胜利！农场守住了。")
	game.show_restart(true)
