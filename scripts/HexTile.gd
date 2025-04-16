extends Area2D

@export var q: int
@export var r: int

var selected = false
var hovered = false

func _ready():
	_update_visual()

func _update_visual():
	if selected:
		$Sprite2D.modulate = Color(0.5, 1, 0.5)  # greenish
	elif hovered:
		$Sprite2D.modulate = Color(1, 0.85, 0.5)  # orange-ish
	else:
		$Sprite2D.modulate = Color(1, 1, 1)  # default

func set_selected(state: bool):
	selected = state
	_update_visual()

func _on_mouse_entered():
	hovered = true
	_update_visual()

func _on_mouse_exited():
	hovered = false
	_update_visual()

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_parent().call_deferred("on_tile_clicked", self)
