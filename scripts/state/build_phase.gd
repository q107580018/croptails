class_name BuildPhase
extends State

func enter(_msg: Dictionary = {}) -> void:
	game.set_building_enabled(true)
	game.set_status("点击建造点选择防御塔，准备好后开始下一波。")
	game.set_start_wave_enabled(game.has_more_waves())
