extends Control

@onready var _back_to_menu_btn = $Panel/BackButton
@onready var _grid_container: GridContainer = $Panel/ScrollContainer/GridContainer


@export var _level_button_prefab: PackedScene

var _level_components: Array[LevelBtn] = []


func _ready() -> void:
	
	_back_to_menu_btn.pressed.connect(_on_back_btn_pressed)
	_populate_level_buttons()


func _on_back_btn_pressed() -> void:
	SoundManager.play_click()
	# UIController.instance.switch_screen(ScreenType.Screen.MAIN_MENU)
	UiManager.instance.show_screen(UiManager.Screen_Type.MAIN_MENU)


func on_show() -> void:
	# super.on_show()
	_update_level_buttons()
	pass


func _populate_level_buttons() -> void:
	_clear_level_buttons()

	var keys = GameManager.instance.all_levels.keys()
	keys.sort()

	for level_number in keys:
		_create_level_button(level_number)


func _create_level_button(level_number: int) -> void:
	print(level_number)
	var level_button = _level_button_prefab.instantiate()
	_grid_container.add_child(level_button)
	_level_components.append(level_button)
	var unlocked = GameManager.instance.is_level_unlocked(level_number)
	level_button.setup(level_number, unlocked)
	


	
func _update_level_buttons() -> void:
	for button in _level_components:
		if !is_instance_valid(button):
			continue

		var unlocked = GameManager.instance.is_level_unlocked(button._level_index)
		button.update_state(unlocked)


func _clear_level_buttons() -> void:
	for button in _level_components:
		if is_instance_valid(button):
			button.queue_free()
	_level_components.clear()
	
	for child in _grid_container.get_children():
		child.queue_free()
		
