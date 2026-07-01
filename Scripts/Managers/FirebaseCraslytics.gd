extends Node

var crashlytics

func _ready():
	if OS.has_feature("editor"):
		return
	crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
	print("Crashlytics = ", crashlytics)
	crashlytics.initialize()


func set_level(level:int):

	if crashlytics == null:
		return

	FirebaseCrashlyticsHelper.set_custom_value(
		crashlytics,
		"current_level",
		level
	)


func set_stars(stars:int):

	if crashlytics == null:
		return

	FirebaseCrashlyticsHelper.set_custom_value(
		crashlytics,
		"stars",
		stars
	)


func set_last_action(action:String):

	if crashlytics == null:
		return

	FirebaseCrashlyticsHelper.set_custom_value(
		crashlytics,
		"last_action",
		action
	)
