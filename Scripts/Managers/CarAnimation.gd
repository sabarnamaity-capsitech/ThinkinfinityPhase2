extends Sprite2D

## CarAnimation — car sirf road segments ke upar chalti hai.
##
## Har road segment = tile_centre → tile_edge → neighbour_edge → neighbour_centre
## Isse car kabhi bhi "blank" jagah se nahi guzarti.

signal finished

const UP    = 1
const RIGHT = 2
const DOWN  = 4
const LEFT  = 8

const CAR_SPEED    : float = 180.0   # pixels/sec
const CAR_REL_SIZE : float = 0.26    # car size relative to cell

# Direction metadata: [dr, dc, our_bit, their_bit, edge_offset_normalised]
# edge_offset = where on THIS tile the road exits (0..1 of cell_size)
const DIR_META = [
	# dr   dc   our    their   exit_x  exit_y
	[-1,   0,   UP,    DOWN,   0.5,    0.0  ],   # UP    → top edge
	[ 0,   1,   RIGHT, LEFT,   1.0,    0.5  ],   # RIGHT → right edge
	[ 1,   0,   DOWN,  UP,     0.5,    1.0  ],   # DOWN  → bottom edge
	[ 0,  -1,   LEFT,  RIGHT,  0.0,    0.5  ],   # LEFT  → left edge
]

var _car       : ColorRect = null
var _waypoints : Array     = []   # Vector2 world positions
var _wp_idx    : int       = 0
var _running   : bool      = false
var _cell_size : float     = 32.0


# ─────────────────────────────────────────────────────────────────────────────
func start(grid: Array, rows: int, cols: int, cell_size: float) -> void:
	_cell_size = cell_size

	_waypoints = _build_waypoints(grid, rows, cols, cell_size)
	if _waypoints.size() < 2:
		finished.emit()
		return

	var sz : float = cell_size * CAR_REL_SIZE

	_car = ColorRect.new()
	_car.size = Vector2(sz, sz)
	_car.color = Color(0.95, 0.18, 0.18)
	_car.z_index = 100

	add_child(_car)

	_car.position = _waypoints[0] - _car.size * 0.5
	_wp_idx = 1
	_running = true



func _process(delta: float) -> void:
	if not _running or _car == null:
		return

	var target    : Vector2 = _waypoints[_wp_idx]
	var centre    : Vector2 = _car.position + _car.size * 0.5
	var to_target : Vector2 = target - centre
	var dist      : float   = to_target.length()
	var step      : float   = CAR_SPEED * delta

	if step >= dist:
		_car.position = target - _car.size * 0.5
		_wp_idx += 1
		if _wp_idx >= _waypoints.size():
			# Loop back to start for continuous driving
			_wp_idx = 0
	else:
		_car.position += to_target.normalized() * step



func _build_waypoints(grid: Array, rows: int, cols: int, cell_size: float) -> Array:
	var wps : Array = []
	var visited : Dictionary = {}

	# প্রথম active tile খুঁজে বের করো
	var start_r := -1
	var start_c := -1

	for r in range(rows):
		for c in range(cols):
			if grid[r][c].active:
				start_r = r
				start_c = c
				break
		if start_r != -1:
			break

	if start_r == -1:
		return wps

	_collect_path(grid, rows, cols, start_r, start_c, visited, wps)

	return wps


func _collect_path(
		grid: Array,
		rows: int,
		cols: int,
		r: int,
		c: int,
		visited: Dictionary,
		wps: Array
	) -> void:

	var key = Vector2i(r, c)
	if visited.has(key):
		return

	visited[key] = true

	# Tile-এর center add করো
	wps.append(grid[r][c].position)

	var tile = grid[r][c]

	for meta in DIR_META:
		var dr : int = meta[0]
		var dc : int = meta[1]
		var our : int = meta[2]
		var their : int = meta[3]

		if not (tile.conn & our):
			continue

		var nr = r + dr
		var nc = c + dc

		if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
			continue

		var nb = grid[nr][nc]
		if nb.active and (nb.conn & their):
			_collect_path(grid, rows, cols, nr, nc, visited, wps)
