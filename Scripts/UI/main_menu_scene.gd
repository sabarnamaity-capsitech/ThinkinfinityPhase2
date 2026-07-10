extends Control

@onready var _playBtn = $Panel/PlayButton
@onready var _tutorialBtn = $Panel/TutorialButton
@onready var _settingsBtn = $Panel/SettingsButton
@export var _coins:Label
@export var _shopBtn: TextureButton
func _ready() -> void:
	
	UiManager.instance.ui_callback.update_coins.connect(_on_update_coins)
	_coins.text=str(GameManager.instance.get_total_coin())
	_shopBtn.pressed.connect(_onShopBtnPressed)
	if _playBtn:
		_playBtn.pressed.connect(_onPlayBtnPressed)
	if _tutorialBtn:
		_tutorialBtn.pressed.connect(_onTutorialBtnPressed)
	if _settingsBtn:
		_settingsBtn.pressed.connect(_onSettingsBtnPressed)
	pass

func _onPlayBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.switch_screen(ScreenType.Screen.LEVEL_SCREEN)
	UiManager.instance.ui_callback.update_btn_alllevel()
	
func _onShopBtnPressed() -> void:
	print("Shop button pressed")
	SoundManager.play_click()
	# UiManager.instance.show_popup(ScreenType.popup.Shop)
func _onSettingsBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.show_popup(ScreenType.popup.SETTINGS_POPUP)
	UiManager.instance.show_popup(ScreenType.popup.SETTINGS_POPUP)
	pass

func _onTutorialBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.show_popup(ScreenType.popup.TUTORIAL_POPUP)
	# UiManager.instance.show_popup(PopupManager.PopupType.TUTORIAL)
	pass
func _on_update_coins(coins):
	_coins.text=str(coins)
