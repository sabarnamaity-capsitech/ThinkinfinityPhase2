extends Sprite2D
class_name TileRenderer


var _tex_straight : Texture2D
var _tex_tjunction: Texture2D
var _tex_corner_a : Texture2D
var _tex_cross : Texture2D
var _tex_roundabout : Texture2D
var _tex_corner_b : Texture2D
var _tex_corner_c : Texture2D
var _tex_deadend: Texture2D

const BASE_STRAIGHT = 5   # N+S
const BASE_CORNER   = 6   # E+S
const BASE_T        = 13  # N+S+W
const BASE_DEAD     = 8   # W



var row: int = -1
var col: int = -1
var conn: int = 0
var skin_variant: int = 0
var skin_rot: int = 0
var active: bool = false

signal tapped(tile: TileRenderer)

@onready var _area: Area2D = $Area2D

var _disp_tile: float = 0.0
var _rot_tween: Tween = null


func _ready() -> void:
	if _area:
		_area.input_pickable = true
		_area.input_event.connect(_on_area_input_event)


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
		pass
	elif event is InputEventScreenTouch and event.pressed:
		tapped.emit(self)
		pass


func set_textures(
	tex_straight: Texture2D,
	tex_tjunction: Texture2D,
	tex_corner_a: Texture2D,
	tex_cross: Texture2D,
	tex_roundabout: Texture2D,
	tex_corner_b: Texture2D,
	tex_corner_c: Texture2D,
	tex_deadend: Texture2D
) -> void:
	_tex_straight   = tex_straight
	_tex_tjunction  = tex_tjunction
	_tex_corner_a   = tex_corner_a
	_tex_cross      = tex_cross
	_tex_roundabout = tex_roundabout
	_tex_corner_b   = tex_corner_b
	_tex_corner_c   = tex_corner_c
	_tex_deadend    = tex_deadend

func assign(
	r: int,
	c: int,
	connection: int,
	_variant: int,
	_s_rot: int,
	p_visual_level: int,
	disp_tile: float,
	offset_x: float,
	offset_y: float
) -> void:
	row = r
	col = c
	conn = connection
	active = connection != 0
	_disp_tile = disp_tile

	
	var hv = r * 97 + c * 53 + p_visual_level * 17
	skin_variant = hv % 3
	skin_rot = int(hv / 3) % 2


	if _area:
		_area.input_pickable = active

	position = Vector2(
		offset_x + c * disp_tile + disp_tile * 0.5,
		offset_y + r * disp_tile + disp_tile * 0.5
	)

	_apply_visual()


func set_connection_instant(new_conn: int) -> void:
	if _rot_tween and _rot_tween.is_valid():
		_rot_tween.kill()

	conn = new_conn
	active = new_conn != 0

	if _area:
		_area.input_pickable = active

	_apply_visual()



func rotate_clockwise() -> void:
	if not active:
		return
	conn = rotate_bits(conn, 1)
	_animate_to(_get_visual(conn, skin_variant, skin_rot))


func _apply_visual() -> void:
	var visual := _get_visual(conn, skin_variant, skin_rot)
	if visual["texture"] == null:
		visible = false
		return
	visible = true
	texture = visual["texture"]
	var tex_size: Vector2 = texture.get_size()
	scale = Vector2(_disp_tile / tex_size.x, _disp_tile / tex_size.y)
	rotation_degrees = visual["rotation_deg"]


func _animate_to(visual: Dictionary) -> void:
	if visual["texture"] == null:
		visible = false
		return

	visible = true

	if texture != visual["texture"]:
		texture = visual["texture"]
		var tex_size := texture.get_size()
		scale = Vector2(_disp_tile / tex_size.x, _disp_tile / tex_size.y)

	if _rot_tween and _rot_tween.is_valid():
		_rot_tween.kill()

	var target := rotation_degrees + 90.0

	_rot_tween = create_tween()
	_rot_tween.tween_property(self, "rotation_degrees", target, 0.16)

	await _rot_tween.finished
	rotation_degrees = fposmod(visual["rotation_deg"], 360.0)



