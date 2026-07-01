extends Node2D
class_name LevelGenerator

# =========================
# CONSTANTS
# =========================

const ROTATIONS := [90, 180, 270]
const LEVELS_JSON_PATH := "res://levels/"

var levels_played_this_session := 0

@export var tile_scene : PackedScene
@export var grid_area : Control

@export var dead_end : Texture2D
@export var straight : Texture2D
@export var corner : Texture2D
@export var t : Texture2D
@export var cross : Texture2D
@export var circle : Texture2D

var cell_size : float = 64.0
@export var level_index: int = 0
@export var car_controller: CarController

@export_group("Gameplay")
@export var start_time: float
@export var car_speed: float = 200.0
@export var travel_time := 3.0

@export_group("Visual")
@export var puzzle_screen_ratio: float = 0.75
@export var car_scale_multiplier: float = 0.2

@export_group("Effects")
@export var winConfetti1: GPUParticles2D
@export var winConfetti2: GPUParticles2D
@export var smoke: GPUParticles2D
@export var slice_Cut: String
var actual_size: Vector2



## All levels loaded from levels.json at startup
var all_levels_json: Array = []

## The JSON data for the currently active level
var current_level_json: Dictionary = {}


var move_count: int = 0
var time_left: float
var timer_warning_started: bool = false
var timer_started := false
var game_finished := false
var car_moving := false

var scale_factor := 1.0
var all_levels_loder : Dictionary = {}

var grid : Array = []
var rows : int
var cols : int



func _ready() -> void:
	all_levels_loder=GameManager.instance.all_levels
	GameManager.instance.current_level_json=current_level_json
	level_index = GameManager.instance.current_level


func clear_grid() -> void:
	for child in grid_area.get_children():
		child.queue_free()

	grid.clear()


func load_level(level_number: int) -> void:
	clear_grid()

	if !all_levels_loder.has(level_number):
		push_error("Level not found: %d" % level_number)
		return

	level_index = level_number
	current_level_json = all_levels_loder[level_number]

	var data : Dictionary = current_level_json

	rows = int(data["rows"])
	cols = int(data["cols"])

	var cells : Array = data["cells"]

	await get_tree().process_frame

	var available_width : float = grid_area.size.x
	var available_height : float = grid_area.size.y

	var padding := 10.0

	cell_size = floor(
		min(
			(available_width - padding * 2.0) / cols,
			(available_height - padding * 2.0) / rows
		)
	)

	var total_width : float = cols * cell_size
	var total_height : float = rows * cell_size

	var offset_x : float = (available_width - total_width) * 0.5
	var offset_y : float = (available_height - total_height) * 0.5

	grid.clear()

	for r in range(rows):
		var row_tiles : Array = []

		for c in range(cols):
			var conn : int = int(cells[r][c])

			var tile : Tile = tile_scene.instantiate()

			grid_area.add_child(tile)

			tile.setup(
				r,
				c,
				conn != 0,
				conn,
				cell_size,
				dead_end,
				straight,
				corner,
				t,
				cross,
				circle
			)

			# Use Control position, not Node2D transform
			tile.position = Vector2(
				offset_x + c * cell_size,
				offset_y + r * cell_size
			)

			row_tiles.append(tile)

		grid.append(row_tiles)

	print("Grid Ready:",rows, "x", cols," Cell:", cell_size)
	_callAfterFullLoad()


func _callAfterFullLoad() -> void:
	# UIController.instance.switch_screen(ScreenType.Screen.GAME_HUD)
	UiManager.instance.show_screen(UiManager.Screen_Type.GAME)
	start_level_timer()




func _process(delta: float) -> void:
	update_timer(delta)


func start_level_timer() -> void:
	print(typeof(current_level_json))
	print(current_level_json)
	print(current_level_json.keys())

	time_left = float(current_level_json["time_limit"])
	timer_started = true

func update_timer(delta: float) -> void:
	if game_finished or not timer_started:
		return

	time_left -= delta
	# UIController.instance.ui_callback.update_timer_ui(time_left)
	UiManager.instance.ui_callback.update_timer_ui(time_left)

	if time_left <= 5 and not timer_warning_started:
		timer_warning_started = true
		SoundManager.play_timer()

	if time_left <= 0.0:
		time_left = 0.0
		game_finished = true
		print("GAME OVER")

		Crashlytics.set_level(level_index)
		Analytics.level_failed(level_index)
		SoundManager.stop_timerPlay()
		SoundManager.play_game_over()
		UIController.instance.show_popup(ScreenType.popup.LOSE_POPUP)






func pause_game() -> void:
	# if timer_warning_started:
		# SoundManager.stop_timerPlay()
	UIController.instance.show_popup(ScreenType.popup.PAUSE_POPUP)
	timer_started = false


func stop_game() -> void:
	timer_started = false
	UIController.instance.close_popup()
	GameManager.instance.save_data()


func resume_game() -> void:
	UIController.instance.close_popup()
	timer_started = true
	if timer_warning_started:
		SoundManager.play_timer()




func restart() -> void:
	Analytics.level_retry(level_index)
	#loadLevel(GameManager.instance.current_level)
	UIController.instance.close_popup()


func nextLevel() -> void:
	if level_index + 1 >= all_levels_json.size():
		print("No next level")
		SoundManager.play_click()
		UIController.instance.switch_screen(ScreenType.Screen.MAIN_MENU)
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

	
	GameManager.instance.unlock_level(GameManager.instance.current_level + 1)


func _on_next_level_interstitial_closed() -> void:
	
	GameManager.instance.unlock_level(GameManager.instance.current_level + 1)


func _load_next_level() -> void:
	GameManager.instance.current_level += 1
	#loadLevel(GameManager.instance.current_level)





func is_piece_solved(piece: Node2D) -> bool:
	return int(piece.rotation_degrees) % 360 == 0


func solve_piece(piece: Node2D):
	var tween = create_tween()
	tween.tween_property(piece, "rotation_degrees", 0, 0.3)
	await tween.finished
	timer_started = true



func game_win() -> void:
	print("Moves: ", move_count)
	print("Time Left: ", snapped(time_left, 0.01))
	Analytics.level_complete(level_index, calculate_stars())
	GameManager.instance.save_level_result(level_index, calculate_stars())
	SoundManager.play_win()
	UIController.instance.show_popup(ScreenType.popup.WIN_POPUP, {"star_count": calculate_stars()})
	nextLevel()
	GameManager.instance.save_data()


func calculate_stars() -> int:
	## ── time_limit from JSON for star calculation ─────────────────────────
	var total_time: float = float(current_level_json.get("time_limit", 30.0))
	var stars := 1
	var time_percent := time_left / total_time
	if time_percent >= 0.5:
		stars += 1
	if time_percent >= 0.8:
		stars += 2
	return clamp(stars, 1, 3)
