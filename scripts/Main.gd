extends Node2D

@export var hex_tile_scene: PackedScene
@export var default_mushroom_scene: PackedScene
var current_mushroom_scene: PackedScene
@export var base_tree_scene: PackedScene

@onready var entity_layer = $EntityLayer
@onready var spore_ui = $UI
@onready var turn_manager = $TurnManager

var hex_size = 32.0
var grid_radius = 5
var grid = {}
var selected_tile = null

var start_base_coords: Vector2
var end_base_coords: Vector2

var hovered_tile: Node = null

func _ready():
	generate_path_with_bases(10, 1, 4)
	current_mushroom_scene = default_mushroom_scene

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var top_tile = _get_topmost_tile_at_pos(mouse_pos)

	if top_tile != hovered_tile:
		# Clear previous hover
		if hovered_tile and hovered_tile.has_method("set_hovered"):
			hovered_tile.set_hovered(false)

		# Set new hover
		if top_tile and top_tile.has_method("set_hovered"):
			top_tile.set_hovered(true)

		hovered_tile = top_tile

# ------------------------------------------------------------------
#  Generate a winding path *with* large hex‑shaped bases on each end
# ------------------------------------------------------------------
func generate_path_with_bases(length: int, path_thickness: int = 1, base_radius: int = 4) -> void:
	var visited : Dictionary = {}
	var q := 0
	var r := 0

	# 1. ——— START BASE ———
	_place_base(q, r, base_radius, visited)
	_place_base_tree(q, r)
	start_base_coords = Vector2(q, r)
	animate_mycelium_spread(start_base_coords.x, start_base_coords.y, 2, 0.2, false)

	# Pick a direction that heads “forward”
	var exit_dir := Vector2(1, 0)        # east   (you could randomise)
	var step_dir := exit_dir             # remember for thickening later

	# Walk out of the base by base_radius + 1 steps,
	# laying a thin corridor so it’s visually connected
	for i in range(base_radius + 1):
		q += int(exit_dir.x)
		r += int(exit_dir.y)
		_place_tile(q, r, visited)       # corridor tile

	# 2. ——— WANDERING PATH ———
	for i in range(length):
		_place_tile(q, r, visited)

		if path_thickness > 0:
			_thicken_path(q, r, step_dir, path_thickness, visited)

		# choose next step
		var options = [
			Vector2(1, 0), Vector2(1, -1), Vector2(0, -1)
		]
		if randi() % 10 < 3:
			options.append(Vector2(-1, 1))
			options.append(Vector2(0, 1))
		options.shuffle()

		var moved := false
		for dir in options:
			var nq = q + int(dir.x)
			var nr = r + int(dir.y)
			if not visited.has(Vector2(nq, nr)):
				q = nq
				r = nr
				step_dir = dir
				moved = true
				break
		if not moved:
			break   # dead‑end

	# 3. ——— END BASE ———
	_place_base(q, r, base_radius, visited)
	_place_base_tree(q, r)
	end_base_coords = Vector2(q, r)
	animate_mycelium_spread(end_base_coords.x, end_base_coords.y, 2, 0.2, true)

# Place a full hexagon of tiles of ‘radius’ around (cq, cr)
func _place_base(cq: int, cr: int, radius: int, visited: Dictionary) -> void:
	for dq in range(-radius, radius + 1):
		for dr in range(-radius, radius + 1):
			if abs(dq + dr) <= radius:        # axial hex‑range test
				_place_tile(cq + dq, cr + dr, visited)

func _place_base_tree(q: int, r: int) -> void:
	var hex = Hex.new(q, r)
	var pos = hex.axial_to_isometric(q, r, hex_size)

	var tree = base_tree_scene.instantiate()
	tree.position = pos
	entity_layer.add_child(tree)

	# ✅ Mark the tile with a tree
	var key = Vector2(q, r)
	if grid.has(key):
		grid[key].is_tree = true  # Add this property to HexTile.gd
		grid[key].tree_health = 100  # Initial health
		grid[key].tree_node = tree  # Store the actual node if needed

# Widen the path by laying tiles perpendicular to the current step dir
func _thicken_path(q: int, r: int, dir: Vector2, thickness: int, visited: Dictionary) -> void:
	var perp_left  := Vector2(-dir.y,  dir.x)
	var perp_right := Vector2( dir.y, -dir.x)
	for t in range(1, thickness + 1):
		_place_tile(q + int(perp_left.x)  * t,
					 r + int(perp_left.y) * t, visited)
		_place_tile(q + int(perp_right.x) * t,
					 r + int(perp_right.y) * t, visited)

