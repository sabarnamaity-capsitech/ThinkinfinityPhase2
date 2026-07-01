extends Control
class_name StartPanelController

@export var setting_Btn: TextureButton
@export var start_Btn: TextureButton

func _ready():
	setting_Btn.pressed.connect(_on_setting_pressed)
	start_Btn.pressed.connect(_on_start_pressed)

func _on_setting_pressed():
	print("Settings Button Pressed")
	


func _on_start_pressed():
	print("Start Button Pressed")
	
