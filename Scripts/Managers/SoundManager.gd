extends Node

# =========================================================
# PLAYERS
# =========================================================

var music_player : AudioStreamPlayer
var sfx_player : AudioStreamPlayer
var ui_player : AudioStreamPlayer
var timer_player : AudioStreamPlayer
# =========================================================
# AUDIO FILES
# =========================================================

var bg_music = preload("res://assets/ThinkfinityAsset/Art/Audio/Puzzle Game (Faster Version).mp3")

var car_start = preload("res://assets/ThinkfinityAsset/Art/Audio/Car StartEdit.ogg")

var move_sound = preload("res://assets/ThinkfinityAsset/Art/Audio/Source Metal Gears Deep Loosen Tighten Click Rotating Mechanism Short 04.wav")

var click_sound = preload("res://assets/ThinkfinityAsset/Art/Audio/Select Click Metallic Tap Slight Scratch.wav")

var win_sound = preload("res://assets/ThinkfinityAsset/Art/Audio/Congratsbell.wav")

var game_over = preload("res://assets/ThinkfinityAsset/Art/Audio/Wrong Tension.wav")

var timer_sound = preload("res://assets/ThinkfinityAsset/Art/Audio/TimerTick_loop1.ogg")

var rotate_sound = preload("res://assets/ThinkfinityAsset/Art/Audio/Source Metal Gears Deep Loosen Tighten Click Rotating Mechanism Short 04.wav")
# =========================================================
# INIT
# =========================================================

func _ready():

	# MUSIC PLAYER
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	#TIMER PLAYER
	timer_player = AudioStreamPlayer.new()
	timer_player.bus = "SFX"
	add_child(timer_player)

	# SFX PLAYER
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	# UI PLAYER
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "UI"
	add_child(ui_player)

	# CONNECT ALL UI BUTTONS
	call_deferred("connect_click_buttons")

	# LOAD SAVED SETTINGS
	load_audio_settings()

	# PLAY MUSIC
	
	var _is_music_on = GameManager.instance.get_music_on()
	if _is_music_on:
		play_music()

# =========================================================
# CONNECT BUTTON GROUP
# =========================================================

func connect_click_buttons():

	var buttons = get_tree().get_nodes_in_group("click_button")

	for button in buttons:

		if button is BaseButton:

			if not button.pressed.is_connected(_on_ui_button_pressed):

				button.pressed.connect(_on_ui_button_pressed)

# =========================================================
# BUTTON CLICK
# =========================================================

func _on_ui_button_pressed():
	if _should_play():
		play_click()

# =========================================================
# MUSIC
# =========================================================

func play_music():

	if music_player.playing:
		return

	music_player.stream = bg_music
	music_player.stream.loop = true
	music_player.play()

func stop_music():

	music_player.stop()

# =========================================================
# UI SOUND
# =========================================================

func play_click():
	if _should_play():
		ui_player.pitch_scale = 1.0
		ui_player.stream = click_sound
		ui_player.play()

func play_popup():
	if _should_play():
		ui_player.pitch_scale = 0.9
		ui_player.stream = click_sound
		ui_player.play()


# =========================================================
# GAMEPLAY SOUND
# =========================================================

#func play_game_start():
#
	##sfx_player.stream = gameplay_start_sound
	#sfx_player.play()

func play_win():
	if _should_play():
		sfx_player.stream = win_sound
		sfx_player.play()

func play_timer():
	if _should_play():
		timer_player.stream = timer_sound
		timer_player.play()

func stop_timerPlay():
	if timer_player:
		timer_player.stop()

func play_game_over():
	if _should_play():
		sfx_player.stream = game_over
		sfx_player.play()

func play_car_start():
	if _should_play():
		sfx_player.stream = car_start
		sfx_player.play()

func play_rotate():
	if _should_play():
		sfx_player.stream = rotate_sound
		sfx_player.play()


# =========================================================
# MUSIC VOLUME
# =========================================================

func set_music_volume(value: float):

	print("Music Volume : ", value)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)

	# SAVE
	#GameDataHandler.player.music_volume = value #---
	#GameDataHandler.save_player_data() #---

# =========================================================
# SFX VOLUME
# =========================================================

func set_sfx_volume(value: float):

	print("SFX Volume : ", value)

	var db = linear_to_db(value)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		db
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("UI"),
		db
	)

	# SAVE
	#GameDataHandler.player.sfx_volume = value #---
	#GameDataHandler.save_player_data() #---

# =========================================================
# LOAD AUDIO SETTINGS
# =========================================================

func load_audio_settings():

	var music_value := 1.0
	var sfx_value := 1.0

	#if GameDataHandler.player != null: 

		#music_value = GameDataHandler.player.music_volume
		#sfx_value = GameDataHandler.player.sfx_volume

	# set_music_volume(music_value)
	# set_sfx_volume(sfx_value)


func _should_play() -> bool:
	var _is_sound_on = GameManager.instance.get_sound_on()
	if _is_sound_on:
		return true
	else:
		return false
