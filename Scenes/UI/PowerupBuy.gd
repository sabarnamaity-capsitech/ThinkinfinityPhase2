extends Control
@export var previewBtn : TextureButton
@export var hintBtn : TextureButton
@export var freezeBtn : TextureButton
@export var closeBtn: TextureButton
var powerup_data = {}
# Called when the node enters the scene tree for the first time.
func _ready():

	powerup_data = {
		previewBtn: {
			"type": "preview",
			"price": 1000,
			"amount": 1
		},

		hintBtn: {
			"type": "hint",
			"price": 1500,
			"amount": 1
		},

		freezeBtn: {
			"type": "freeze",
			"price": 2000,
			"amount": 1
		}
	}
	previewBtn.pressed.connect(_on_powerup_pressed.bind(previewBtn))
	hintBtn.pressed.connect(_on_powerup_pressed.bind(hintBtn))
	freezeBtn.pressed.connect(_on_powerup_pressed.bind(freezeBtn))
	closeBtn.pressed.connect(_onCloseBtnPressed)


func _on_powerup_pressed(button):

	var data = powerup_data[button]
	var price = data["price"]
	var amount = data["amount"]
	var type = data["type"]

	if GameManager.instance.get_total_coin() < price:
		print("Not Enough Coins")
		return

	GameManager.instance.set_total_coin(
		GameManager.instance.get_total_coin() - price
	)

	var count = GameManager.instance.get_powerup(type)

	GameManager.instance.set_powerup(
		type,
		count + amount
	)

	print(type, "Bought")

func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.hide_popup()