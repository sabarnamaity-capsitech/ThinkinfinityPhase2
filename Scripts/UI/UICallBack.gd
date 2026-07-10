class_name UICallBack


signal  update_color(color,colortwo,texture)
signal update_score(score)
signal update_timer(time_left)
signal update_wintime(type)
signal previewbtn_pressed(type)
signal allLevelBtn
signal level_start(level_index)
signal update_level

signal game_pause
signal game_resume

signal game_win(start_indexValue)
signal show_lose_screen
signal hideallBtn(type)

signal update_coins(coins)

func update_score_ui(score: int) -> void:
	update_score.emit(score)

func update_timer_ui(time_left: float) -> void:
	update_timer.emit(time_left)

func level_start_ui(level_index: int) -> void:
	level_start.emit(level_index)

func update_level_onTop() -> void:
	update_level.emit()


func pause_game_ui() -> void:
	game_pause.emit()

func resume_game_ui() -> void:
	game_resume.emit()

func game_win_ui(start_indexValue: int) -> void:
	game_win.emit(start_indexValue)

func update_color_ui(color: Color,colorTwo: Color,texture : Texture2D) -> void:
	update_color.emit(color,colorTwo,texture)

func show_lose_ui() -> void:
	show_lose_screen.emit()

func  hide_allBtn(type : bool) -> void :
	hideallBtn.emit(type)	


func  win_done(type : bool) -> void :
	update_wintime.emit(type)


func  preview_pressed(type : bool) -> void :
	previewbtn_pressed.emit(type)
		
func update_coins_ui(coins: int) -> void:
	update_coins.emit(coins)


func update_btn_alllevel() ->void:
	allLevelBtn.emit()