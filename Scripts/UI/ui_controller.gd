
extends Node2D
class_name UIController

static var instance: UIController = null
var ui_callback : UICallBack
@export var backgrounds: Array[Sprite2D] = []
var first_main_menu_load := true
#Supriyo logic
#@export var screens: Array[BaseScreen] = []
#@export var popups: Array[BaseScreen] = []
#
#var _screens_dict: Dictionary = {}
#var _popups_dict: Dictionary = {}
#
##popupstack
#var _popup_stack: Array[ScreenType.Type] = []
#
#var _current_screen: BaseScreen = null
#var _current_popup: BaseScreen = null
func _init():
	ui_callback = UICallBack.new()
	
var screen_paths := {
	ScreenType.Screen.MAIN_MENU: "res://Scenes/UI/MainMenuScene.tscn",
	ScreenType.Screen.GAME_HUD: "res://Scenes/UI/GameSceneUI.tscn",
	ScreenType.Screen.LEVEL_SCREEN: "res://Scenes/UI/LevelScene.tscn"
}

var popup_paths := {
	ScreenType.popup.PAUSE_POPUP: "res://Scenes/UI/Popups/pause_popup.tscn",
	ScreenType.popup.SETTINGS_POPUP: "res://Scenes/UI/Popups/SettingsPopup.tscn",
	ScreenType.popup.WIN_POPUP: "res://Scenes/UI/Popups/WinnerPopUp.tscn",
	ScreenType.popup.LOSE_POPUP:"res://Scenes/UI/Popups/FailurePopup.tscn",
	ScreenType.popup.TUTORIAL_POPUP: "res://Scenes/UI/Popups/InformationPopup.tscn",
	ScreenType.popup.HINT_POPUP:"res://Scenes/UI/Popups/HintPopup.tscn",
	ScreenType.popup.CREDIT_POPUP:"res://Scenes/UI/Popups/CreditPopup.tscn"
}
@export var screen_layer : Node
@export var popup_layer : Node


	
signal updateScore
var current_screen : Node = null

var popup_stack : Array[Node] = []

func _enter_tree() -> void:
	instance = self
func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	switch_screen(ScreenType.Screen.MAIN_MENU)
	if GameManager.instance.is_first_time:
		show_popup(ScreenType.popup.TUTORIAL_POPUP)
		GameManager.instance.is_first_time = false
	#initialize_ui()
	#connect_to_game_signals()










# =====================================================
# SCREENS
# =====================================================

func switch_screen(screen_type : ScreenType.Screen) -> void:
	if screen_type == ScreenType.Screen.MAIN_MENU:

		if first_main_menu_load:
			first_main_menu_load = false
		else:

			GameManager.instance.home_return_count += 1

			print(
				"Home Return Count: ",
				GameManager.instance.home_return_count
			)

			# Show ad on 6th return
			if GameManager.instance.home_return_count >= 6:

				GameManager.instance.home_return_count = 0

				if AdMob.is_interstitial_available():
					print("Showing Home Interstitial")
					AdMob.show_interstitial()
				else:
					print("Interstitial not ready")

	if not screen_paths.has(screen_type):
		push_error("Screen not registered")
		return

	# remove current screen
	if current_screen:
		current_screen.queue_free()
		current_screen = null

	# clear popups
	clear_all_popups()

	var scene : PackedScene = load(screen_paths[screen_type])

	current_screen = scene.instantiate()

	screen_layer.add_child(current_screen)


# =====================================================
# POPUPS
# =====================================================

func show_popup(popup_type : ScreenType.popup,data : Dictionary = {}) -> void:
	if not popup_paths.has(popup_type):
		push_error("Popup not registered")
		return

	var scene : PackedScene = load(
		popup_paths[popup_type]
	)

	var popup = scene.instantiate()

	popup_layer.add_child(popup)

	if popup.has_method("set_data"):
		popup.set_data(data)

	popup_stack.push_back(popup)


func close_popup() -> void:

	if popup_stack.is_empty():
		return

	var popup = popup_stack.pop_back()

	if is_instance_valid(popup):
		popup.queue_free()


func clear_all_popups() -> void:

	for popup in popup_stack:

		if is_instance_valid(popup):
			popup.queue_free()

	popup_stack.clear()


# =====================================================
# HELPERS
# =====================================================

