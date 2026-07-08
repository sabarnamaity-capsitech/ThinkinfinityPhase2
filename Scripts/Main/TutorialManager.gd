extends CanvasLayer
class_name TutorialManager

@export var grid_area: Control

@export var top_rect: ColorRect
@export var bottom_rect: ColorRect
@export var left_rect: ColorRect
@export var right_rect: ColorRect

@export var label: Label
@export var hand: TextureRect

var hand_tween: Tween
var label_tween: Tween


func focus_tile(tile: TileRenderer) -> void:

	visible = true

	top_rect.visible = true
	bottom_rect.visible = true
	left_rect.visible = true
	right_rect.visible = true

	var grid_pos = grid_area.global_position
	var grid_size = grid_area.size

	var size = tile._disp_tile
	var pos = tile.global_position

	var half = size * 0.5

	# ---------- Spotlight ----------

	top_rect.position = grid_pos
	top_rect.size = Vector2(
		grid_size.x,
		max(0.0, pos.y - half - grid_pos.y)
	)

	bottom_rect.position = Vector2(
		grid_pos.x,
		pos.y + half
	)
	bottom_rect.size = Vector2(
		grid_size.x,
		max(0.0, grid_pos.y + grid_size.y - (pos.y + half))
	)

	left_rect.position = Vector2(
		grid_pos.x,
		pos.y - half
	)
	left_rect.size = Vector2(
		max(0.0, pos.x - half - grid_pos.x),
		size
	)

	right_rect.position = Vector2(
		pos.x + half,
		pos.y - half
	)
	right_rect.size = Vector2(
		max(0.0, grid_pos.x + grid_size.x - (pos.x + half)),
		size
	)

	# ---------- Hand ----------

	hand.visible = true
	hand.global_position = pos + Vector2(40, -35)

	# ---------- Label ----------

	label.visible = true
	label.text = "Tap the highlighted\nroad to rotate."

	label.reset_size()

	label.global_position = Vector2(
		grid_pos.x + (grid_size.x - label.size.x) * 0.5,
		grid_pos.y + grid_size.y + 20
	)

	start_tutorial_animation()
	type_text("Tap the highlighted\nroad to rotate.", 0.05)



func start_tutorial_animation() -> void:

	if hand_tween:
		hand_tween.kill()

	var tap_pos := hand.position
	var start_pos := tap_pos + Vector2(0, 250) # নিচ থেকে শুরু

	hand.position = start_pos
	hand.scale = Vector2.ONE
	hand.rotation_degrees = 0

	hand_tween = create_tween()
	hand_tween.set_loops()

	
	hand_tween.tween_property(
		hand,
		"position",
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
		"position",
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


func hide_tutorial() -> void:

	top_rect.visible = false
	bottom_rect.visible = false
	left_rect.visible = false
	right_rect.visible = false

	hand.visible = false
	label.visible = false

	if hand_tween:
		hand_tween.kill()

	if label_tween:
		label_tween.kill()
