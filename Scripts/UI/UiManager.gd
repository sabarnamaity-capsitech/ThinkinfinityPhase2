extends CanvasLayer
class_name UiManager
 
static var instance: UiManager = null
var ui_callback : UICallBack
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
@export_group("Screen Scenes")
@export var main_menu_scene: PackedScene
@export var level_screen_scene: PackedScene
@export var game_scene : Control
 

@export_group("Popup Scenes")
@export var pause_popup_scene: PackedScene
@export var settings_popup_scene: PackedScene
@export var win_popup_scene: PackedScene
@export var lose_popup_scene: PackedScene
@export var tutorial_popup_scene: PackedScene
@export var hint_popup_scene: PackedScene
@export var credit_popup_scene: PackedScene
 

@export_group("All Layers")
@export var screen_layer : Control
@export var popup_layer : Control
 
 
var screen_scenes := {}
var popup_scenes := {}
 
 

var current_screen : Node = null
 
var popup_stack : Array[Node] = []





func _init():
    ui_callback = UICallBack.new()
 
 
 
func _enter_tree() -> void:
    instance = self
 
func _ready() -> void:
 
    process_mode = Node.PROCESS_MODE_ALWAYS
 
    screen_scenes = {
        ScreenType.Screen.MAIN_MENU: main_menu_scene,
        ScreenType.Screen.LEVEL_SCREEN: level_screen_scene
    }
 
    popup_scenes = {
        ScreenType.popup.PAUSE_POPUP: pause_popup_scene,
        ScreenType.popup.SETTINGS_POPUP: settings_popup_scene,
        ScreenType.popup.WIN_POPUP: win_popup_scene,
        ScreenType.popup.LOSE_POPUP: lose_popup_scene,
        ScreenType.popup.TUTORIAL_POPUP: tutorial_popup_scene,
        ScreenType.popup.HINT_POPUP: hint_popup_scene,
    }
 
    switch_screen(ScreenType.Screen.MAIN_MENU)
    if GameManager.instance.is_first_time:
        show_popup(ScreenType.popup.TUTORIAL_POPUP)
        GameManager.instance.is_first_time = false
   
 
func switch_screen(screen_type : ScreenType.Screen) -> void:


    if game_scene:
        game_scene.visible = (screen_type == ScreenType.Screen.GAME_HUD)

    if screen_type == ScreenType.Screen.GAME_HUD:
        if current_screen:
            current_screen.queue_free()
            current_screen = null

            clear_all_popups()
            return

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
 
    if not screen_scenes.has(screen_type) or screen_scenes[screen_type] == null:
        push_error("Screen not registered / not assigned in Inspector")
        return
 

    if current_screen:
        current_screen.queue_free()
        current_screen = null
 
    # clear popups
    clear_all_popups()
 
    var scene : PackedScene = screen_scenes[screen_type]
 
    current_screen = scene.instantiate()
 
    screen_layer.add_child(current_screen)
     
    

 
 
 
func show_popup(popup_type : ScreenType.popup, data : Dictionary = {}) -> void:
    if not popup_scenes.has(popup_type) or popup_scenes[popup_type] == null:
        push_error("Popup not registered / not assigned in Inspector")
        return
 
    var scene : PackedScene = popup_scenes[popup_type]
 
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
 
 
 
func get_current_screen() -> Node:
    return current_screen
 
 
func has_popup() -> bool:
    return popup_stack.size() > 0