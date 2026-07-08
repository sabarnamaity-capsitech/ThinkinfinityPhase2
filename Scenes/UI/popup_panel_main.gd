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
 




# func _toggle_popup(popup : Control, show : bool, delay := 0.0):
 
# 	popup.pivot_offset = popup.size * 0.5
 
# 	var tween = create_tween()
 
# 	if show:
 
# 		popup.visible = true

# 		popup.scale = Vector2.ZERO
 
# 		tween.tween_property(

# 			popup,

# 			"scale",

# 			Vector2.ONE,

# 			0.25

# 		).set_trans(Tween.TRANS_BACK)\

# 		.set_ease(Tween.EASE_OUT)\

# 		.set_delay(delay)
 
# 	else:
 
# 		tween.tween_property(

# 			popup,

# 			"scale",

# 			Vector2.ZERO,

# 			0.20

# 		).set_trans(Tween.TRANS_BACK)\

# 		.set_ease(Tween.EASE_IN)\

# 		.set_delay(delay)
 
# 		tween.tween_callback(func():

# 			popup.visible = false

# 		)
func _toggle_popup(popup: Control, show: bool):
	var panel: Panel = null

	for child in popup.get_children():
		if child is Panel:
			panel = child
			break

	if panel == null:
		return

	panel.pivot_offset = panel.size * 0.5

	var start_pos := panel.position
	var start_scale := panel.scale

	if show:
		popup.visible = true

		# Initial state
		panel.position = start_pos + Vector2(0, -300)
		panel.scale = start_scale * 0.2
		panel.rotation_degrees = -8
		panel.modulate.a = 0.0

		var tween = create_tween()

		# Stage 1
		tween.set_parallel(true)

		tween.tween_property(panel, "position", start_pos + Vector2(0, 25), 0.20)\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_OUT)

		tween.tween_property(panel, "scale", start_scale * 1.12, 0.20)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

		tween.tween_property(panel, "rotation_degrees", 2.0, 0.20)

		tween.tween_property(panel, "modulate:a", 1.0, 0.12)

		# Stage 2
		tween.chain()

		tween.tween_property(panel, "position", start_pos - Vector2(0, 10), 0.10)\
			.set_trans(Tween.TRANS_SPRING)\
			.set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(panel, "scale", start_scale * 0.97, 0.10)

		tween.parallel().tween_property(panel, "rotation_degrees", -1.0, 0.10)

		# Stage 3
		tween.chain()

		tween.tween_property(panel, "position", start_pos, 0.08)

		tween.parallel().tween_property(panel, "scale", start_scale, 0.08)

		tween.parallel().tween_property(panel, "rotation_degrees", 0.0, 0.08)
		animate_buttons(panel)
	else:
		var tween = create_tween()

		tween.set_parallel(true)

		tween.tween_property(panel, "position", start_pos + Vector2(0, -180), 0.18)\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_IN)

		tween.tween_property(panel, "scale", start_scale * 0.5, 0.18)

		tween.tween_property(panel, "rotation_degrees", 6.0, 0.18)

		tween.tween_property(panel, "modulate:a", 0.0, 0.15)

		await tween.finished

		panel.position = start_pos
		panel.scale = start_scale
		panel.rotation_degrees = 0
		panel.modulate.a = 1.0

		popup.visible = false

func animate_buttons(panel: Control):
	var tween = create_tween()

	for child in panel.get_children():
		if child is Button:
			var btn := child as Button
			var original := btn.scale

			btn.scale = Vector2.ZERO

			tween.tween_property(btn, "scale", original * 1.15, 0.12)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)

			tween.tween_property(btn, "scale", original, 0.08)\
				.set_trans(Tween.TRANS_BOUNCE)\
				.set_ease(Tween.EASE_OUT)

			tween.tween_interval(0.03)	