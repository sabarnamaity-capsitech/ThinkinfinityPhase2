extends TextureButton

@export var coin_id : int = 0
@export var coin_amount : int = 1000
@export var coin_price : int = 99

@export var coinBuyBtn : TextureButton
@export var _coins : Label
@export var coinpriceLabel : Label

func _ready():
	coinBuyBtn.pressed.connect(buy_coin)
	coinpriceLabel.text = str(coin_amount)
	update_state()

func update_state():

	if GameManager.instance.is_coin_pack_bought(coin_id):
		coinBuyBtn.disabled = true
		coinBuyBtn.modulate = Color(0.5, 0.5, 0.5, 1.0) # Dark
	else:
		coinBuyBtn.disabled = false
		coinBuyBtn.modulate = Color.WHITE
		
func buy_coin():

	if GameManager.instance.is_coin_pack_bought(coin_id):
		return
	var total = GameManager.instance.get_total_coin()
	GameManager.instance.set_total_coin(total + coin_amount)
	GameManager.instance.buy_coin_pack(coin_id)
	_coins.text = str(GameManager.instance.get_total_coin())
	update_state()
	print("Coins Added")
