extends Node

var analytics

func _ready():
	if OS.has_feature("editor"):
		return
	print("ANALYTICS SCRIPT STARTED")
	analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
	analytics.initialize()
	
	print("Analytics Singleton = ", analytics)

	if analytics == null:
		print("FIREBASE ANALYTICS NOT FOUND (Mocking active for non-mobile platforms)")
	else:
		print("FIREBASE ANALYTICS FOUND")


func _log_event_internal(event_name: String, params: Dictionary) -> void:
	if analytics:
		analytics.log_event(event_name, params)
	else:
		print("[FirebaseAnalytics Mock] Logged event: '%s' with params: %s" % [event_name, str(params)])



func level_start(level: int):
	_log_event_internal(
		"level_start",
		{
			"level": level
		}
	)


func level_complete(level: int, stars: int):
	_log_event_internal(
		"level_complete",
		{
			"level": level,
			"stars": stars
		}
	)


func level_failed(level: int):
	_log_event_internal(
		"level_failed",
		{
			"level": level
		}
	)


func eye_powerup_used(level: int):
	_log_event_internal(
		"eye_powerup_used",
		{
			"level": level
		}
	)


func map_powerup_used(level: int):
	_log_event_internal(
		"map_powerup_used",
		{
			"level": level
		}
	)


func restart_powerup_used(level: int):
	_log_event_internal(
		"restart_powerup_used",
		{
			"level": level
		}
	)
	
func level_retry(level: int):
	_log_event_internal(
		"level_retry",
		{
			"level": level
		}
	)
