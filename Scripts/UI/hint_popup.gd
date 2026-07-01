extends BaseScreen
@onready var _closeBtn = $HintPanel/Header/CloseButton
var pending_half_hint := false
var pending_full_hint := false
func _ready() -> void:
	GameManager.instance.level_generator.timer_started = false
	if _closeBtn:
		_closeBtn.pressed.connect(_onCloseBtnPressed)
	pass

func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	GameManager.instance.level_generator.resume_game()
	pass


func _on_hint_for_preview_pressed() -> void:
	if OS.has_feature("editor"):
		GameManager.instance.level_generator.timer_started = false
		GameManager.instance.hint_powerup.use_full_hint()
		UIController.instance.ui_callback.preview_pressed(false)
		UIController.instance.close_popup()
		return

	if AdMob.is_rewarded_available():

		pending_full_hint = true

		AdMob.rewarded_ad_dismissed.connect(
			_on_full_hint_ad_closed,
			CONNECT_ONE_SHOT
		)

		AdMob.show_rewarded()
	else:

		show_no_ads_popup()




func _on_full_hint_ad_closed() -> void:
	
	if not pending_full_hint:
		return

	pending_full_hint = false
	Analytics.eye_powerup_used(
		GameManager.instance.current_level
	)
	GameManager.instance.hint_powerup.use_full_hint()
	UIController.instance.ui_callback.preview_pressed(false)
	# GameManager.instance.level_generator.timer_started = true

	UIController.instance.close_popup()


func _on_hint_for_path_solve_pressed() -> void:
	if OS.has_feature("editor"):
		await GameManager.instance.hint_powerup.use_half_hint()
		GameManager.instance.hint_powerup.reset_hints()
		UIController.instance.close_popup()
		return
	if AdMob.is_rewarded_available():

		pending_half_hint = true

		AdMob.rewarded_ad_dismissed.connect(
			_on_half_hint_ad_closed,
			CONNECT_ONE_SHOT
		)

		AdMob.show_rewarded()
	else:
		show_no_ads_popup()
func _on_half_hint_ad_closed() -> void:
	if not pending_half_hint:
		return

	pending_half_hint = false
	Analytics.map_powerup_used(
		GameManager.instance.current_level
	)

	await GameManager.instance.hint_powerup.use_half_hint()

	GameManager.instance.hint_powerup.reset_hints()
	UIController.instance.close_popup()
#func show_no_ads_popup():
#
	#no_ads_popup.visible = true
#
	#await get_tree().create_timer(2.0).timeout
#
	#no_ads_popup.visible = false
func show_no_ads_popup():

	var popup_scene = preload("res://Scenes/UI/Popups/NoAdsPopup.tscn")
	var popup = popup_scene.instantiate()

	add_child(popup)

	# Fully visible
	popup.modulate.a = 1.0

	# Wait for 2 seconds
	await get_tree().create_timer(2.0).timeout

	# Fade out
	var tween = create_tween()
	tween.tween_property(
		popup,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished

	popup.queue_free()
