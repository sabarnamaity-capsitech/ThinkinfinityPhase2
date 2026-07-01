extends BaseScreen

@onready var _closeBtn = $PopupPanel/Header/CloseButton
@onready var _languageBtn = $PopupPanel/LanguageButton

@onready var _languagePanel = $LangugagePanel
@onready var _languageCloseBtn = $LangugagePanel/Languageheader/CloseButton

@onready var _creditBtn = $PopupPanel/CreditButton
@onready var _englishBtn = $LangugagePanel/Languagepopup/VBoxContainer/EnglishButton
@onready var _spanishBtn = $LangugagePanel/Languagepopup/VBoxContainer/SpanishButton
@onready var _portugueseBtn = $LangugagePanel/Languagepopup/VBoxContainer/PortuguseButton
@onready var _frenchBtn = $LangugagePanel/Languagepopup/VBoxContainer/FrenchButton
@onready var _arabicBtn = $LangugagePanel/Languagepopup/VBoxContainer/ArabicButtton
@onready var _russianBtn = $LangugagePanel/Languagepopup/VBoxContainer/RussianButton



@onready var sound_on_btn = $PopupPanel/SoundOnButton
@onready var music_on_btn = $PopupPanel/MusicOnButton
@onready var sound_off_btn = $PopupPanel/SoundOffButton
@onready var music_off_btn = $PopupPanel/MusicOffButton
@export var privacyButton : Button

func _ready() -> void:
	

	print("Loaded locales:")
	print(TranslationServer.get_loaded_locales())

	sound_on_btn.pressed.connect(_on_sound_pressed)
	sound_off_btn.pressed.connect(_on_sound_pressed)
	music_on_btn.pressed.connect(_on_music_pressed)
	music_off_btn.pressed.connect(_on_music_pressed)
	privacyButton.pressed.connect(on_Pressed_privacyButton)
	update_buttons()


	if _closeBtn:
		_closeBtn.pressed.connect(_onCloseBtnPressed)

	if _languageBtn:
		_languageBtn.pressed.connect(_onLanguageBtnPressed)
	
	if _creditBtn:
		_creditBtn.pressed.connect(_onCreditBtnPressed)

	if _languageCloseBtn:
		_languageCloseBtn.pressed.connect(_onLanguageCloseBtnPressed)
	

	if _englishBtn:
		_englishBtn.pressed.connect(_onEnglishBtnPressed)

	if _spanishBtn:
		_spanishBtn.pressed.connect(_onSpanishBtnPressed)

	if _portugueseBtn:
		_portugueseBtn.pressed.connect(_onPortugueseBtnPressed)

	if _frenchBtn:
		_frenchBtn.pressed.connect(_onFrenchBtnPressed)

	if _arabicBtn:
		_arabicBtn.pressed.connect(_onArabicBtnPressed)

	if _russianBtn:
		_russianBtn.pressed.connect(_onRussianBtnPressed)

	_languagePanel.visible = false
	update_language_highlight()


func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.close_popup()
	UiManager.instance.hide_popup()


func _onLanguageBtnPressed() -> void:
	SoundManager.play_click()
	# Hide Settings Panel

	$PopupPanel.visible = false
	_languagePanel.visible = true

func _onCreditBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.show_popup(ScreenType.popup.CREDIT_POPUP)
	UiManager.instance.show_popup(PopupManager.PopupType.CREDIT)
	
func _on_sound_pressed():
	SoundManager.play_click()
	GameManager.instance.set_sound_toggle()
	update_buttons()

func _on_music_pressed():
	SoundManager.play_click()
	GameManager.instance.set_music_toggle()
	update_buttons()
	update_music()

func _onLanguageCloseBtnPressed() -> void:

	SoundManager.play_click()
	# Hide Language Panel

	_languagePanel.visible = false
	$PopupPanel.visible = true



func on_Pressed_privacyButton()-> void:
	OS.shell_open("https://www.thegamewise.com/privacy-policy/")
	SoundManager.play_click()


func update_buttons():
	var sound_on = GameManager.instance.get_sound_on()
	sound_on_btn.visible = sound_on
	sound_off_btn.visible = !sound_on
	var music_on = GameManager.instance.get_music_on()
	music_on_btn.visible = music_on
	music_off_btn.visible = !music_on


func _onEnglishBtnPressed() -> void:
	_change_language("en")


func _onSpanishBtnPressed() -> void:
	_change_language("es")


func _onPortugueseBtnPressed() -> void:
	_change_language("pt_BR")


func _onFrenchBtnPressed() -> void:
		_change_language("fr")


func _onArabicBtnPressed() -> void:
	_change_language("ar")


func _onRussianBtnPressed() -> void:
	_change_language("ru")


func _change_language(locale: String) -> void:
	TranslationServer.set_locale(locale)
	GameManager.instance.set_language(locale)
	update_language_highlight()
	_languagePanel.visible = false
	$PopupPanel.visible = true
 # Replace with function body.


func update_music():
	var _is_on = GameManager.instance.get_music_on()
	if _is_on:
		SoundManager.play_music()
	else:
		SoundManager.stop_music()
	pass
func update_language_highlight():

	var selected_lang = GameManager.instance.get_language()

	var buttons = {
		"en": _englishBtn,
		"es": _spanishBtn,
		"pt_BR": _portugueseBtn,
		"fr": _frenchBtn,
		"ar": _arabicBtn,
		"ru": _russianBtn
	}

	for key in buttons:

		var btn = buttons[key]

		if key == selected_lang:
			btn.modulate = Color(0.8, 0.8, 0.8) # light ash
		else:
			btn.modulate = Color.WHITE
