class_name Hint
extends Node
var half_hint_used := false

func use_half_hint():

	if half_hint_used:
		return false

	var board = GameManager.instance.level_generator

	var incorrect_pieces = board.get_incorrect_pieces()

	if incorrect_pieces.is_empty():
		return false

	var total_pieces = board.get_total_piece_count()
	var current_correct = board.get_correct_piece_count()

	var target_correct = ceili(total_pieces * 0.5)

	var pieces_to_fix = target_correct - current_correct

	pieces_to_fix = max(1, pieces_to_fix)
	print("===== HALF HINT =====")
	print("Total Pieces: ", total_pieces)
	print("Current Correct: ", current_correct)
	print("Target Correct: ", target_correct)
	print("Need To Solve: ", pieces_to_fix)

	incorrect_pieces.shuffle()

	for i in min(pieces_to_fix, incorrect_pieces.size()):

		board.solve_piece(
			incorrect_pieces[i]
		)

	half_hint_used = true

	# board.check_win()

	return true
	
func use_full_hint() -> bool:
	var board = GameManager.instance.level_generator
	# board.timer_started=false
	board.show_solution_preview()
	return true
func reset_hints() -> void:
	half_hint_used = false
