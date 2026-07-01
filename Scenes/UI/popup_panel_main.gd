class_name PopupManager
extends Control
enum PopupType {
	NONE,
	PAUSE,
	WIN,
	LOSE,
	SETTINGS,
	TUTORIAL,
	HINT,
	CREDIT
}
 
@export var pause_popup : Control
@export var win_popup : Control
@export var lose_popup : Control
@export var settings_popup : Control
@export var tutorial_popup : Control
@export var hint_popup : Control
@export var credit_popup : Control
var popup_map : Dictionary = {}

var current_popup : Control = null
 
func _ready():
	popup_map = {

		PopupType.PAUSE : pause_popup,

		PopupType.WIN : win_popup,

		PopupType.LOSE : lose_popup,

		PopupType.SETTINGS : settings_popup,

		PopupType.TUTORIAL : tutorial_popup,

		PopupType.HINT : hint_popup,

		PopupType.CREDIT : credit_popup

	}
 
	hide_all()
 
func show_popup(type : PopupType):
	hide_all()
	current_popup = popup_map.get(type)
	if current_popup:
		_toggle_popup(current_popup, true)
 
func hide_popup():
	if current_popup:
		_toggle_popup(current_popup, false)
		current_popup = null
 
func hide_all():
	for popup in popup_map.values():
		if popup:
			popup.visible = false
			popup.scale = Vector2.ONE 
	current_popup = null
 
func is_popup_open() -> bool:
	return current_popup != null
 
func get_current_popup() -> Control:
	return current_popup
 
func _toggle_popup(popup : Control, show : bool, delay := 0.0):
 
	popup.pivot_offset = popup.size * 0.5
 
	var tween = create_tween()
 
	if show:
 
		popup.visible = true

		popup.scale = Vector2.ZERO
 
		tween.tween_property(

			popup,

			"scale",

			Vector2.ONE,

			0.25

		).set_trans(Tween.TRANS_BACK)\

		.set_ease(Tween.EASE_OUT)\

		.set_delay(delay)
 
	else:
 
		tween.tween_property(

			popup,

			"scale",

			Vector2.ZERO,

			0.20

		).set_trans(Tween.TRANS_BACK)\

		.set_ease(Tween.EASE_IN)\

		.set_delay(delay)
 
		tween.tween_callback(func():

			popup.visible = false

		)
 