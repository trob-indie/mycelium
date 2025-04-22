extends Node

enum Turn { PLAYER, ENEMY }
var current_turn: Turn = Turn.PLAYER

@export var trumpet_mushroom_scene: PackedScene
@export var basic_mushroom_scene: PackedScene
@export var cordyceps_mushroom_scene: PackedScene

@export var game_root: NodePath
@export var spore_ui_path: NodePath
@export var entity_layer_path: NodePath
@export var main: Node

var game       : Node
var spore_ui   : Node
var entity_layer : Node

var enemy_spore_count := 2

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
	enemy_spore_count = 2
	await spawn_enemy_mushrooms()
	await get_tree().create_timer(1.0).timeout
	main.apply_siege_damage_to_player()
	start_player_turn()


# --- Enemy AI logic ---

func spawn_enemy_mushrooms():
	var spores_left = enemy_spore_count
	var candidates: Array = []

	# Step 1: Find all valid tiles (unoccupied enemy mycelium)
	for tile in main.grid.values():
		if tile.has_mycelium and tile.is_enemy_mycelium and not tile.is_occupied:
			candidates.append(tile)

	# Sort candidates by usefulness (same as before)
	candidates.sort_custom(func(a, b):
		return get_directional_enemy_tile_score(a) > get_directional_enemy_tile_score(b)
	)

	# Step 2: CORDYCEPS — place on dual-mycelium tiles first
	for tile in candidates:
		if spores_left <= 0:
			break

		if tile.is_dual_mycelium:
			var mushroom = cordyceps_mushroom_scene.instantiate()
			mushroom.add_to_group("enemy")
			mushroom.name = "EnemyMushroom"
			mushroom.position = tile.global_position + Vector2(0, 1)
			tile.occupying_mushroom = mushroom
			main.entity_layer.add_child(mushroom)
			
			if mushroom.is_cordyceps:
				convert_neighbors_to_enemy(tile.q, tile.r)

			tile.is_occupied = true
			spores_left -= 1

	# Step 3: TRUMPET — expand enemy mycelium
	for tile in candidates:
		if spores_left <= 0:
			break

		if tile.is_occupied or tile.is_dual_mycelium:
			continue

		var score = get_directional_enemy_tile_score(tile)
		if score <= 0:
			continue

		var mushroom = trumpet_mushroom_scene.instantiate()
		mushroom.add_to_group("enemy")
		mushroom.name = "EnemyMushroom"
		mushroom.position = tile.global_position + Vector2(0, 1)
		tile.occupying_mushroom = mushroom
		main.entity_layer.add_child(mushroom)

		tile.is_occupied = true
		spores_left -= 1

		# spread from trumpet
		main.spread_mycelium_around(tile.q, tile.r, true)

	# Step 4: BASIC fallback — only on pure enemy tiles
	for tile in candidates:
		if spores_left <= 0:
			break

		if tile.is_occupied or tile.is_dual_mycelium:
			continue

		var mushroom = basic_mushroom_scene.instantiate()
		mushroom.add_to_group("enemy")
		mushroom.name = "EnemyMushroom"
		mushroom.position = tile.global_position + Vector2(0, 1)
		tile.occupying_mushroom = mushroom
		main.entity_layer.add_child(mushroom)

		tile.is_occupied = true
		spores_left -= 1
	main.apply_siege_damage_to_enemy()

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
	var distance_penalty = 0.01

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

func convert_neighbors_to_enemy(q: int, r: int):
	var neighbors = main.get_hex_ring(q, r, 1)
	for neighbor in neighbors:
		if not neighbor.has_mycelium:
			continue
		neighbor.set_mycelium_active(true, true)

		if neighbor.occupying_mushroom and not neighbor.occupying_mushroom.is_in_group("enemy"):
			neighbor.disable_mushroom()
