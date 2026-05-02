class_name WavePhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(true)
	game.set_start_wave_enabled(false)
	game.set_status("敌人正在进攻，仍可继续建造。")
	game.spawn_current_wave()
