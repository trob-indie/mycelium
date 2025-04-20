extends Node

enum Turn { PLAYER, ENEMY }
var current_turn: Turn = Turn.PLAYER

@export var game_root: NodePath
@export var spore_ui_path: NodePath
@export var entity_layer_path: NodePath
@export var mushroom_scene: PackedScene

var game       : Node
var spore_ui   : Node
var entity_layer : Node

func _ready():
	game = get_node(game_root)
	spore_ui = get_node(spore_ui_path)
	entity_layer = get_node(entity_layer_path)

	start_player_turn()


# --- Turn Handling ---

func start_player_turn():
	current_turn = Turn.PLAYER
	spore_ui.start_turn()

func start_enemy_turn():
	current_turn = Turn.ENEMY
	await spawn_enemy_mushrooms()
	await get_tree().create_timer(1.0).timeout
	start_player_turn()


# --- Enemy AI logic ---

func spawn_enemy_mushrooms():
	var enemy_spores = spore_ui.spores_per_turn
	var candidates: Array = []

	for tile in game.grid.values():
		if tile.has_mycelium and tile.is_enemy_mycelium and tile.get_node_or_null("Mushroom") == null:
			candidates.append(tile)

	candidates.shuffle()

	for i in range(min(enemy_spores, candidates.size())):
		var tile = candidates[i]

		var mushroom = mushroom_scene.instantiate()
		mushroom.name = "EnemyMushroom"
		mushroom.position = tile.global_position + Vector2(0, 1)
		entity_layer.add_child(mushroom)
