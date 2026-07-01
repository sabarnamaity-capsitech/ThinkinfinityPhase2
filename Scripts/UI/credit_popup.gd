extends Control
@onready var _closeBtn = $CreditPanel/PanelBG/CloseButton

func _ready() -> void:
	if _closeBtn:
		_closeBtn.pressed.connect(_onCloseBtnPressed)
	pass

func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	# UIController.instance.close_popup()
	UiManager.instance.hide_popup()
	pass
