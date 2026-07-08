extends Node
class_name GameManager

static var instance: GameManager
@export var level_generator: LevelGenerator
@export var hint_powerup:Hint
@export var preview_overlay : PreviewOverlay
var current_level_json: Dictionary = {}


var move_count: int = 0
var time_left: float
var timer_warning_started: bool = false
var timer_started := false
var game_finished := false
var car_moving := false

var scale_factor := 1.0
var all_levels : Dictionary = {}
var current_level;
var tutorial_open_count := 0
# =========================
# FILE PATH
# =========================
var file_name := "gamedata.dat"
var file_path := ""
# =========================
# GAME DATA
# =========================
var game_data := {}

# =========================
# INIT
# =========================
func init() -> void:
	MetaSdk.init()


func _enter_tree():
	
	if instance == null:
		instance = self
	else:
		queue_free()
	
	create_path()
	load_data()
	preload_levels()


func _ready():
	print("Max Unlocked Level: ", game_data["player_data"]["max_unlocked_level_index"])
	TranslationServer.set_locale(get_language())
	#apply_sound_settings()
	



func preload_levels() -> void:
	all_levels.clear()

	var file = FileAccess.open("res://levels.json", FileAccess.READ)

	if file == null:
		push_error("Failed to open levels.json")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null:
		push_error("Invalid JSON")
		return

	if not json.has("levels"):
		push_error("No 'levels' array found in JSON")
		return

	for level_data in json["levels"]:
		var level_id : int = int(level_data["level"])
		all_levels[level_id] = level_data

	


func create_path():
	file_path = "user://" + file_name
	var absolute_path = ProjectSettings.globalize_path(file_path)
	print(absolute_path)
	

func save_data():
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(game_data)  # Binary serialization
		file.close()
		print("Saved successfully (DAT)")
	else:
		push_error("Save failed")

func load_data():
	if not FileAccess.file_exists(file_path):
		initialize_default_data()
		save_data()
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var result = file.get_var()  # Read binary data

		if result != null:
			game_data = result
			print("Loaded successfully (DAT)")
		else:
			print("Corrupted data, resetting...")
			initialize_default_data()
			save_data()

		file.close()

 

func initialize_default_data():
	game_data = {
		"player_data": {
			"name": "",
			"uid": "",
			"user_rank": 0,
			"total_coin": 5000,
			"total_score": 0,
			"game_won_counter": 0,
			"max_unlocked_level_index": 150,
			"is_FirstTime" : true,
			"is_FirstTime_hint" : true,
			"home_return_count" : 0,
			"level_progressions": _create_level_list(50),
			"owned_cars": {
                "0": true
            },
            "selected_car": 0,
            "bought_coin_packs": {}
		},

		"settings_data": {
			"is_music_on": true,
			"is_sound_on": true,
			"is_theme_on": true,
			"sfx_volume": 1.0,
			"music_volume": 1.0,
			"is_first_time_playing": false,
			"language": "en",
			"is_login_mode_guest": true,
			"is_zyro_mode": true
		}
	}

	print("Default data initialized")

func _create_level_list(count:int) -> Array:
	var arr := []
	for i in count:
		arr.append({
			"completed": false,
			"stars": 0,
			"best_time": 0.0,
			"best_moves": 0
		})
	return arr

# =========================
# GETTERS
# =========================

var is_first_time: bool:
	get:
		return game_data["player_data"]["is_FirstTime"]
	set(value):
		game_data["player_data"]["is_FirstTime"] = value
		save_data()
		
var is_First_Time_hint: bool:
	get:
		return game_data["player_data"]["is_FirstTime_hint"]
	set(value):
		game_data["player_data"]["is_FirstTime_hint"] = value
		save_data()


var is_setMaxUnlock: int:
	get:
		return game_data["player_data"]["max_unlocked_level_index"]
	set(value):
		game_data["player_data"]["max_unlocked_level_index"] = value
		save_data()


var home_return_count: int:
	get:
		return game_data["player_data"]["home_return_count"]
	set(value):
		game_data["player_data"]["home_return_count"] = value
		save_data()
		
func get_music_on() -> bool:
	return game_data["settings_data"]["is_music_on"]

func get_sound_on() -> bool:
	return game_data["settings_data"]["is_sound_on"]

