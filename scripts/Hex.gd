class_name Hex

var q: int
var r: int

func _init(_q: int, _r: int):
	q = _q
	r = _r

func axial_to_pixel(q: int, r: int, hex_size: float) -> Vector2:
	var width = sqrt(3) * hex_size
	var height = 2 * hex_size
	var x = width * (q + r / 2.0)
	var y = height * (3.0 / 4.0) * r
	return Vector2(x, y)

func axial_to_isometric(q: int, r: int, hex_size: float) -> Vector2:
	var pos = axial_to_pixel(q, r, hex_size)
	var iso_x = pos.x - pos.y
	var iso_y = (pos.x + pos.y) / 2.0

	# Add padding/stretch vertically
	iso_y *= 1.2425  # tweak this number — try 1.1 to 1.3

	return Vector2(iso_x, iso_y)
