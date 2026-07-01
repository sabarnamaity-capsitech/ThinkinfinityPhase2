extends Control
 
class_name PreviewOverlay
 
@onready var image =$PreviewImage
# @onready var timer_label =$Label
@onready var hand = $Clock/hand
@onready var loader = $Clock/loader
@export var levelNumber :Label
@export var bg: TextureRect
		
 
func _ready():
	pass
	# UIController.instance.ui_callback.update_level.connect(_onLevelStart)
# func show_preview(texture: Texture2D, duration := 5.0):
 
#   visible = true
 
#   image.texture = texture
 
#   for i in range(duration, 0, -1):
 
#       # timer_label.text = str(i)
#       await get_tree().create_timer(1.0).timeout
 
#   visible = false
#   GameManager.instance.level_generator.timer_started = true
func _onLevelStart() -> void:
	levelNumber.text = tr("Level")+ ":" + str(GameManager.instance.current_level + 1)
func show_preview(texture: Texture2D, duration := 5.0):
 
	visible = true
	image.texture = texture
 
	loader.value = 0
	hand.rotation_degrees = 0
 
	var elapsed := 0.0
 
	while elapsed < duration:
 
		var progress = elapsed / duration
 
		# Loader fill
		loader.value = progress * 100
 
		# Hand rotate
		hand.rotation_degrees = progress * 360
 
		await get_tree().process_frame
		elapsed += get_process_delta_time()
 
	# Ensure complete
	loader.value = 100
	hand.rotation_degrees = 360
 
	visible = false
 
	GameManager.instance.level_generator.timer_started = true
	UIController.instance.ui_callback.preview_pressed(true)
