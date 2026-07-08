extends Node2D
class_name LevelGenerator


@export var TEX_CAR : Texture2D

const UP    := 1
const RIGHT := 2
const DOWN  := 4
const LEFT  := 8

@export var tile_scene : PackedScene
@export var grid_area : Control
@export var car_controller: CarController

@export_group("Gameplay")
@export var car_speed: float = 200.0

@export_group("Effects")
@export var winConfetti1: GPUParticles2D
@export var winConfetti2: GPUParticles2D
@export var smoke: GPUParticles2D

@export_group("Tile Textures")
@export var _tex_straight : Texture2D
@export var _tex_tjunction: Texture2D
@export var _tex_corner_a : Texture2D
@export var _tex_cross : Texture2D
@export var _tex_roundabout : Texture2D
@export var _tex_corner_b : Texture2D
@export var _tex_corner_c : Texture2D
@export var _tex_deadend: Texture2D

@onready var tiles_container: Node2D = $TilesContainer

var levels_played_this_session := 0
var all_levels_loder : Dictionary = {}
var level_index : int = 0
var current_level_json: Dictionary = {}

var rows: int
var cols: int
var current_grid: Array = []    
var solution_grid: Array = []   
var skin_variants: Array = []  
var skin_rots: Array = []      

var grid_sprites: Array = []    
var marker_nodes: Array = []
var car_sprite: Sprite2D = null
var driving: bool = false

var offset_x: float = 0.0
var offset_y: float = 0.0
var disp_tile: float = 0.0

var completed: bool = false

var move_count: int = 0
var time_left: float
var timer_warning_started: bool = false
var timer_started := false
var game_finished := false

@export var tutorial: TutorialManager

func _ready() -> void:
	all_levels_loder = GameManager.instance.all_levels
	GameManager.instance.current_level=level_index


func _process(delta: float) -> void:
	update_timer(delta)



func load_level(level_number: int) -> void:
	if !all_levels_loder.has(level_number):
		push_error("Level not found: %d" % level_number)
		return

	completed = false
	driving = false
	game_finished = false
	timer_started = false
	timer_warning_started = false
	move_count = 0

	_clear_grid()

	level_index = level_number
	current_level_json = all_levels_loder[level_number]
	GameManager.instance.current_level_json = current_level_json
	GameManager.instance.current_level=level_index
	rows = int(current_level_json["rows"])
	cols = int(current_level_json["cols"])

	await get_tree().process_frame

	_build_grid_data()
	_layout_and_spawn_sprites()
	
	_spawn_markers()
	_spawn_car()

	print("Grid Ready:", rows, "x", cols, " Cell:", disp_tile)
	_callAfterFullLoad1()
	


func _clear_grid() -> void:
	for row in grid_sprites:
		for s in row:
			if is_instance_valid(s):
				s.queue_free()
	grid_sprites.clear()

	for m in marker_nodes:
		if is_instance_valid(m):
			m.queue_free()
	marker_nodes.clear()

	if is_instance_valid(car_sprite):
		car_sprite.queue_free()
	car_sprite = null


func _build_grid_data() -> void:
	solution_grid = []
	current_grid = []
	skin_variants = []
	skin_rots = []

	for r in range(rows):
		var srow: Array = []
		var crow: Array = []
		var skrow: Array = []
		var skrrow: Array = []
		for c in range(cols):
			srow.append(int(current_level_json["solution"][r][c]))
			crow.append(int(current_level_json["cells"][r][c]))
			var h = (r * 928371 + c * 12977 + level_index * 37) % 100
			
			var variant := 0
			if h >= 90:
				variant = 2
			elif h >= 80:
				variant = 1
			skrow.append(variant)
			var hr = (r * 55317 + c * 91013 + level_index * 71) % 4
			skrrow.append(hr)
		solution_grid.append(srow)
		current_grid.append(crow)
		skin_variants.append(skrow)
		skin_rots.append(skrrow)

