extends Node

@export var is_trumpet: bool = false
@export var is_front_lines: bool = false
@export var is_cordyceps: bool = false
@export var is_siege: bool = false
var disabled: bool = false

func set_disabled(state: bool):
	disabled = state
	# grayscale or dim if disabled
	var modulate:Color
	if state:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		Color(1, 1, 1, 1)
	set_process(!state)  # optionally disable processing

func is_siege_mushroom() -> bool: 
	return is_siege
