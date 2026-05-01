class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state_name: StringName = &"BuildPhase"

var current_state: State
var states: Dictionary[StringName, State] = {}

func setup(game_node: Node) -> void:
	for child: Node in get_children():
		if child is State:
			var state := child as State
			states[state.name] = state
			state.state_machine = self
			state.game = game_node
			state.set_process(false)
	if states.has(initial_state_name):
		current_state = states[initial_state_name]
		current_state.set_process(true)
		current_state.enter()

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("State '%s' not found" % state_name)
		return
	var previous := current_state
	if current_state:
		current_state.exit()
		current_state.set_process(false)
	current_state = states[state_name]
	current_state.set_process(true)
	current_state.enter(msg)
	if previous:
		state_changed.emit(previous.name, current_state.name)
