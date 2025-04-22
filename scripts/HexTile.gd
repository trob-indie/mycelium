extends Area2D

@export var q: int
@export var r: int

@onready var sprite := $Sprite2D

var selected = false
var hovered = false
var is_flashing_invalid = false

var friendly_shader := preload("res://materials/Mycelium.tres")
var enemy_shader := preload("res://materials/EnemyMycelium.tres")
var dual_shader := preload("res://materials/DualMycelium.tres")

var has_mycelium = false
var is_enemy_mycelium = false
var is_occupied: bool = false
var is_dual_mycelium = false 
var occupying_mushroom: Node = null

var is_tree: bool = false
var tree_health: int = 100
var tree_node: Node = null  # Optional reference to the BaseTree scene

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

func set_mycelium_active(active: bool, is_enemy: bool = false, is_dual: bool = false) -> void:
	has_mycelium = active
	is_enemy_mycelium = is_enemy
	is_dual_mycelium = is_dual
	_update_shader()

func _update_shader():
	if not has_mycelium:
		$Sprite2D.material = null
		return

	var chosen_material: ShaderMaterial
	if is_dual_mycelium:
		chosen_material = dual_shader
	elif is_enemy_mycelium:
		chosen_material = enemy_shader
	else:
		chosen_material = friendly_shader

	$Sprite2D.material = chosen_material.duplicate()

func disable_mushroom():
	if occupying_mushroom and occupying_mushroom.has_method("set_disabled"):
		occupying_mushroom.set_disabled(true)
		if occupying_mushroom.has_node("Sprite2D") and occupying_mushroom.get_node("Sprite2D").material:
			var mat = occupying_mushroom.get_node("Sprite2D").material.duplicate()
			mat.set_shader_parameter("disabled_overlay", true)
			occupying_mushroom.get_node("Sprite2D").material = mat

func enable_mushroom():
	if occupying_mushroom and occupying_mushroom.has_method("set_disabled"):
		occupying_mushroom.set_disabled(false)
		if occupying_mushroom.has_node("Sprite2D") and occupying_mushroom.get_node("Sprite2D").material:
			var mat = occupying_mushroom.get_node("Sprite2D").material.duplicate()
			mat.set_shader_parameter("disabled_overlay", false)
			occupying_mushroom.get_node("Sprite2D").material = mat

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