# Drop a single tile at (q,r) if it hasn’t been placed yet
func _place_tile(q: int, r: int, visited: Dictionary) -> void:
	var key := Vector2(q, r)
	if visited.has(key):
		return
	var hex = Hex.new(q, r)
	var pos = hex.axial_to_isometric(q, r, hex_size)
	var tile = hex_tile_scene.instantiate()
	tile.position = pos
	tile.q = q
	tile.r = r

	entity_layer.add_child(tile)  # ✅ Add to Y-sorted layer

	grid[key] = tile
	visited[key] = true

func animate_mycelium_spread(center_q: int, center_r: int, max_radius: int, delay: float = 0.2, is_enemy: bool = false) -> void:
	# Run this as a coroutine
	await _spread_mycelium(center_q, center_r, max_radius, delay, is_enemy)

func _spread_mycelium(center_q: int, center_r: int, max_radius: int, delay: float, is_enemy: bool) -> void:
	for radius in range(max_radius + 1):
		var ring = get_hex_ring(center_q, center_r, radius)
		for tile in ring:
			if tile.has_method("set_mycelium_active"):
				tile.set_mycelium_active(true, is_enemy)
		await get_tree().create_timer(delay).timeout

func get_hex_ring(center_q: int, center_r: int, radius: int) -> Array:
	var results: Array = []
	for dq in range(-radius, radius + 1):
		for dr in range(-radius, radius + 1):
			var ds = -dq - dr
			if abs(ds) <= radius:
				var q = center_q + dq
				var r = center_r + dr
				var key = Vector2(q, r)
				if grid.has(key):
					results.append(grid[key])
	return results

func _unselect_all():
	for tile in grid.values():
		tile.set_selected(false)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_mouse_pos = get_global_mouse_position()
		var tile = _get_topmost_tile_at_pos(world_mouse_pos)

		if tile:
			_unselect_all()

			var mushroom = current_mushroom_scene.instantiate()
			var is_front_lines = mushroom.has_method("is_front_lines") and mushroom.is_front_lines
			var is_siege = mushroom.has_method("is_siege") and mushroom.is_siege

			var is_valid := false

			if is_front_lines:
				# Cordyceps: only on dual tiles
				is_valid = tile.is_dual_mycelium and not tile.is_occupied
			else:
				# All others: friendly-only, not occupied
				is_valid = (
					tile.has_mycelium
					and not tile.is_enemy_mycelium
					and not tile.is_occupied
				)

			# Siege restriction
			if mushroom.is_siege:
				var tile_coords = Vector2(tile.q, tile.r)
				var distance = axial_distance(tile_coords, end_base_coords)
				if distance > 2:
					is_valid = false
			
			if is_valid:
				tile.set_selected(true)
				selected_tile = tile
				on_tile_clicked(tile)
			else:
				if tile.has_method("flash_invalid"):
					tile.flash_invalid()

func axial_distance(a: Vector2, b: Vector2) -> int:
	var dq = abs(a.x - b.x)
	var dr = abs(a.y - b.y)
	var ds = abs((-a.x - a.y) - (-b.x - b.y))  # s = -q - r
	return int((dq + dr + ds) / 2)

func _get_topmost_tile_at_pos(pos: Vector2) -> Node:
	var top_tile: Node = null
	var top_y := INF  # lower y means it's visually on top
	
	for tile in grid.values():
		var poly = tile.get_node_or_null("CollisionPolygon2D")
		if poly and poly.polygon.size() > 2:
			var local_mouse = tile.to_local(pos)
			if Geometry2D.is_point_in_polygon(local_mouse, poly.polygon):
				# Pick tile closest to screen (lowest y)
				if tile.global_position.y < top_y:
					top_tile = tile
					top_y = tile.position.y
	return top_tile

func _get_tile_at_pos(pos: Vector2):
	# Brute-force check all tiles for now (can optimize later)
	for tile in grid.values():
		if tile.get_global_transform().get_origin().distance_to(pos) < hex_size:
			return tile
	return null

