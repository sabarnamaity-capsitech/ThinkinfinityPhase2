extends Control

@export var selected_image:TextureRect#for car
@export var selectedCoinImage:TextureRect#for coin
@export var carSelection_grid:GridContainer
@export var coinSelection_grid:GridContainer
@export var closeBtn: TextureButton
@export var _coins:Label
@export var buyBtn:TextureButton
@export var btnlabel:Label
@export var priceLabel:Label#for car
@export var coinpriceLabel:Label#for coin
@export var coinsTabBtn:TextureButton
@export var carsTabBtn:TextureButton
@export var carSelectionPanel: TextureRect
@export var coinSelectionPanel: TextureRect
# @export var coinBuyBtn:TextureButton


var selected_car
var selected_coin


func _ready():
	UiManager.instance.ui_callback.update_coins.connect(_on_update_coins)
	_coins.text=str(GameManager.instance.get_total_coin())
	closeBtn.pressed.connect(_onCloseBtnPressed)
	buyBtn.pressed.connect(_on_buy_pressed)
	# coinBuyBtn.pressed.connect(buy_coin)
	coinsTabBtn.pressed.connect(_on_coins_tab_pressed)
	carsTabBtn.pressed.connect(_on_cars_tab_pressed)
	for coin in coinSelection_grid.get_children():
		coin.pressed.connect(_on_coin_pressed.bind(coin))
	for car in carSelection_grid.get_children():
		car.pressed.connect(_on_car_pressed.bind(car))


func _on_coins_tab_pressed():
	selected_image.hide()
	selectedCoinImage.show()
	carSelectionPanel.hide()
	coinSelectionPanel.show()
	animate_grid(coinSelection_grid)
func _on_cars_tab_pressed():
	selected_image.show()
	selectedCoinImage.hide()
	carSelectionPanel.show()
	coinSelectionPanel.hide()
	animate_grid(carSelection_grid)
func _on_car_pressed(car):

	selected_car = car

	selected_image.texture = car.get_node("TextureRect2").texture
	priceLabel.text = str(selected_car.car_price)
	update_buy_button()
func _on_coin_pressed(coin):
	selected_coin = coin
	selectedCoinImage.texture = coin.get_node("TextureRect").texture
	coinpriceLabel.text = str(selected_coin.coin_price)
	# update_buy_button()

func _on_update_coins(coins):
	_coins.text=str(coins)

func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	UiManager.instance.hide_popup()

func buy_coin():

	if selected_coin == null:
		return

	var total = GameManager.instance.get_total_coin()

	GameManager.instance.set_total_coin(
		total + selected_coin.coin_amount
	)

	_coins.text = str(GameManager.instance.get_total_coin())

	print("Coins Added")

func _on_buy_pressed():#function to buy or select car

	if selected_car == null:
		return

	# if car present in owned cars
	if GameManager.instance.is_car_owned(selected_car.car_id):
		if GameManager.instance.get_selected_car() == selected_car.car_id:
			print("Already Selected")
			return
		GameManager.instance.set_selected_car(selected_car.car_id)#selectingcar
		update_buy_button()
		print("Car Selected")
		return
	if GameManager.instance.get_total_coin() < selected_car.car_price:
		print("Not Enough Coins")
		return
	GameManager.instance.set_total_coin(
		GameManager.instance.get_total_coin() - selected_car.car_price
	)
	_coins.text = str(GameManager.instance.get_total_coin())
	# Car unlock
	GameManager.instance.buy_car(selected_car.car_id)
	selected_car.update_state()
	update_buy_button()
	print("Car Purchased")

func update_buy_button():
	if selected_car == null:
		return
	if !GameManager.instance.is_car_owned(selected_car.car_id):
		btnlabel.text = "BUY"
	elif GameManager.instance.get_selected_car() == selected_car.car_id:
		btnlabel.text = "SELECTED"
		print("Selected")
	else:
		btnlabel.text = "SELECT"

func animate_grid(grid: GridContainer):
	var delay := 0.0

	for item in grid.get_children():
		item.modulate.a = 0.0
		item.scale = Vector2(0.8, 0.8)

		var tween = create_tween()
		tween.set_parallel(true)

		tween.tween_property(item, "modulate:a", 1.0, 0.25).set_delay(delay)

		tween.tween_property(item, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)\
			.set_delay(delay)

		delay += 0.08
func play_shop_animation():
	if carSelectionPanel.visible:
		animate_grid(carSelection_grid)

	if coinSelectionPanel.visible:
		animate_grid(coinSelection_grid)