func _layout_and_spawn_sprites() -> void:
	var available_width: float = grid_area.size.x
	var available_height: float = grid_area.size.y
	var padding := 10.0

	disp_tile = floor(
		min(
			(available_width - padding * 2.0) / cols,
			(available_height - padding * 2.0) / rows
		)
	)

	var total_w: float = disp_tile * cols
	var total_h: float = disp_tile * rows


	tiles_container.global_position = grid_area.global_position

	
	offset_x = (available_width - total_w) * 0.5
	offset_y = (available_height - total_h) * 0.5

	grid_sprites.clear()

	for r in range(rows):
		var srow: Array = []

		for c in range(cols):
			var tile: TileRenderer = tile_scene.instantiate()
			tile.name = "Tile_%d_%d" % [r, c]

			tiles_container.add_child(tile)

			tile.set_textures(
				_tex_straight,
				_tex_tjunction,
				_tex_corner_a,
				_tex_cross,
				_tex_roundabout,
				_tex_corner_b,
				_tex_corner_c,
				_tex_deadend
			)

			tile.assign(
				r,
				c,
				current_grid[r][c],
				0,
				0,
				current_level_json["old_level"],
				disp_tile,
				offset_x,
				offset_y
			)

			tile.tapped.connect(_on_tile_tapped)
			srow.append(tile)

		grid_sprites.append(srow)


func _callAfterFullLoad1() -> void:
	UiManager.instance.show_screen(UiManager.Screen_Type.GAME)

	timer_started = false

	# Show solved board
	for r in range(rows):
		for c in range(cols):
			grid_sprites[r][c].set_connection_instant(solution_grid[r][c])

	await get_tree().create_timer(1.2).timeout

	# Collect all tiles
	var all_tiles: Array[TileRenderer] = []

	for r in range(rows):
		for c in range(cols):
			all_tiles.append(grid_sprites[r][c])

	# Animate in batches (1 -> 2 -> 3 -> 4)
	var index := 0
	var batch_size := 1

	while index < all_tiles.size():

		for i in range(batch_size):
			if index >= all_tiles.size():
				break

			var tile := all_tiles[index]

			tile.animate_to_connection(
				current_grid[tile.row][tile.col]
			)

			index += 1

		batch_size += 1
		if batch_size > 4:
			batch_size = 1

		await get_tree().create_timer(0.05).timeout

	# Wait for last animations
	await get_tree().create_timer(1.4).timeout

	start_level_timer()
	_animate_grid_wave()
	var start = _start_cell()
	tutorial.focus_tile(grid_sprites[start.x][start.y])

	
func _callAfterFullLoad() -> void:
	UiManager.instance.show_screen(UiManager.Screen_Type.GAME)
	# _animate_grid_wave()
	start_level_timer()
	_animate_grid_wave()




func _cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(
		offset_x + cell.y * disp_tile + disp_tile / 2,
		offset_y + cell.x * disp_tile + disp_tile / 2
	)


func _start_cell() -> Vector2i:
	var s : Array = current_level_json.get("start", [-1, -1])
	return Vector2i(int(s[0]), int(s[1]))


func _end_cell() -> Vector2i:
	var e : Array = current_level_json.get("end", [-1, -1])
	return Vector2i(int(e[0]), int(e[1]))


func _spawn_markers() -> void:
	_spawn_marker(_start_cell(), Color(0.18, 0.75, 0.25), "S")
	_spawn_marker(_end_cell(), Color(0.85, 0.20, 0.20), "E")
	


func _spawn_marker(cell: Vector2i, col: Color, letter: String) -> void:
	var d = max(20, int(disp_tile * 0.30))
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for px in range(64):
		for py in range(64):
			var dx = px - 32
			var dy = py - 32
			var dist = sqrt(float(dx * dx + dy * dy))
			if dist <= 26.0:
				img.set_pixel(px, py, col)
			elif dist <= 30.0:
				img.set_pixel(px, py, Color(1, 1, 1))
	var sp = Sprite2D.new()
	sp.texture = ImageTexture.create_from_image(img)
	sp.scale = Vector2(float(d) / 64.0, float(d) / 64.0)
	sp.position = _cell_to_pos(cell) - Vector2(disp_tile * 0.32, disp_tile * 0.32)
	sp.z_index = 10
	tiles_container.add_child(sp)
	marker_nodes.append(sp)

	var lbl = Label.new()
	lbl.text = letter
	lbl.add_theme_font_size_override("font_size", max(12, int(d * 0.55)))
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.position = sp.position - Vector2(d * 0.28, d * 0.42)
	lbl.z_index = 11
	tiles_container.add_child(lbl)
	marker_nodes.append(lbl)

