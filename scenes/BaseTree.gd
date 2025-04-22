extends Node2D

@onready var health_bar = $HealthBar
@onready var sprite = $Sprite2D  # Assumes your tree's Sprite2D node is named this

@export var tree_sprite_healthy: Texture
@export var tree_sprite_damaged: Texture
@export var tree_sprite_critical: Texture

var max_health := 100
var current_health := 100

func _ready():
	update_health_bar()

func take_damage(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	update_health_bar()

func update_health_bar():
	var percent := float(current_health) / float(max_health) * 100.0
	health_bar.value = percent

	# Duplicate and assign unique style for the health bar fill
	var original_style = health_bar.get("theme_override_styles/fill")
	if original_style:
		var bar_style = original_style.duplicate()
		if percent <= 33:
			bar_style.bg_color = Color.RED
		elif percent <= 66:
			bar_style.bg_color = Color.YELLOW
		else:
			bar_style.bg_color = Color.LIME_GREEN
		health_bar.add_theme_stylebox_override("fill", bar_style)

	# Update tree sprite
	if percent <= 0:
		sprite.visible = false
	elif percent <= 33:
		sprite.texture = tree_sprite_critical
		sprite.visible = true
	elif percent <= 66:
		sprite.texture = tree_sprite_damaged
		sprite.visible = true
	else:
		sprite.texture = tree_sprite_healthy
		sprite.visible = true
