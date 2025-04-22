extends HBoxContainer

@export var basic_mushroom_scene: PackedScene
@export var trumpet_mushroom_scene: PackedScene
@export var cordyceps_mushroom_scene: PackedScene
@export var black_morel_mushroom_scene: PackedScene

var main_node: Node  # will reference your Main.gd

func _ready():
	main_node = get_node("/root/Root")  # or use a signal to assign if needed

	# Connect buttons
	$BasicButton.pressed.connect(_on_basic_selected)
	$TrumpetButton.pressed.connect(_on_trumpet_selected)
	$CordycepsButton.pressed.connect(_on_cordyceps_selected)
	$BlackMorelButton.pressed.connect(_on_black_morel_selected)

func _on_basic_selected():
	main_node.current_mushroom_scene = basic_mushroom_scene

func _on_trumpet_selected():
	main_node.current_mushroom_scene = trumpet_mushroom_scene

func _on_cordyceps_selected():
	main_node.current_mushroom_scene = cordyceps_mushroom_scene

func _on_black_morel_selected():
	main_node.current_mushroom_scene = black_morel_mushroom_scene
