extends Control
@export var closeBtn: TextureButton

func _ready():
	closeBtn.pressed.connect(_onCloseBtnPressed)
func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.hide_popup()