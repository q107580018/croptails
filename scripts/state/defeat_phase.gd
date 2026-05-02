class_name DefeatPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(false)
	game.set_start_wave_enabled(false)
	game.set_status("失败，农场被突破了。")
	game.show_restart(true)
