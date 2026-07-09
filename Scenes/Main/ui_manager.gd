class_name UiManager
extends CanvasLayer

static var instance : UiManager
var ui_callback : UICallBack
enum Screen_Type{
	MAIN_MENU,
	GAME,
	LEVEL
}
@export var main_menu : Control
@export var game_scene : Control
@export var level_scene : Control
@export var preview_overlay : Control

@export var popup_manager : PopupManager

var screen_map : Dictionary
var current_screen : Control

func _init():
	ui_callback = UICallBack.new()
func _enter_tree():
	instance = self

func _ready():

	screen_map = {
		Screen_Type.MAIN_MENU : main_menu,
		Screen_Type.GAME : game_scene,
		Screen_Type.LEVEL : level_scene
	}
	show_screen(Screen_Type.MAIN_MENU)
	# UiManager.instance.show_screen(UiManager.Screen_Type.MAIN_MENU)
	# UiManager.instance.ui_callback.update_coins_ui(GameManager.instance.get_total_coin())
	


func show_screen(type: Screen_Type):
	var new_screen = screen_map[type]

	if current_screen == new_screen:
		return

	if current_screen:
		var old_screen = current_screen
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(
			old_screen,
			"position:x",
			-get_viewport().size.x,
			0.5
		)

		tween.parallel().tween_property(
			old_screen,
			"modulate:a",
			0.0,
			0.5
		)

		await tween.finished

		old_screen.hide()
		old_screen.position = Vector2.ZERO
		old_screen.modulate.a = 1.0

	current_screen = new_screen
	current_screen.show()

	current_screen.position.x = get_viewport().size.x
	current_screen.modulate.a = 0.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		current_screen,
		"position:x",
		0,
		0.5
	)

	tween.parallel().tween_property(
		current_screen,
		"modulate:a",
		1.0,
		0.5
	)

func show_popup(type : PopupManager.PopupType):
	popup_manager.show_popup(type)

func hide_popup():
	popup_manager.hide_popup()

func has_popup() -> bool:
	return popup_manager.is_popup_open()


func click_animation(btn: Control) -> void:
	# btn.pivot_offset = btn.size / 2.0
	var original_scale = btn.scale
	var tween = btn.create_tween()
	tween.parallel().tween_property(btn, "scale", original_scale * 0.95, 0.1)
	tween.parallel().tween_property(btn, "modulate", Color(0.4, 0.4, 0.4), 0.1)
	tween.tween_property(btn, "scale", original_scale, 0.1)
	tween.parallel().tween_property(btn, "modulate", Color.WHITE, 0.1)
	await tween.finished