extends Control

@onready var _closeBtn = $WinnerPanel/Header/CloseButton
@export var stars: Array[Node]
@export var restartBtn: Button
@export var nextLevel: Button
@export var levelTxt : Label

func _ready() -> void:
	_closeBtn.pressed.connect(_onCloseBtnPressed)
	restartBtn.pressed.connect(_onRestartBtnPressed)
	nextLevel.pressed.connect(_onnextBtnPressed)
	levelTxt.text=tr("Level")+ ":"+str(GameManager.instance.current_level)

	

func _onRestartBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.click_animation(restartBtn)
	GameManager.instance.level_generator.restart()



func _onnextBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.click_animation(nextLevel)
	UiManager.instance.hide_popup()
	GameManager.instance.level_generator.nextLevel()


func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.click_animation(_closeBtn)
	# UIController.instance.switch_screen(ScreenType.Screen.MAIN_MENU)
	UiManager.instance.show_screen(UiManager.Screen_Type.MAIN_MENU)
	GameManager.instance.level_generator.stop_game()
	pass


func set_data(data: Dictionary) -> void:
	var star_count = data.get("star_count", 0)
	update_Ui(star_count)


func update_Ui(starCount: int) -> void:
	print(starCount, " FFFFGD")
	for i in range(starCount):
		stars[i].visible = true
		stars[i].scale = Vector2.ZERO

		var tween = create_tween()
		tween.tween_interval(i * 0.15)
		tween.tween_property(stars[i], "scale", Vector2.ONE, 0.3)

	for i in range(starCount, stars.size()):
		stars[i].visible = false
