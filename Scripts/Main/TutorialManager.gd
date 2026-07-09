extends CanvasLayer
class_name TutorialManager

@export var grid_area: Control

@export var label: Label
@export var hand: TextureRect

var hand_tween: Tween
var label_tween: Tween

@export var spotlight: ColorRect

var glow_tween: Tween

# FIX: track which tile(s) and hole(s) are currently highlighted, so
# _on_spotlight_gui_input() can hit-test a click against them and forward
# the tap manually — this is how we let clicks work ONLY inside the hole.
var _focused_tile1: TileRenderer = null
var _focused_tile2: TileRenderer = null
var _hole1_pos: Vector2 = Vector2(-1000, -1000)
var _hole1_radius: float = 0.0
var _hole2_pos: Vector2 = Vector2(-1000, -1000)
var _hole2_radius: float = 0.0


func _ready() -> void:
	if spotlight and not spotlight.gui_input.is_connected(_on_spotlight_gui_input):
		spotlight.gui_input.connect(_on_spotlight_gui_input)


func _on_spotlight_gui_input(event: InputEvent) -> void:
	var is_press: bool = (
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		or (event is InputEventScreenTouch and event.pressed)
	)			

	if not is_press:
		return

	# event.position here is local to `spotlight` (a Control), so convert
	# to the same global/canvas space our hole centers are stored in.
	var click_pos: Vector2 = spotlight.get_global_transform_with_canvas() * event.position

	if _focused_tile1 and click_pos.distance_to(_hole1_pos) <= _hole1_radius:
		spotlight.accept_event()
		_focused_tile1.tapped.emit(_focused_tile1)
		return

	if _focused_tile2 and click_pos.distance_to(_hole2_pos) <= _hole2_radius:
		spotlight.accept_event()
		_focused_tile2.tapped.emit(_focused_tile2)
		return

	# FIX: click landed on the black overlay itself (outside every hole).
	# Explicitly accept/consume it so it does absolutely nothing — no tile
	# tap, no fall-through, no side effect of any kind.
	spotlight.accept_event()


func _sync_spotlight_to_grid_area() -> void:
	
	spotlight.mouse_filter = Control.MOUSE_FILTER_STOP

	if hand:
		hand.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tiles: Array[TileRenderer] = []
	for child in grid_area.get_children():
		if child is TileRenderer:
			tiles.append(child)

	if tiles.is_empty():
		
		spotlight.global_position = grid_area.global_position
		spotlight.size = grid_area.size
		return

	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)

	for t in tiles:
		var origin: Vector2 = t.get_global_transform_with_canvas().origin
		var half := Vector2(t._disp_tile, t._disp_tile) * 0.5

		var tile_min := origin - half
		var tile_max := origin + half

		min_pos.x = min(min_pos.x, tile_min.x)
		min_pos.y = min(min_pos.y, tile_min.y)
		max_pos.x = max(max_pos.x, tile_max.x)
		max_pos.y = max(max_pos.y, tile_max.y)

	spotlight.global_position = min_pos
	spotlight.size = max_pos - min_pos

func start_tile_glow(tile: TileRenderer) -> void:
	if glow_tween:
		glow_tween.kill()

	tile.self_modulate = Color.WHITE
	tile.scale = Vector2.ONE

	glow_tween = create_tween()
	glow_tween.set_loops()

	# Glow In
	glow_tween.parallel().tween_property(
		tile,
		"self_modulate",
		Color(1.0, 1.0, 0.7, 1.0),
		0.5
	)

	glow_tween.parallel().tween_property(
		tile,
		"scale",
		Vector2(1.08, 1.08),
		0.5
	)

	# Glow Out
	glow_tween.parallel().tween_property(
		tile,
		"self_modulate",
		Color.WHITE,
		0.5
	)

	glow_tween.parallel().tween_property(
		tile,
		"scale",
		Vector2.ONE,
		0.5
	)


func stop_tile_glow(tile: TileRenderer) -> void:
	if glow_tween:
		glow_tween.kill()

	tile.self_modulate = Color.WHITE
	tile.scale = Vector2.ONE
