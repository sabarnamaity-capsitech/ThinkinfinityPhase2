extends Control
class_name LevelBtn

@onready var _unlocked_sprite = $unlocked
@onready var _locked_sprite = $locked
@onready var _level_number_label = $unlocked/LavelNumber
@onready var _select_btn = $Button

var _level_index: int

func setup(level_index: int, is_unlocked: bool) -> void:
	print("Setup:", level_index)
	_level_index = level_index

	_unlocked_sprite.visible = is_unlocked
	_locked_sprite.visible = !is_unlocked
	_level_number_label.visible = is_unlocked

	_select_btn.disabled = !is_unlocked

	if is_unlocked:
		_level_number_label.text = str(level_index)


	if not _select_btn.pressed.is_connected(_on_level_selected):
		_select_btn.pressed.connect(_on_level_selected)


func _on_level_selected() -> void:
	SoundManager.play_click()
	print("Level Selected: ", _level_index)
	GameManager.instance.level_generator.load_level(_level_index)


func update_state(is_unlocked: bool) -> void:
	
	_unlocked_sprite.visible = is_unlocked
	_locked_sprite.visible = !is_unlocked
	_level_number_label.visible = is_unlocked
	_select_btn.disabled = !is_unlocked
	if is_unlocked:
		_level_number_label.text = str(_level_index)