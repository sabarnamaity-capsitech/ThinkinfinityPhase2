extends Node

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
func start(grid: Array, rows: int, cols: int,
		   grid_area: Control, cell_size: float) -> void:
	_cell_size = cell_size

	# Build waypoints: centre → edge → neighbour-edge → neighbour-centre …
	_waypoints = _build_waypoints(grid, rows, cols, cell_size, grid_area)
	if _waypoints.size() < 2:
		finished.emit()
		return

	# Create car
	var sz : float = cell_size * CAR_REL_SIZE
	_car           = ColorRect.new()
	_car.size      = Vector2(sz, sz)
	_car.color     = Color(0.95, 0.18, 0.18)
	_car.z_index   = 20
	grid_area.add_child(_car)

	_car.position = _waypoints[0] - _car.size * 0.5
	_wp_idx  = 1
	_running = true


# ─────────────────────────────────────────────────────────────────────────────
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


# ─────────────────────────────────────────────────────────────────────────────
# Waypoint builder
#
# For every road edge A→B we emit 4 points:
#   1. centre of A
#   2. exit-edge of A  (where road leaves A)
#   3. entry-edge of B (where road enters B, = mirror of exit)
#   4. centre of B
#
# This keeps the car exactly on the road strip at all times.
# We do an Eulerian-style walk: use each directed edge once, loop back.
# ─────────────────────────────────────────────────────────────────────────────
func _build_waypoints(grid: Array, rows: int, cols: int,
					  cell_size: float, grid_area: Control) -> Array:

	# World position helpers (in grid_area local coords)
	var tile_centre = func(r: int, c: int) -> Vector2:
		return Vector2(c * cell_size + cell_size * 0.5,
					   r * cell_size + cell_size * 0.5)

	var tile_edge = func(r: int, c: int, ex: float, ey: float) -> Vector2:
		return Vector2(c * cell_size + ex * cell_size,
					   r * cell_size + ey * cell_size)

	# Find a good start tile (prefer one with only 1 connection = dead-end,
	# so the path looks natural; fall back to any active tile)
	var start_r := -1
	var start_c := -1
	for r in range(rows):
		for c in range(cols):
			var t = grid[r][c]
			if not t.active:
				continue
			var bits := 0
			for b in [UP, RIGHT, DOWN, LEFT]:
				if t.conn & b:
					bits += 1
			if bits == 1:
				start_r = r
				start_c = c
				break
		if start_r >= 0:
			break
	if start_r < 0:
		for r in range(rows):
			for c in range(cols):
				if grid[r][c].active:
					start_r = r; start_c = c; break
			if start_r >= 0:
				break
	if start_r < 0:
		return []

	# DFS collecting waypoints — only travel along actual road connections
	var edge_used : Dictionary = {}
	var wps       : Array      = []

	_dfs(grid, rows, cols, start_r, start_c, -1, -1,
		 edge_used, wps, tile_centre, tile_edge, cell_size)

	# Close the loop: add waypoints back to start so car loops smoothly
	if wps.size() >= 2:
		wps.append(tile_centre.call(start_r, start_c))

	return wps


func _dfs(grid: Array, rows: int, cols: int,
		  r: int, c: int, from_r: int, from_c: int,
		  edge_used: Dictionary, wps: Array,
		  tile_centre: Callable, tile_edge: Callable,
		  cell_size: float) -> void:

	var tile = grid[r][c]

	# Add this tile's centre as a waypoint
	wps.append(tile_centre.call(r, c))

	# Try each direction that has a road connection
	for meta in DIR_META:
		var dr    : int   = meta[0]
		var dc    : int   = meta[1]
		var our   : int   = meta[2]
		var their : int   = meta[3]
		var ex    : float = meta[4]
		var ey    : float = meta[5]

		if not (tile.conn & our):
			continue   # no road this way

		var nr : int = r + dr
		var nc : int = c + dc
		if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
			continue
		var nb = grid[nr][nc]
		if not nb.active:
			continue
		if not (nb.conn & their):
			continue   # neighbour has no matching road (shouldn't happen post-solve)

		var key : String = "%d,%d>%d,%d" % [r, c, nr, nc]
		if edge_used.has(key):
			continue   # already used this road segment

		edge_used[key]                                      = true
		edge_used["%d,%d>%d,%d" % [nr, nc, r, c]] = true

		# Exit edge of current tile
		wps.append(tile_edge.call(r, c, ex, ey))

		# Entry edge of neighbour tile (mirror: 1-ex, 1-ey)
		wps.append(tile_edge.call(nr, nc, 1.0 - ex, 1.0 - ey))

		# Recurse into neighbour
		_dfs(grid, rows, cols, nr, nc, r, c,
			 edge_used, wps, tile_centre, tile_edge, cell_size)

		# After returning, add this tile's centre again so car
		# smoothly returns before trying next branch
		wps.append(tile_centre.call(r, c))
