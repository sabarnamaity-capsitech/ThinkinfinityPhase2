extends Node

const PLUGIN_NAME := "MetaSdkPlugin"

var _plugin = null


func _ready() -> void:
	if Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)
		print("[MetaSdk] Plugin ready ✅")
		
		print("[MetaSdk] Sending event: Godot_Build")
		_plugin.log_event("Godot_Build")   # ← fire immediately here, guaranteed not null
	else:
		print("[MetaSdk] Plugin NOT found — running on editor or non-Android platform.")


func init(debug: bool = false) -> void:
	
	pass  # no longer needed, kept so existing calls don't break


func log_event(event_name: String) -> void:
	if _plugin == null:
		return
	_plugin.log_event(event_name)


func log_event_with_value(event_name: String, value: float) -> void:
	if _plugin == null:
		return	
	_plugin.log_event_with_value(event_name, value)
