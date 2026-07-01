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
	


func show_screen(type : Screen_Type):
	for screen in screen_map.values():
		screen.hide()
	current_screen = screen_map[type]
	current_screen.show()

func show_popup(type : PopupManager.PopupType):
	popup_manager.show_popup(type)

func hide_popup():
	popup_manager.hide_popup()

func has_popup() -> bool:
	return popup_manager.is_popup_open()