func get_zyro_mode() -> bool:
	return game_data["settings_data"]["is_zyro_mode"]

func get_language():
	return game_data["settings_data"]["language"]

func get_login_mode() -> bool:
	return game_data["settings_data"]["is_login_mode_guest"]

func get_music_volume() -> float:
	return game_data["settings_data"]["music_volume"]

func get_sfx_volume() -> float:
	return game_data["settings_data"]["sfx_volume"]

func get_player_name() -> String:
	return game_data["player_data"]["name"]
func get_player_uid() -> String:
	return game_data["player_data"]["uid"]
func get_player_rank() -> int:
	return game_data["player_data"]["user_rank"]


func get_level_stars(level_index: int) -> int:
	var levels = game_data["player_data"]["level_progressions"]
	return levels[level_index - 1]

func get_total_coin() -> int:
	return game_data["player_data"]["total_coin"]
# =========================
# SETTERS
# =========================
func set_music_toggle():
	game_data["settings_data"]["is_music_on"] = !game_data["settings_data"]["is_music_on"]
	# apply_music_settings()
	save_data()

func set_sound_toggle():
	game_data["settings_data"]["is_sound_on"] = !game_data["settings_data"]["is_sound_on"]
	# apply_sound_settings()
	save_data()

func set_zyro_mode_toggle():
	game_data["settings_data"]["is_zyro_mode"] = !game_data["settings_data"]["is_zyro_mode"]
	save_data()

func set_language(lang:String):
	game_data["settings_data"]["language"] = lang
	save_data()

func set_login_mode(is_guest:bool):
	game_data["settings_data"]["is_login_mode_guest"] = is_guest
	save_data()
func set_player_name(player_name:String):
	game_data["player_data"]["name"] = player_name
	save_data()

func set_player_uid(uid:String):
	game_data["player_data"]["uid"] = uid
	save_data()

func set_player_rank(rank:int):
	game_data["player_data"]["user_rank"] = rank
	save_data()
func set_total_coin(coin:int):
	game_data["player_data"]["total_coin"] = coin
	save_data()
# =========================
# LEVEL STAR SAVE
# =========================
func save_level_stars(level_index: int, stars: int):

	var levels = game_data["player_data"]["level_progressions"]
	# array index starts from 0
	var current_stars = levels[level_index - 1]
	if stars > current_stars:
		levels[level_index - 1] = stars
		save_data()
		print("Saved Stars -> Level:", level_index, " Stars:", stars)



func save_level_result(level_index:int,stars:int):
	# var levels = game_data["player_data"]["level_progressions"]

	# var level = levels[level_index - 1]

	# level["completed"] = true

	# if stars > level["stars"]:
	# 	level["stars"] = stars

	save_data()


# func apply_music_settings():

# 	var bus_index = AudioServer.get_bus_index("Music")

# 	if get_music_on():
# 		AudioServer.set_bus_mute(bus_index, false)
# 	else:
# 		AudioServer.set_bus_mute(bus_index, true)

# func apply_sound_settings():
# 	var bus_index = AudioServer.get_bus_index("SFX")

# 	if get_sound_on():
# 		AudioServer.set_bus_mute(bus_index, false)
# 	else:
# 		AudioServer.set_bus_mute(bus_index, true)


func is_level_unlocked(level_index:int) -> bool:
	return level_index <= game_data["player_data"]["max_unlocked_level_index"]


func unlock_level(level_index:int):
	var current = game_data["player_data"]["max_unlocked_level_index"]

	if level_index > current:
		game_data["player_data"]["max_unlocked_level_index"] = level_index
		print("new level")
		save_data()

func is_car_owned(car_id:int) -> bool:
	return game_data["player_data"]["owned_cars"].get(str(car_id), false)
 
 
func buy_car(car_id:int):
	game_data["player_data"]["owned_cars"][str(car_id)] = true
	save_data()
 
 
func get_selected_car() -> int:
	return game_data["player_data"]["selected_car"]
 
 
func set_selected_car(car_id:int):
	game_data["player_data"]["selected_car"] = car_id
	save_data()
   
func is_coin_pack_bought(id:int) -> bool:
	return game_data["player_data"]["bought_coin_packs"].get(str(id), false)
 
func buy_coin_pack(id:int):
	game_data["player_data"]["bought_coin_packs"][str(id)] = true
	save_data()				
