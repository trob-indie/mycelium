extends CanvasLayer

@export var spores_per_turn: int = 2
var current_spores: int = 0

@onready var spore_container = $SporeContainer
@export var spore_texture: Texture2D

func _ready():
	start_turn()

func start_turn():
	current_spores = spores_per_turn
	update_spore_display()

func has_spores() -> bool:
	return current_spores > 0

func use_spore():
	if has_spores():
		current_spores -= 1
		update_spore_display()
	else:
		print("No spores left!")

func update_spore_display():
	for child in spore_container.get_children():
		spore_container.remove_child(child)
		child.queue_free()
	
	for i in range(current_spores):
		var icon := TextureRect.new()
		icon.texture = spore_texture

		# Limit the actual display size
		icon.custom_minimum_size = Vector2(32, 32)

		# Prevent the container from stretching it
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Optional for visual quality
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		spore_container.add_child(icon)
