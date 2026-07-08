extends Control

@onready var _closeBtn = $FailurePanel/Header/CloseButton
@export var restartBtn : Button
@export var resumetimer : Button
@export var levelTxt : Label

func _ready() -> void:
	#screen_
	_closeBtn.pressed.connect(_onCloseBtnPressed)
	restartBtn.pressed.connect(_onRestartBtnPressed)
	resumetimer.pressed.connect(_onResumetimeBtnPressed)
	# levelTxt.text=tr("Level")+ ":"+str(GameManager.instance.current_level+1)

	

func _onRestartBtnPressed() -> void:
	SoundManager.play_click()
	GameManager.instance.level_generator.restart()

	
	
func _onResumetimeBtnPressed() -> void:
	SoundManager.play_click()

	if AdMob.is_rewarded_available():
		AdMob.rewarded_ad_user_earned_reward.connect(
			_on_resume_time_rewarded,
			CONNECT_ONE_SHOT
		)
		AdMob.show_rewarded()
	else:
		show_no_ads_popup()
		
func _on_resume_time_rewarded(_ad_info, _reward_data) -> void:
	Analytics.restart_powerup_used(
		GameManager.instance.current_level
	)
	GameManager.instance.level_generator.resume_time()
	


func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.switch_screen(ScreenType.Screen.MAIN_MENU)
	UiManager.instance.show_screen(UiManager.Screen_Type.MAIN_MENU)
	GameManager.instance.level_generator.stop_game()


func show_no_ads_popup():

	var popup_scene = preload("res://Scenes/UI/Popups/NoAdsPopup.tscn")
	var popup = popup_scene.instantiate()

	add_child(popup)

	await get_tree().create_timer(2.0).timeout

	var tween = create_tween()
	tween.tween_property(
		popup,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished

	popup.queue_free()
