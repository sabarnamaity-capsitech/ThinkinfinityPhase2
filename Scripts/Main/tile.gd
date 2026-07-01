extends TextureRect
class_name Tile

signal rotated

const UP    = 1
const RIGHT = 2
const DOWN  = 4
const LEFT  = 8

var row : int = 0
var col : int = 0
var active : bool = true
var conn : int = 0

@export var is_roundabout := false

var _input_locked := false

# store textures for future rotations
var _dead_end : Texture2D
var _straight : Texture2D
var _corner : Texture2D
var _t : Texture2D
var _cross : Texture2D
var _circle : Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(
	r : int,
	c : int,
	is_active : bool,
	connection : int,
	cell_size : float,
	p_dead_end : Texture2D,
	p_straight : Texture2D,
	p_corner : Texture2D,
	p_t : Texture2D,
	p_cross : Texture2D,
	p_circle : Texture2D
) -> void:

	row = r
	col = c
	active = is_active
	conn = connection

	_dead_end = p_dead_end
	_straight = p_straight
	_corner = p_corner
	_t = p_t
	_cross = p_cross
	_circle = p_circle

	# Fixed size
	custom_minimum_size = Vector2.ZERO
	size = Vector2(cell_size, cell_size)

	# TextureRect settings
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE

	# Rotate around center
	pivot_offset = size * 0.5

	_update_sprite()


func _gui_input(event: InputEvent) -> void:
	if !active or _input_locked:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			rotate_clockwise()


func rotate_clockwise() -> void:
	if is_roundabout:
		rotated.emit()
		return

	conn = ((conn << 1) | (conn >> 3)) & 15

	_update_sprite()
	rotated.emit()


func play_reveal_then_scramble(
	solved_conn: int,
	scrambled_conn: int,
	show_secs: float,
	spin_secs: float
) -> void:

	if !active:
		return

	_input_locked = true

	conn = solved_conn
	_update_sprite()

	await get_tree().create_timer(show_secs + spin_secs).timeout

	conn = scrambled_conn
	_update_sprite()

	_input_locked = false


func _update_sprite() -> void:
	if !active:
		visible = false
		return

	visible = true

	var tex : Texture2D = null
	var rot_deg : float = 0.0
	var bit_count := _popcount(conn)

	# roundabout
	if is_roundabout and conn == 15:
		tex = _circle if _circle != null else _cross
		rot_deg = 0.0

	# dead end
	elif bit_count == 1:
		tex = _dead_end
		rot_deg = _dead_end_rot(conn)

	# straight / corner
	elif bit_count == 2:
		if conn == 5 or conn == 10:
			tex = _straight
			rot_deg = _straight_rot(conn)
		else:
			tex = _corner
			rot_deg = _corner_rot(conn)

	# t junction
	elif bit_count == 3:
		tex = _t
		rot_deg = _t_rot(conn)

	# cross
	elif bit_count == 4:
		tex = _cross
		rot_deg = 0.0

	texture = tex
	rotation_degrees = rot_deg

	if tex != null:
		stretch_mode = TextureRect.STRETCH_SCALE


func _dead_end_rot(c : int) -> float:
	match c:
		UP: return 0
		RIGHT: return 90
		DOWN: return 180
		LEFT: return 270
	return 0


func _straight_rot(c : int) -> float:
	return 90 if c == 10 else 0


func _corner_rot(c : int) -> float:
	match c:
		3: return 0
		6: return 90
		12: return 180
		9: return 270
	return 0


func _t_rot(c : int) -> float:
	match c:
		7: return 0
		14: return 90
		13: return 180
		11: return 270
	return 0


func _popcount(n : int) -> int:
	var count := 0
	while n:
		count += n & 1
		n >>= 1
	return count