func _animate_grid_wave() -> void:
	for r in range(rows):
		for c in range(cols):
			var tile: TileRenderer = grid_sprites[r][c]

			var original_scale := tile.scale

			tile.scale = original_scale * 0.8
			tile.modulate = Color(0.85, 0.85, 0.85, 1.0) # Slightly dim

			var tween := create_tween()

			# Scale up
			tween.parallel().tween_property(
				tile,
				"scale",
				original_scale * 1.15,
				0.50
			)\
			.set_delay((r + c) * 0.09)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)

			# Color brighten
			tween.parallel().tween_property(
				tile,
				"modulate",
				Color(1.1, 1.1, 1.1, 1.0),
				0.45
			)\
			.set_delay((r + c) * 0.09)

			# Return scale
			tween.tween_property(
				tile,
				"scale",
				original_scale,
				0.15
			)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

			# Return color
			tween.parallel().tween_property(
				tile,
				"modulate",
				Color.WHITE,
				0.20
			)

func _spawn_car() -> void:
	car_sprite = Sprite2D.new()
	car_sprite.texture = TEX_CAR
	var tex_size: Vector2 = car_sprite.texture.get_size()*2.5
	var target_w = disp_tile * 0.82
	var s = target_w / max(tex_size.x, tex_size.y)
	car_sprite.scale = Vector2(s, s)
	car_sprite.z_index = 20
	car_sprite.position = _cell_to_pos(_start_cell())
	car_sprite.rotation_degrees = 0.0
	tiles_container.add_child(car_sprite)


func _dir_rotation(a: Vector2i, b: Vector2i) -> float:
	var dr = b.x - a.x
	var dc = b.y - a.y
	if dc == 1:
		return 0.0    # East
	if dr == 1:
		return 90.0   # South
	if dc == -1:
		return 180.0  # West
	return 270.0          # North


func _compute_path() -> Array:
	var start = _start_cell()
	var goal = _end_cell()
	var visited = {start: true}
	var parent = {}
	var queue: Array = [start]
	var dirs = [
		{"bit": 1, "dr": -1, "dc": 0, "opp": 4},
		{"bit": 2, "dr": 0, "dc": 1, "opp": 8},
		{"bit": 4, "dr": 1, "dc": 0, "opp": 1},
		{"bit": 8, "dr": 0, "dc": -1, "opp": 2},
	]
	while queue.size() > 0:
		var cur: Vector2i = queue.pop_front()
		if cur == goal:
			break
		var cur_val: int = solution_grid[cur.x][cur.y]
		for d in dirs:
			if cur_val & int(d["bit"]) == 0:
				continue
			var nr = cur.x + int(d["dr"])
			var nc = cur.y + int(d["dc"])
			if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
				continue
			var nb = Vector2i(nr, nc)
			if visited.has(nb):
				continue
			var nb_val: int = solution_grid[nr][nc]
			if nb_val & int(d["opp"]) == 0:
				continue
			visited[nb] = true
			parent[nb] = cur
			queue.append(nb)

	var path: Array = []
	if not visited.has(goal):
		return path
	var node = goal
	while node != start:
		path.push_front(node)
		node = parent[node]
	path.push_front(start)
	print("start =", start)
	print("goal =", goal)
	print("path =", path)
	return path

