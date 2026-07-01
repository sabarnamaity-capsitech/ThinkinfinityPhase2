extends Node2D
class_name CutSlice

var area: Area2D
var collision_shape :CollisionShape2D
var instance: CutSlice


func all_done() -> void:
	for child in get_children():
		if child is Area2D:
			area = child
			break

	if area == null:
		print("Area2D not found!")
		return

	print("Found Area: ", area.name)

	collision_shape = area.get_child(0) as CollisionShape2D
	print("Found Collision: ", collision_shape.name)

	area.input_event.connect(func(_viewport, event, _shape_idx):on_piece_clicked(event))
	

	

func on_piece_clicked(event: InputEvent) -> void:
	if GameManager.instance.level_generator.game_finished:
		return

	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	collision_shape.disabled = true
	var target_rotation = rotation_degrees + 90
	GameManager.instance.level_generator.set_all_piece_colliders(false)
	SoundManager.play_rotate()
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", target_rotation, 0.15)
	
	GameManager.instance.level_generator.move_count += 1

	await tween.finished
	collision_shape.disabled = false
	rotation_degrees = fmod(rotation_degrees, 360.0)
	GameManager.instance.level_generator.set_all_piece_colliders(true)
	GameManager.instance.level_generator.check_win()
