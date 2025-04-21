extends Area2D

@export var q: int
@export var r: int

@onready var sprite := $Sprite2D

var selected = false
var hovered = false
var is_flashing_invalid = false  # ✅ new flag

var friendly_shader := preload("res://materials/Mycelium.tres")
var enemy_shader := preload("res://materials/EnemyMycelium.tres")
var dual_shader := preload("res://materials/DualMycelium.tres")

var has_mycelium = false
var is_enemy_mycelium = false
var is_occupied: bool = false
var is_dual_mycelium = false 

signal mouse_entered_tile
signal mouse_exited_tile

func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	_update_visual()

func _on_mouse_entered():
	hovered = true
	_update_visual()

func _on_mouse_exited():
	hovered = false
	_update_visual()

func set_selected(state: bool) -> void:
	if is_flashing_invalid:
		return  # ❌ suppress during red flash

	selected = state
	_update_visual()

	if state:
		call_deferred("_clear_selection_delayed")

func set_hovered(state: bool) -> void:
	if is_flashing_invalid:
		return  # ❌ suppress during red flash

	hovered = state
	_update_visual()

func _clear_selection_delayed():
	await get_tree().create_timer(0.5).timeout
	selected = false
	_update_visual()

func _update_visual():
	if $Sprite2D.material and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("is_hovered", hovered)
		$Sprite2D.material.set_shader_parameter("is_selected", selected)
	else:
		if selected:
			$Sprite2D.modulate = Color(0.4, 1.0, 0.4)
		elif hovered:
			$Sprite2D.modulate = Color(1.0, 0.85, 0.5)
		else:
			$Sprite2D.modulate = Color(1, 1, 1)

func set_mycelium_active(active: bool, is_enemy: bool = false) -> void:
	if not active:
		return  # Skip deactivation for now

	if has_mycelium:
		# Mycelium already exists — check for overlap
		if is_enemy_mycelium != is_enemy and not is_dual_mycelium:
			is_dual_mycelium = true
			var dual_material = preload("res://materials/DualMycelium.tres")
			$Sprite2D.material = dual_material.duplicate()
		return  # Already claimed — no further action needed

	# First-time mycelium activation
	has_mycelium = true
	is_enemy_mycelium = is_enemy

	var chosen_material: ShaderMaterial = null
	if is_enemy:
		chosen_material = preload("res://materials/EnemyMycelium.tres")
	else:
		chosen_material = preload("res://materials/Mycelium.tres")

	$Sprite2D.material = chosen_material.duplicate()

func flash_invalid():
	var prev_hovered = hovered
	var prev_selected = selected

	is_flashing_invalid = true
	hovered = false
	selected = false
	_update_visual()

	if $Sprite2D.material and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("flash_invalid", true)

	await get_tree().create_timer(0.3).timeout

	if $Sprite2D.material and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("flash_invalid", false)

	is_flashing_invalid = false

	# Rely on signals to update hover naturally
	selected = false
	_update_visual()
