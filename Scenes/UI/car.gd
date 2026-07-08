extends TextureButton

@export var car_id : int = 0
@export var car_price : int = 0
@onready var lock_icon = $Lock
@onready var unlock_icon = $Unlock

func _ready():
	update_state()

func update_state():

	if GameManager.instance.is_car_owned(car_id):
		lock_icon.hide()
		unlock_icon.show()
	else:
		lock_icon.show()
		unlock_icon.hide()
# @export var is_purchased : bool = false