static func rotate_bits(v: int, times: int) -> int:
	var r := v
	var n := ((times % 4) + 4) % 4
	for i in range(n):
		var nr := 0
		if r & 1: nr |= 2
		if r & 2: nr |= 4
		if r & 4: nr |= 8
		if r & 8: nr |= 1
		r = nr
	return r


func _popcount(v: int) -> int: #returns the number of bits set to 1 in v for rotation detection
	var c := 0
	var vv := v
	while vv > 0:
		c += vv & 1
		vv >>= 1
	return c





func _find_rotation(base: int, target: int, max_k: int) -> int:
	for k in range(max_k):
		if rotate_bits(base, k) == target:
			return k
	return 0





func _corner_rotation(c: int, variant: int) -> float:
	match c:
		6:
			return 0.0 if variant != 1 else 180.0
		12:
			return 90.0 if variant != 1 else 270.0
		9:
			return 180.0 if variant != 1 else 0.0
		3:
			return 270.0 if variant != 1 else 90.0
		_:
			return 0.0






func _get_visual(v: int, skin_variant_: int = 0, skin_rot_: int = 0) -> Dictionary:
	if v == 0:
		return {
			"texture": null,
			"rotation_deg": 0.0
		}

	var pc := _popcount(v)

	# Cross / Roundabout
	if v == 15:
		return {
			"texture": _tex_cross if skin_rot_ == 0 else _tex_roundabout,
			"rotation_deg": 0.0
		}

	# Dead-end
	if pc == 1:
		var k := _find_rotation(BASE_DEAD, v, 4)
		return {
			"texture": _tex_deadend,
			"rotation_deg": float(k * 90)
		}

	# Straight / Corner
	if pc == 2:
		# Straight
		if v == 5 or v == 10:
			var k2 := _find_rotation(BASE_STRAIGHT, v, 2)
			return {
				"texture": _tex_straight,
				"rotation_deg": float(k2 * 90)
			}

		var variant := skin_variant_ % 3
		var corner_tex: Texture2D

		match variant:
			0:
				corner_tex = _tex_corner_a
			1:
				corner_tex = _tex_corner_b
			_:
				corner_tex = _tex_corner_c

		return {
			"texture": corner_tex,
			"rotation_deg": _corner_rotation(v, variant)
		}
	# T-junction
	if pc == 3:
		var k4 := _find_rotation(BASE_T, v, 4)
		return {
			"texture": _tex_tjunction,
			"rotation_deg": float(k4 * 90)
		}

	return {
		"texture": null,
		"rotation_deg": 0.0
	}


	
func animate_to_connection(target_conn: int) -> void:
	if _rot_tween and _rot_tween.is_valid():
		_rot_tween.kill()

	active = target_conn != 0

	if _area:
		_area.input_pickable = active

	var end_visual := _get_visual(target_conn, skin_variant, skin_rot)

	# Update texture if needed
	if texture != end_visual["texture"]:
		texture = end_visual["texture"]

		var tex_size: Vector2 = texture.get_size()
		scale = Vector2(_disp_tile / tex_size.x, _disp_tile / tex_size.y)

	# Random full spin
	var extra_spin: float = 360.0 * float(randi_range(0.1, 1))
	var target_angle: float = float(end_visual["rotation_deg"]) + extra_spin

	_rot_tween = create_tween()
	_rot_tween.set_trans(Tween.TRANS_CUBIC)
	_rot_tween.set_ease(Tween.EASE_OUT)

	_rot_tween.tween_property(
		self,
		"rotation_degrees",
		target_angle,
		0.9 + randf() * 0.4
	)

	await _rot_tween.finished

	conn = target_conn
	rotation_degrees = float(end_visual["rotation_deg"])