func _drive_car_then_finish() -> void:
	driving = true

	var path: Array = _compute_path()
	if path.size() < 2:
		driving = false
		_on_win_sequence_finished()
		return

	const ROT_OFFSET := PI / 2.0
	const CAR_SPEED := 401.0

	var points: Array = []
	for cell in path:
		points.append(_cell_to_pos(cell))

	car_sprite.position = points[0]
	car_sprite.rotation = (points[1] - points[0]).angle() + ROT_OFFSET
	car_sprite.z_index = 20

	var tw := create_tween()
	tw.set_parallel(false)

	var prev_rot := car_sprite.rotation

	for i in range(1, points.size()):
		var from_pos: Vector2 = points[i - 1]
		var to_pos: Vector2 = points[i]
		var dir_vec: Vector2 = to_pos - from_pos

		var distance := dir_vec.length()
		if distance < 0.001:
			continue

		var seg_time := distance / CAR_SPEED

		var raw_rot := dir_vec.angle() + ROT_OFFSET
		var target_rot := prev_rot + wrapf(raw_rot - prev_rot, -PI, PI)

		
		tw.tween_property(
			car_sprite,
			"rotation",
			target_rot,
			min(seg_time, 0.12)
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		tw.parallel().tween_property(
			car_sprite,
			"position",
			to_pos,
			seg_time
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		prev_rot = target_rot

	tw.finished.connect(func():
		driving = false
		_on_win_sequence_finished()
	)

func _on_tile_tapped(tile: TileRenderer) -> void:
	if completed or driving or not timer_started:
		return

	move_count += 1
	SoundManager.play_click()
	tile.rotate_clockwise()
	current_grid[tile.row][tile.col] = tile.conn
	if _check_win():
		game_win()


func _check_win() -> bool:
	for r in range(rows):
		for c in range(cols):
			if current_grid[r][c] != solution_grid[r][c]:
				return false
	return true



func solve_level() -> void:
	if completed or driving:
		return
	for r in range(rows):
		for c in range(cols):
			if current_grid[r][c] == solution_grid[r][c]:
				continue
			current_grid[r][c] = solution_grid[r][c]
			var tile: TileRenderer = grid_sprites[r][c]
			tile.set_connection_instant(solution_grid[r][c])
	game_win()




func start_level_timer() -> void:
	time_left = float(current_level_json.get("time_limit", 30.0))
	timer_started = true
	timer_warning_started = false
	game_finished = false


func update_timer(delta: float) -> void:
	if game_finished or completed or not timer_started:
		return

	time_left -= delta
	UiManager.instance.ui_callback.update_timer_ui(time_left)

	if time_left <= 5 and not timer_warning_started:
		timer_warning_started = true
		SoundManager.play_timer()

	if time_left <= 0.0:
		time_left = 0.0
		game_finished = true
		timer_started = false
		print("GAME OVER")

		Crashlytics.set_level(level_index)
		Analytics.level_failed(level_index)
		SoundManager.stop_timerPlay()
		SoundManager.play_game_over()
		UiManager.instance.show_popup(PopupManager.PopupType.LOSE)


func pause_game() -> void:
	UiManager.instance.show_popup(PopupManager.PopupType.PAUSE)
	timer_started = false


func stop_game() -> void:
	timer_started = false
	UiManager.instance.hide_popup()
	GameManager.instance.save_data()


func resume_game() -> void:
	UiManager.instance.hide_popup()
	timer_started = true
	if timer_warning_started:
		SoundManager.play_timer()


func restart() -> void:
	Analytics.level_retry(level_index)
	UiManager.instance.hide_popup()
	load_level(level_index)


func nextLevel() -> void:
	if level_index + 1 >= all_levels_loder.size():
		print("No next level")
		SoundManager.play_click()
		stop_game()
		return

	levels_played_this_session += 1

	if levels_played_this_session >= 4:
		levels_played_this_session = 0
		if AdMob.is_interstitial_available():
			print("Showing Interstitial")
			AdMob.interstitial_ad_dismissed.connect(
				_on_next_level_interstitial_closed,
				CONNECT_ONE_SHOT
			)
			AdMob.show_interstitial()
			return

	_advance_to_next_level()


func _on_next_level_interstitial_closed() -> void:
	_advance_to_next_level()


func _advance_to_next_level() -> void:
	load_level(GameManager.instance.current_level + 1)


func game_win() -> void:
	completed = true
	timer_started = false
	print("Moves: ", move_count)
	print("Time Left: ", snapped(time_left, 0.01))
	_drive_car_then_finish()


func _on_win_sequence_finished() -> void:
	Analytics.level_complete(level_index, calculate_stars())
	GameManager.instance.save_level_result(level_index, calculate_stars())
	SoundManager.play_win()
	if winConfetti1:
		winConfetti1.emitting = true
	if winConfetti2:
		winConfetti2.emitting = true
	UiManager.instance.show_popup(PopupManager.PopupType.WIN)
	GameManager.instance.unlock_level(GameManager.instance.current_level + 1)
	GameManager.instance.save_data()


func calculate_stars() -> int:
	var total_time: float = float(current_level_json.get("time_limit", 30.0))
	var stars := 1
	var time_percent := time_left / total_time
	if time_percent >= 0.5:
		stars += 1
	if time_percent >= 0.8:
		stars += 2
	return clamp(stars, 1, 3)
