@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_tool_menu_item("Generate Fixed Pieces", generate)

func _exit_tree() -> void:
	remove_tool_menu_item("Generate Fixed Pieces")


func generate() -> void:

	print("========== START ==========")

	var level_data := load("res://Data/LevelData.tres") as LevelData

	if level_data == null:
		push_error("LevelData not found")
		return

	print("Total Levels :", level_data.level_data_list.size())

	for i in range(16,20):

		var level := level_data.level_data_list[i] as LevelDataSO

		if level == null:
			continue

		if level.grid_cols <= 0 or level.grid_rows <= 0:
			push_warning("Invalid Grid : Level %d" % i)
			continue

		var scene := load(level.LevelScene) as PackedScene

		if scene == null:
			push_warning("Scene Load Failed : %s" % level.LevelScene)
			continue

		var root := scene.instantiate()

		if root == null:
			continue

		var sprite := root.get_node_or_null("SlicingSprite") as Sprite2D

		if sprite == null:
			root.free()
			continue

		if sprite.texture == null:
			root.free()
			continue

		var image := sprite.texture.get_image()

		if image == null:
			root.free()
			continue

		var tile_w := image.get_width() / level.grid_cols
		var tile_h := image.get_height() / level.grid_rows

		if tile_w <= 0 or tile_h <= 0:
			root.free()
			continue

		var fixed_pieces: Array[int] = []

		for row in range(level.grid_rows):
			for col in range(level.grid_cols):

				var result := check_tile(
					image,
					col * tile_w,
					row * tile_h,
					tile_w,
					tile_h
				)

				var index := row * level.grid_cols + col

				if result.empty or result.visible_pixels <= 10:
					fixed_pieces.append(index)

		level.fixed_pieces = fixed_pieces

		print("Level", i, "Fixed Pieces:", fixed_pieces)

		root.free()

	var err := ResourceSaver.save(level_data)

	if err != OK:
		push_error("Save Failed : %s" % err)
	else:
		print("LevelData Saved")

	print("=========== DONE ===========")


func check_tile(
	image: Image,
	start_x: int,
	start_y: int,
	width: int,
	height: int
) -> Dictionary:

	var visible_pixels := 0
	var step := 4

	var end_x := mini(start_x + width, image.get_width())
	var end_y := mini(start_y + height, image.get_height())

	for y in range(start_y, end_y, step):
		for x in range(start_x, end_x, step):

			if x < 0 or y < 0:
				continue

			if x >= image.get_width() or y >= image.get_height():
				continue

			if image.get_pixel(x, y).a > 0.01:
				visible_pixels += 1

	return {
		"empty": visible_pixels == 0,
		"visible_pixels": visible_pixels
	}