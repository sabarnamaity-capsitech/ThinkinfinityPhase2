extends Control

@export var timer : Label
@onready var _pauseBtn = $PauseButton
@onready var _hintBtn = $HintButton
@export var _timerBox : Label
@export var top_text : Label
@export var bg : TextureRect
@export var levelBox : Label

var hint_tween: Tween




func _ready() -> void:
	# UIController.instance.ui_callback.update_timer.connect(update_time)
	# UIController.instance.ui_callback.hideallBtn.connect(btnOff)
	# UIController.instance.ui_callback.update_level.connect(update_Toptext)
	# UIController.instance.ui_callback.update_color.connect(sprite_changer)
	# UIController.instance.ui_callback.update_wintime.connect(winsprite_changer)
	# UIController.instance.ui_callback.previewbtn_pressed.connect(btnOff_preview)
	UiManager.instance.ui_callback.update_timer.connect(update_time)
	UiManager.instance.ui_callback.hideallBtn.connect(btnOff)
	UiManager.instance.ui_callback.update_level.connect(update_Toptext)
	UiManager.instance.ui_callback.update_color.connect(sprite_changer)
	UiManager.instance.ui_callback.update_wintime.connect(winsprite_changer)
	UiManager.instance.ui_callback.previewbtn_pressed.connect(btnOff_preview)
	_pauseBtn.pressed.connect(_onPauseBtnPressed)
	_hintBtn.pressed.connect(_onHintBtnPressed)
	# UIController.instance.ui_callback.update_color.connect(sprite_changer)
	#top_text.text=str("level : ",GameManager.instance.current_level+1)
	# update_Toptext()


	# top_text.text=str("level : ",GameManager.instance.current_level+1)

	
	


func _onPauseBtnPressed() -> void:
	SoundManager.play_click()
	GameManager.instance.level_generator.pause_game()
	

func _onHintBtnPressed() -> void:
	SoundManager.play_click()
	SoundManager.stop_timerPlay()
	# UIController.instance.show_popup(ScreenType.popup.HINT_POPUP)
	UiManager.instance.show_popup(PopupManager.PopupType.HINT)
	if hint_tween and hint_tween.is_valid():
		hint_tween.kill()
		hint_tween = null

	_hintBtn.scale = Vector2.ONE
	GameManager.instance.level_generator.timer_started=false
	_pauseBtn.mouse_filter = Control.MOUSE_FILTER_STOP
	GameManager.instance.level_generator.set_pieces_interactable(true)
	GameManager.instance.is_First_Time_hint=false





func start_hint_animation():
	if hint_tween and hint_tween.is_valid():
		return

	hint_tween = create_tween()
	hint_tween.set_loops()
	
	_hintBtn.pivot_offset = _hintBtn.size/2
	hint_tween.tween_property(
		_hintBtn,
		"scale",
		Vector2(1.15, 1.15),
		0.4
	)

	hint_tween.tween_property(
		_hintBtn,
		"scale",
		Vector2.ONE,
		0.4
	)


var warning_tween: Tween

func update_time(time_left: int) -> void:
	var minutes = time_left / 60
	var seconds = time_left % 60

	timer.text = "%02d:%02d" % [minutes, seconds]

	if time_left <= 5:
		timer.add_theme_color_override("font_color", Color.RED)

		if warning_tween == null or !warning_tween.is_valid():
			warning_tween = create_tween()
			warning_tween.set_loops()

			timer.pivot_offset = timer.size/2
			warning_tween.tween_property(
				timer,
				"scale",
				Vector2(1.2, 1.2),
				0.5
			)

			warning_tween.tween_property(
				timer,
				"scale",
				Vector2.ONE,
				0.5
			)

	else:
		timer.add_theme_color_override("font_color", Color.BLACK)

		timer.scale = Vector2.ONE

		if warning_tween and warning_tween.is_valid():
			warning_tween.kill()
			warning_tween = null


func btnOff(type : bool) -> void:
	_hintBtn.visible=type
	_pauseBtn.visible=type
	_timerBox.visible=type


func btnOff_preview(type : bool) -> void:
	_hintBtn.visible=type
	_pauseBtn.visible=type
	_timerBox.visible=type
	levelBox.visible=type
	

func update_Toptext() -> void:
	top_text.text = tr("Level")+":" + str(GameManager.instance.current_level +1)
	if GameManager.instance.current_level == 1 and  GameManager.instance.is_First_Time_hint==true:
		GameManager.instance.level_generator.set_pieces_interactable(false)
		print("kjdkhkfdshkdfhshfdhsdhfjhdsf")
		_pauseBtn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameManager.instance.level_generator.timer_started=false
		start_hint_animation()


func sprite_changer(color: Color,colorTwo: Color,texture : Texture2D) ->void:
		RenderingServer.set_default_clear_color(color)
		bg.texture = texture


func winsprite_changer(type : bool) ->void:
		# RenderingServer.set_default_clear_color(Color.BLACK)
		bg.visible=type
		
		


# func fit_background() -> void:
# 	var viewport_size = get_viewport_rect().size
# 	var texture_size = background.texture.get_size()
# 	var scale_factor = max(viewport_size.x / texture_size.x,viewport_size.y / texture_size.y)
# 	background.position = viewport_size / 2
# 	background.scale = Vector2.ONE * scale_factor