func start_two_tile_animation(pos1: Vector2) -> void:
	if hand_tween:
		hand_tween.kill()

	hand.visible = true
	hand.scale = Vector2.ONE
	hand.rotation_degrees = 0
	hand.global_position = pos1

	hand_tween = create_tween()
	hand_tween.set_loops()

	# Tap tile
	hand_tween.tween_property(hand, "scale", Vector2(0.9, 0.9), 0.12)
	hand_tween.parallel().tween_property(hand, "rotation_degrees", 10, 0.12)
	hand_tween.tween_property(hand, "scale", Vector2.ONE, 0.12)
	hand_tween.parallel().tween_property(hand, "rotation_degrees", 0, 0.12)

	hand_tween.tween_interval(0.4)


func start_tutorial_animation() -> void:
	if hand_tween:
		hand_tween.kill()

	# FIX: use global_position consistently (matches what focus_tile() sets
	# right before calling this). Mixing .position and .global_position
	# was causing the hand to jump / animate from the wrong spot whenever
	# the hand's parent node had any offset relative to the CanvasLayer root.
	var tap_pos := hand.global_position
	var start_pos := tap_pos + Vector2(0, 250) # নিচ থেকে শুরু

	hand.global_position = start_pos
	hand.scale = Vector2.ONE
	hand.rotation_degrees = 0

	hand_tween = create_tween()
	hand_tween.set_loops()

	hand_tween.tween_property(
		hand,
		"global_position",
		tap_pos,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Tap (press)
	hand_tween.parallel().tween_property(
		hand,
		"scale",
		Vector2(0.9, 0.9),
		0.12
	)

	hand_tween.parallel().tween_property(
		hand,
		"rotation_degrees",
		10,
		0.12
	)

	# Tap release
	hand_tween.tween_property(
		hand,
		"scale",
		Vector2.ONE,
		0.12
	)

	hand_tween.parallel().tween_property(
		hand,
		"rotation_degrees",
		0,
		0.12
	)

	hand_tween.tween_interval(0.4)

	hand_tween.tween_property(
		hand,
		"global_position",
		start_pos,
		0.4
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	hand_tween.tween_interval(0.2)


var typing_tween: Tween

func type_text(text: String, speed := 0.05) -> void:
	if typing_tween:
		typing_tween.kill()

	label.text = ""
	label.visible_characters = 0
	label.text = text

	typing_tween = create_tween()

	for i in range(text.length()):
		typing_tween.tween_property(
			label,
			"visible_characters",
			i + 1,
			speed
		)


func stop_tutorial(glowing_tile: TileRenderer = null) -> void:
	# Kill all running tweens so nothing keeps animating in the background
	if hand_tween:
		hand_tween.kill()
	if label_tween:
		label_tween.kill()
	if glow_tween:
		glow_tween.kill()
	if typing_tween:
		typing_tween.kill()

	# Hide overlay elements
	spotlight.visible = false
	hand.visible = false
	label.visible = false

	# Reset shader holes so nothing lingers if spotlight is shown again later
	var mat := spotlight.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("hole1", Vector2(-1000, -1000))
		mat.set_shader_parameter("hole2", Vector2(-1000, -1000))

	# Reset hand transform so it doesn't carry stale scale/rotation into next use
	hand.scale = Vector2.ONE
	hand.rotation_degrees = 0

	# Reset label typing state
	label.text = ""
	label.visible_characters = 0

	# If a tile was mid-glow, snap it back to normal (glow_tween.kill() alone
	# leaves self_modulate/scale wherever the tween last was)
	if glowing_tile:
		glowing_tile.self_modulate = Color.WHITE
		glowing_tile.scale = Vector2.ONE

	# FIX: clear hit-test tracking so no stale tile keeps receiving forwarded
	# taps after the tutorial has been hidden.
	_focused_tile1 = null
	_focused_tile2 = null
	_hole1_pos = Vector2(-1000, -1000)
	_hole1_radius = 0.0
	_hole2_pos = Vector2(-1000, -1000)
	_hole2_radius = 0.0


func focus_tile(tile: TileRenderer) -> void:
	spotlight.visible = true
	_sync_spotlight_to_grid_area()

	var mat := spotlight.material as ShaderMaterial
	if mat == null:
		push_error("Spotlight has no ShaderMaterial!")
		return


	var center := tile.get_global_transform_with_canvas().origin


	mat.set_shader_parameter("viewport_size", get_viewport().get_visible_rect().size)

	mat.set_shader_parameter("hole1", center)
	mat.set_shader_parameter("radius1", tile._disp_tile * 0.55)

	mat.set_shader_parameter("hole2", Vector2(-1000, -1000))

	
	_focused_tile1 = tile
	_hole1_pos = center
	_hole1_radius = tile._disp_tile * 0.55
	_focused_tile2 = null
	_hole2_pos = Vector2(-1000, -1000)
	_hole2_radius = 0.0

	hand.visible = true
	hand.global_position = center + Vector2(40, -35)

	label.visible = true
	label.text = "Tap the highlighted\nroad to rotate."

	label.reset_size()
	label.global_position = Vector2(
		grid_area.global_position.x + (grid_area.size.x - label.size.x) * 0.5,
		grid_area.global_position.y + grid_area.size.y + 20
	)

	start_tutorial_animation()
	type_text(label.text)

func focus_tiles(tile1: TileRenderer) -> void:
	spotlight.visible = true
	_sync_spotlight_to_grid_area()

	var mat := spotlight.material as ShaderMaterial
	if mat == null:
		push_error("Spotlight has no ShaderMaterial!")
		return

	mat.set_shader_parameter("viewport_size", get_viewport().get_visible_rect().size)

	var center1 := tile1.get_global_transform_with_canvas().origin
	mat.set_shader_parameter("hole1", center1)
	mat.set_shader_parameter("radius1", tile1._disp_tile * 0.55)

	

	_focused_tile1 = tile1
	_hole1_pos = center1
	_hole1_radius = tile1._disp_tile * 0.55
	

	hand.visible = true
	hand.global_position = center1 + Vector2(40, -35)

	label.visible = true
	label.text = "Tap the highlighted\nroad to rotate."

	label.reset_size()
	label.global_position = Vector2(
		grid_area.global_position.x + (grid_area.size.x - label.size.x) * 0.5,
		grid_area.global_position.y + grid_area.size.y + 20
	)

	start_tutorial_animation()
	type_text(label.text)

	start_two_tile_animation(center1 + Vector2(40, -35)
		)

	type_text(label.text)


func hide_tutorial(glowing_tile: TileRenderer = null) -> void:
	# Kill all running tweens so nothing keeps animating in the background
	if hand_tween:
		hand_tween.kill()
	if label_tween:
		label_tween.kill()
	if glow_tween:
		glow_tween.kill()
	if typing_tween:
		typing_tween.kill()

	# Hide overlay elements
	spotlight.visible = false
	hand.visible = false
	label.visible = false

	# Reset shader holes so nothing lingers if spotlight is shown again later
	var mat := spotlight.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("hole1", Vector2(-1000, -1000))
		mat.set_shader_parameter("hole2", Vector2(-1000, -1000))

	# Reset hand transform so it doesn't carry stale scale/rotation into next use
	hand.scale = Vector2.ONE
	hand.rotation_degrees = 0

	# Reset label typing state
	label.text = ""
	label.visible_characters = 0

	# If a tile was mid-glow, snap it back to normal (glow_tween.kill() alone
	# leaves self_modulate/scale wherever the tween last was)
	if glowing_tile:
		glowing_tile.self_modulate = Color.WHITE
		glowing_tile.scale = Vector2.ONE

	# Clear hit-test tracking so no stale tile keeps receiving forwarded
	# taps after the tutorial has been hidden.
	_focused_tile1 = null
	_focused_tile2 = null
	_hole1_pos = Vector2(-1000, -1000)
	_hole1_radius = 0.0
	_hole2_pos = Vector2(-1000, -1000)
	_hole2_radius = 0.0
