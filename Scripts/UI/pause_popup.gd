extends Control

@onready var _closeBtn = $PausePanel/Header/CloseButton
@onready var _homeBtn = $PausePanel/HomeButton
@onready var _resumeBtn = $PausePanel/ResumeButton
@export var _restartBtn : Button


func _ready() -> void:
	#screen_type = ScreenType.Type.PAUSE_POPUP
	if _closeBtn:
		_closeBtn.pressed.connect(_onCloseBtnPressed)
	if _homeBtn:
		_homeBtn.pressed.connect(_onHomeBtnPressed)
	if _resumeBtn:
		_resumeBtn.pressed.connect(_onResumeBtnPressed)
	_restartBtn.pressed.connect(_onRestartBtnPressed)
	
	

func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	GameManager.instance.level_generator.resume_game()
	pass

func _onHomeBtnPressed() -> void:
	SoundManager.play_click()
	UIController.instance.switch_screen(ScreenType.Screen.MAIN_MENU)
	GameManager.instance.level_generator.stop_game()
	pass

func _onResumeBtnPressed() -> void:
	SoundManager.play_click()
	GameManager.instance.level_generator.resume_game()
	pass
func _onRestartBtnPressed() -> void:
	SoundManager.play_click()
	GameManager.instance.level_generator.restart()
	pass
