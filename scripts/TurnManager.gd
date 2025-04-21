extends Node

enum Turn { PLAYER, ENEMY }
var current_turn: Turn = Turn.PLAYER

@export var game_root: NodePath
@export var spore_ui_path: NodePath
@export var entity_layer_path: NodePath
@export var mushroom_scene: PackedScene
@export var main: Node

var game       : Node
var spore_ui   : Node
var entity_layer : Node

var enemy_spore_count := 3

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
	enemy_spore_count = 3
	await spawn_enemy_mushrooms()
	await get_tree().create_timer(1.0).timeout
	start_player_turn()


# --- Enemy AI logic ---

func spawn_enemy_mushrooms():
	var candidates: Array = []

	for tile in main.grid.values():
		if tile.has_mycelium and tile.is_enemy_mycelium and not tile.is_occupied:
			candidates.append(tile)

	if candidates.is_empty():
		return

	candidates.sort_custom(func(a, b):
		return get_directional_enemy_tile_score(a) > get_directional_enemy_tile_score(b)
	)

	for i in range(enemy_spore_count):
		if i >= candidates.size():
			break

		var tile = candidates[i]
		var mushroom = mushroom_scene.instantiate()
		mushroom.name = "EnemyMushroom"
		mushroom.position = tile.global_position + Vector2(0, 1)
		main.entity_layer.add_child(mushroom)

		tile.is_occupied = true

		if mushroom.is_trumpet:
			var neighbors = main.get_hex_ring(tile.q, tile.r, 1)
			for neighbor in neighbors:
				if not neighbor.has_mycelium:
					neighbor.set_mycelium_active(true, true)

func get_directional_enemy_tile_score(tile) -> float:
	var base_pos = main.grid[main.start_base_coords].global_position
	var tile_pos = tile.global_position
	var to_base_distance = tile_pos.distance_to(base_pos)

	var neighbors = main.get_hex_ring(tile.q, tile.r, 1)

	var potential_new_tiles := 0
	for neighbor in neighbors:
		if not neighbor.has_mycelium and not neighbor.is_occupied:
			potential_new_tiles += 1

	# Not an edge tile = don't consider
	if potential_new_tiles == 0:
		return -INF

	# Tune these weights to balance spread vs aggression
	var spread_weight = 10.0
	var distance_penalty = 0.5

	return potential_new_tiles * spread_weight - to_base_distance * distance_penalty

func get_enemy_tile_score(tile) -> float:
	var edge_score = 0
	var neighbors = main.get_hex_ring(tile.q, tile.r, 1)
	for neighbor in neighbors:
		if not neighbor.has_mycelium:
			edge_score += 1

	var base_tile = main.grid[main.start_base_coords]
	var distance = tile.global_position.distance_to(base_tile.global_position)

	# Lower distance is better, so we subtract it from a base value
	return edge_score * 10 - distance * 0.01
