extends Control

@onready var _playBtn = $Panel/PlayButton
@onready var _tutorialBtn = $Panel/TutorialButton
@onready var _settingsBtn = $Panel/SettingsButton
func _ready() -> void:
	# screen_type = ScreenType.Screen.MAIN_MENU
	
	if _playBtn:
		_playBtn.pressed.connect(_onPlayBtnPressed)
	if _tutorialBtn:
		_tutorialBtn.pressed.connect(_onTutorialBtnPressed)
	if _settingsBtn:
		_settingsBtn.pressed.connect(_onSettingsBtnPressed)
	pass

func _onPlayBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.level_scene.on_show()
	UiManager.instance.show_screen(UiManager.Screen_Type.LEVEL)
	

func _onSettingsBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.show_popup(ScreenType.popup.SETTINGS_POPUP)
	UiManager.instance.show_popup(PopupManager.PopupType.SETTINGS)
	pass

func _onTutorialBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.show_popup(ScreenType.popup.TUTORIAL_POPUP)
	UiManager.instance.show_popup(PopupManager.PopupType.TUTORIAL)
	pass
