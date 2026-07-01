extends Control
class_name BaseScreen

@export var screen_type: ScreenType.Screen = ScreenType.Screen.NONE

@export var start_hidden: bool = true

func _ready() -> void:
	if start_hidden:
		hide_immediate()
		
	if screen_type == ScreenType.Screen.NONE:
		push_warning("Screen type not set for %s" % name)


func showw() -> void:
	visible = true
	on_show()

func hidee() -> void:
	hide_immediate()
	on_hide()

func hide_immediate() -> void:
	visible = false


# will be overriden in subclesses
func on_show() -> void:
	pass

func on_hide() -> void:
	pass