func get_current_screen() -> Node:
	return current_screen


func has_popup() -> bool:
	return popup_stack.size() > 0
	
	# supriyo logic
#===== Initialize all screens and popups =====
#func initialize_ui() -> void:
#
	## Register screens
	#for screen in screens:
		#if screen == null:
			#continue
		#_screens_dict[screen.screen_type] = screen
		#screen.hide_immediate()
	#
	## Register popups
	#for popup in popups:
		#if popup == null:
			#continue
		#_popups_dict[popup.screen_type] = popup
		#popup.hide_immediate()
	#
	##test for now - to remove later
	#switch_screen(ScreenType.Type.MAIN_MENU)



#===== Connect to game signals =====
#func connect_to_game_signals() -> void:
	#_event_bus = get_tree().root.get_child(0)  # Assuming game is first child
		
	#---Connect various game signals---
	#if _event_bus:		 
		#if _event_bus.has_signal("game_started"):
			#_event_bus.game_started.connect(_on_game_started)	
		#if _event_bus.has_signal("game_paused"):
			#_event_bus.game_paused.connect(_on_game_paused)	
		#if _event_bus.has_signal("game_lost"):
			#_event_bus.game_lost.connect(_on_game_lost)	
		#if _event_bus.has_signal("game_won"):
			#_event_bus.game_won.connect(_on_game_won)
		


# ============================================
# PUBLIC APIs
# ============================================

# 1. Screen Switch
#func switch_screen(screen_type: ScreenType.Type) -> void:
	#if screen_type == ScreenType.Type.NONE:
		#return	
	#if not _screens_dict.has(screen_type):
		#push_error("Screen type %s not found in registry" % screen_type)
		#return
	#
	#var new_screen = _screens_dict[screen_type]	
	##clearing popup and its stack---
	#if _current_popup:
		#_current_popup.hidee()	
	#_popup_stack.clear()
	#_current_popup = null
	#
	#if _current_screen:
		#_current_screen.hidee()
	#new_screen.show()
	#_current_screen = new_screen
#
#
## 2. Popup open
#func show_popup(popup_type: ScreenType.Type, data: Dictionary = {}) -> void:	
	#if popup_type == ScreenType.Type.NONE:
		#return	
	#if not _popups_dict.has(popup_type):
		#push_error("Popup type %s not found in registry" % popup_type)
		#return	
	#var new_popup = _popups_dict[popup_type]
	#
	## Prevent duplicate popups
	#if _current_popup and _current_popup.screen_type == popup_type:
		#return	
	#if _current_popup:
		#_popup_stack.append(_current_popup.screen_type)
		#_current_popup.hidee()
	#
	## Pass data to popup if it has a method
	#if data and new_popup.has_method("set_data"):
		#new_popup.set_data(data)	
	#new_popup.show()
	#_current_popup = new_popup



# 3. Popup close (Go back to previous)
#func go_back() -> void:
	#
	## If popup is open, close it first
	#if _current_popup:
		#_current_popup.hidee()
		#
		#if _popup_stack.size() > 0:
			#var prev_popup_type = _popup_stack.pop_back()
			#var prev_popup = _popups_dict[prev_popup_type]
			#prev_popup.show()
			#_current_popup = prev_popup
		#else:
			#_current_popup = null
		#return
#
## 4. Hide current (Hide current popup without going back)
#
#func hide_current_popup() -> void:
	#if _current_popup:
		#_current_popup.hidee()
		#_current_popup = null
#
#
## helper methods
#func get_current_screen() -> BaseScreen:
	#return _current_screen
#
#func get_current_popup() -> BaseScreen:
	#return _current_popup
#
#func set_starting_screen(screen_type: ScreenType.Type) -> void:
	#call_deferred("switch_screen", screen_type)




# ============================================
# GAME SIGNAL HANDLERS
# ============================================

#func _on_game_started(mode: String) -> void:
	#switch_screen(ScreenType.Type.GAME_HUD)

#func _on_game_paused() -> void:
	#show_popup(ScreenType.Type.PAUSE_POPUP)

#func _on_game_lost(score: int) -> void:
	#show_popup(ScreenType.Type.LOSS_POPUP, {"score": score})

#func _on_game_won(score: int) -> void:
	#show_popup(ScreenType.Type.WIN_POPUP, {"score": score})
