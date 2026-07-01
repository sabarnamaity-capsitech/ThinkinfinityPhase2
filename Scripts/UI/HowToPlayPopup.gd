extends BaseScreen

@onready var _closeBtn = $PopupPanel/Header/CloseButton
@onready var popup_panel = $PopupPanel



func _onCloseBtnPressed() -> void:
	SoundManager.play_click()
	reset_tutorial()
	UIController.instance.close_popup()
	pass

# --------------------------
# SWIPE SETTINGS
# --------------------------


var current_page := 0

var swipe_start := Vector2.ZERO
var is_dragging := false
var is_animating := false

const SWIPE_THRESHOLD := 80

# --------------------------
# DOT TEXTURES
# --------------------------

const BLUE_DOT = preload("res://assets/ThinkfinityAsset/Art/DesignMaterial/Ellipse 168.png")
const WHITE_DOT = preload("res://assets/ThinkfinityAsset/Art/DesignMaterial/Ellipse 169.png")

# --------------------------
# PAGE REFERENCES
# --------------------------

@onready var pages = [
	$PopupPanel/TutorialPages/Page1,
	$PopupPanel/TutorialPages/Page2,
	$PopupPanel/TutorialPages/Page3
]

@onready var dots = [
	$PopupPanel/DotsContainer/Dot1,
	$PopupPanel/DotsContainer/Dot2,
	$PopupPanel/DotsContainer/Dot3
]

# --------------------------
# READY
# --------------------------

func _ready():
	GameManager.instance.tutorial_open_count += 1

	#screen_type = ScreenType.Type.TUTORIAL_POPUP
	print("Tutorial opened: ", GameManager.instance.tutorial_open_count)

	if GameManager.instance.tutorial_open_count >= 3:
		GameManager.instance.tutorial_open_count = 0

		print("Checking interstitial")

		if AdMob.is_interstitial_available():
			print("Showing interstitial")
			AdMob.show_interstitial()
		else:
			print("Interstitial not ready")

	#screen_type = ScreenType.Type.TUTORIAL_POPUP
   


	if _closeBtn:
		_closeBtn.pressed.connect(_onCloseBtnPressed)

	for i in range(pages.size()):
		pages[i].visible = (i == 0)
		pages[i].position.x = 0


	for i in range(dots.size()):
		dots[i].pivot_offset = dots[i].size / 2
		dots[i].scale = Vector2(1.0, 1.0)

	current_page = 0

	update_dots()

# --------------------------
# CLOSE
# --------------------------



# --------------------------
# DOTS
# --------------------------

func update_dots():

	for i in range(dots.size()):

		if i == current_page:
			dots[i].texture = BLUE_DOT
			dots[i].pivot_offset = dots[i].size / 2
			var tween = create_tween()
			tween.tween_property(dots[i], "scale", Vector2(1.3, 1.3), 0.3)
		else:
			dots[i].texture = WHITE_DOT
			dots[i].pivot_offset = dots[i].size / 2
			var tween = create_tween()
			tween.tween_property(dots[i], "scale", Vector2(1.0, 1.0), 0.3)

# --------------------------
# PAGE NAVIGATION
# --------------------------

func next_page():

	if current_page >= pages.size() - 1:
		return

	show_page(current_page + 1)

func previous_page():

	if current_page <= 0:
		return

	show_page(current_page - 1)

# --------------------------
# PAGE TRANSITION
# --------------------------

func show_page(index):

	if is_animating:
		return

	if index < 0 or index >= pages.size():
		return

	if index == current_page:
		return

	is_animating = true

	var old_page = pages[current_page]
	var new_page = pages[index]

	var direction = 1

	if index > current_page:
		direction = 1
	else:
		direction = -1

	var width = popup_panel.size.x

	new_page.visible = true

	new_page.position.x = direction * width

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		old_page,
		"position:x",
		-direction * width,
		0.25
	)

	tween.tween_property(
		new_page,
		"position:x",
		0,
		0.25
	)

	await tween.finished

	old_page.visible = false
	old_page.position.x = 0

	current_page = index

	update_dots()

	is_animating = false

# --------------------------
# SNAP BACK
# --------------------------
func reset_tutorial():

	current_page = 0

	for i in range(pages.size()):

		pages[i].visible = (i == 0)
		pages[i].position.x = 0

	update_dots()
func reset_current_page_position():

	var tween = create_tween()

	tween.tween_property(
		pages[current_page],
		"position:x",
		0,
		0.15
	)

# --------------------------
# INPUT
# --------------------------

func _input(event):

	if is_animating:
		return

	# --------------------------------
	# MOBILE TOUCH START / END
	# --------------------------------

	if event is InputEventScreenTouch:

		if event.pressed:

			swipe_start = event.position
			is_dragging = true

		else:

			if not is_dragging:
				return

			is_dragging = false

			var delta_x = event.position.x - swipe_start.x

			if abs(delta_x) > SWIPE_THRESHOLD:

				if delta_x < 0:
					next_page()
				else:
					previous_page()

			else:

				reset_current_page_position()

	# --------------------------------
	# MOBILE DRAG
	# --------------------------------

	elif event is InputEventScreenDrag:

		if not is_dragging:
			return

		var delta_x = event.position.x - swipe_start.x

		# First page - block dragging to right
		if current_page == 0 and delta_x > 0:
			pages[current_page].position.x = delta_x * 0.05
			return

		# Last page - block dragging to left
		if current_page == pages.size() - 1 and delta_x < 0:
			pages[current_page].position.x = delta_x * 0.05
			return

		pages[current_page].position.x = delta_x * 0.20

	# --------------------------------
	# MOUSE START / END
	# --------------------------------

	elif event is InputEventMouseButton:

		if event.pressed:

			swipe_start = event.position
			is_dragging = true

		else:

			if not is_dragging:
				return

			is_dragging = false

			var delta_x = event.position.x - swipe_start.x

			if abs(delta_x) > SWIPE_THRESHOLD:

				if delta_x < 0:
					next_page()
				else:
					previous_page()

			else:

				reset_current_page_position()

	# --------------------------------
	# MOUSE DRAG (EDITOR TESTING)
	# --------------------------------

	elif event is InputEventMouseMotion:

		if not is_dragging:
			return

		var delta_x = event.position.x - swipe_start.x

		# First page
		if current_page == 0 and delta_x > 0:
			return

		# Last page
		if current_page == pages.size() - 1 and delta_x < 0:
			return

		pages[current_page].position.x = delta_x * 0.20
