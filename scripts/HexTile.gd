extends Area2D

@export var q: int
@export var r: int

@onready var sprite := $Sprite2D

var selected = false
var hovered = false

var friendly_shader := preload("res://materials/Mycelium.tres")
var enemy_shader := preload("res://materials/EnemyMycelium.tres")

var has_mycelium = false
var is_enemy_mycelium = false

func _ready():
	_update_visual()

func set_selected(state: bool) -> void:
	selected = state
	_update_visual()

	# If clicked (selected = true), auto-unselect after 0.5s
	if state:
		call_deferred("_clear_selection_delayed")

func set_hovered(state: bool) -> void:
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
		# fallback if not using shader
		if selected:
			$Sprite2D.modulate = Color(0.4, 1.0, 0.4)  # green
		elif hovered:
			$Sprite2D.modulate = Color(1.0, 0.85, 0.5)  # orange
		else:
			$Sprite2D.modulate = Color(1, 1, 1)

func set_mycelium_active(active: bool, is_enemy: bool = false) -> void:
	has_mycelium = active
	is_enemy_mycelium = is_enemy

	if active:
		var chosen_material: ShaderMaterial
		if is_enemy:
			chosen_material = enemy_shader
		else:
			chosen_material = friendly_shader

		$Sprite2D.material = chosen_material.duplicate()
	else:
		$Sprite2D.material = null

func flash_invalid():
	if $Sprite2D.material and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("is_selected", false)
		$Sprite2D.material.set_shader_parameter("is_hovered", false)
		$Sprite2D.material.set_shader_parameter("flash_invalid", true)
		await get_tree().create_timer(0.3).timeout
		$Sprite2D.material.set_shader_parameter("flash_invalid", false)
