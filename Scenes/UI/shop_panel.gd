extends Control
@export var closeBtn: TextureButton
@export var coinshopBtn: TextureButton
@export var carshopBtn: TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	closeBtn.pressed.connect(_onCloseBtnPressed)
	coinshopBtn.pressed.connect(_onCoinshopBtnPressed)
	carshopBtn.pressed.connect(_onCarshopBtnPressed)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.hide_popup()

func _onCoinshopBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.show_popup(PopupManager.PopupType.COIN_SHOP)

func _onCarshopBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.show_popup(PopupManager.PopupType.CAR_SHOP)
