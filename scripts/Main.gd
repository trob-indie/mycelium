extends Node2D

@export var hex_tile_scene: PackedScene
var hex_size = 32.0
var grid_radius = 5
var grid = {}
var selected_tile = null

func _ready():
	generate_path_with_bases(50, 1, 4)

# ------------------------------------------------------------------
#  Generate a winding path *with* large hex‑shaped bases on each end
# ------------------------------------------------------------------
func generate_path_with_bases(length: int, path_thickness: int = 1, base_radius: int = 4) -> void:
	var visited : Dictionary = {}
	var q := 0
	var r := 0

	# 1. ——— START BASE ———
	_place_base(q, r, base_radius, visited)

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

# Place a full hexagon of tiles of ‘radius’ around (cq, cr)
func _place_base(cq: int, cr: int, radius: int, visited: Dictionary) -> void:
	for dq in range(-radius, radius + 1):
		for dr in range(-radius, radius + 1):
			if abs(dq + dr) <= radius:        # axial hex‑range test
				_place_tile(cq + dq, cr + dr, visited)


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
	var hex  := Hex.new(q, r)
	var pos  := hex.axial_to_isometric(q, r, hex_size)
	var tile := hex_tile_scene.instantiate()
	tile.position = pos
	tile.q = q
	tile.r = r
	tile.z_index = int(tile.position.y)    # depth‑correct draw order
	add_child(tile)
	grid[key] = tile
	visited[key] = true

func _unselect_all():
	for tile in grid.values():
		tile.set_selected(false)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var clicked_tile = _get_tile_at_pos(mouse_pos)
		if clicked_tile:
			_unselect_all()
			clicked_tile.set_selected(true)
			selected_tile = clicked_tile

func _get_tile_at_pos(pos: Vector2):
	# Brute-force check all tiles for now (can optimize later)
	for tile in grid.values():
		if tile.get_global_transform().get_origin().distance_to(pos) < hex_size:
			return tile
	return null

func on_tile_clicked(tile):
	_unselect_all()
	tile.set_selected(true)
	selected_tile = tile

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