func on_tile_clicked(tile):
	if turn_manager.has_method("current_turn") and turn_manager.current_turn != turn_manager.Turn.PLAYER:
		return

	_unselect_all()
	tile.set_selected(true)
	selected_tile = tile

	if not spore_ui.has_spores():
		tile.flash_invalid()
		return

	var mushroom = current_mushroom_scene.instantiate()

	var is_valid := false

	if mushroom.is_front_lines:
		is_valid = tile.is_dual_mycelium and not tile.is_occupied
	else:
		if mushroom.is_trumpet:
			is_valid = (
				tile.has_mycelium
				and not tile.is_enemy_mycelium
				and not tile.is_occupied
			)
		else:
			is_valid = (
				tile.has_mycelium
				and not tile.is_enemy_mycelium
				and not tile.is_dual_mycelium
				and not tile.is_occupied
			)

	if mushroom.is_siege:
		var enemy_base_pos = grid[end_base_coords].position
		var dist = tile.position.distance_to(enemy_base_pos)
		if dist > hex_size * 3:
			is_valid = false

	if is_valid:
		mushroom.name = "Mushroom"
		mushroom.position = tile.global_position + Vector2(0, 1)
		entity_layer.add_child(mushroom)

		tile.is_occupied = true
		tile.occupying_mushroom = mushroom
		spore_ui.use_spore()

		if mushroom.is_cordyceps:
			convert_neighbors_to_friendly(tile.q, tile.r)
		elif mushroom.is_trumpet:
			convert_neighbors_to_dual(tile.q, tile.r)
			spread_mycelium_around(tile.q, tile.r, false, true)

		if not spore_ui.has_spores():
			turn_manager.start_enemy_turn()
	else:
		tile.flash_invalid()

var dragging = false
var last_mouse_pos = Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				last_mouse_pos = get_viewport().get_mouse_position()
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta = current_mouse_pos - last_mouse_pos
		$Camera2D.position = $Camera2D.position.lerp($Camera2D.position - delta, 0.5)  # move opposite to mouse drag
		last_mouse_pos = current_mouse_pos

func can_place_mushroom_on(tile) -> bool:
	return tile.get_node_or_null("Mushroom") == null \
		and tile.has_mycelium \
		and not tile.is_enemy_mycelium \
		and not tile.is_dual_mycelium \
		and not tile.is_occupied

func spread_mycelium_around(center_q: int, center_r: int, is_enemy: bool = false, allow_dual: bool = false):
	var max_radius = 2
	for radius in range(1, max_radius + 1):
		var ring = get_hex_ring(center_q, center_r, radius)
		for tile in ring:
			if not tile.has_mycelium:
				tile.set_mycelium_active(true, is_enemy, false)
			elif allow_dual and is_enemy != tile.is_enemy_mycelium:
				tile.set_mycelium_active(true, true, true)  # dual
			# else: do nothing (already our mycelium or dual)

func convert_neighbors_to_friendly(q: int, r: int):
	var neighbors = get_hex_ring(q, r, 1)
	for neighbor in neighbors:
		if not neighbor.has_mycelium:
			continue
		neighbor.set_mycelium_active(true, false)

		# Disable enemy mushrooms on those tiles
		if neighbor.occupying_mushroom and neighbor.occupying_mushroom.is_in_group("enemy"):
			neighbor.disable_mushroom()

func convert_neighbors_to_dual(q: int, r: int):
	for radius in range(1, 3):  # 1 and 2 (2 rings out)
		var neighbors = get_hex_ring(q, r, radius)
		for neighbor in neighbors:
			if not neighbor.has_mycelium:
				# Set friendly if no mycelium
				neighbor.set_mycelium_active(true, false, false)
			elif neighbor.is_enemy_mycelium:
				# Set to dual if it was enemy
				neighbor.set_mycelium_active(true, false, true)
			# else leave it as-is if already friendly

func apply_siege_damage_to_enemy():
	var base_tile = grid[end_base_coords]
	var tree = base_tile.tree_node

	for child in entity_layer.get_children():
		if child.has_method("is_siege_mushroom") and child.is_siege_mushroom() and not child.is_in_group("enemy"):
			var siege_pos = child.global_position
			var dist = base_tile.global_position.distance_to(siege_pos)
			if dist <= hex_size * 3.5:
				if tree and tree.has_method("take_damage"):
					tree.take_damage(10)

func apply_siege_damage_to_player():
	var base_tile = grid[start_base_coords]
	var tree = base_tile.tree_node

	for child in entity_layer.get_children():
		if child.has_method("is_siege_mushroom") and child.is_siege_mushroom() and child.is_in_group("enemy"):
			var siege_pos = child.global_position
			var dist = base_tile.global_position.distance_to(siege_pos)
			if dist <= hex_size * 3.5:
				if tree and tree.has_method("take_damage"):
					tree.take_damage(10)
