extends Panel


enum AnimationStyle {
	SCALE_IN,
	BOUNCE,
	DROP
}


@export var animation_style: AnimationStyle = AnimationStyle.SCALE_IN
@export var animation_duration: float = 0.5
@export var animation_easing: Tween.EaseType = Tween.EASE_OUT
@export var auto_play: bool = true


var tween: Tween = null
var is_animating: bool = false
var initial_position: Vector2

func _ready() -> void:
	
	initial_position = position
	
	pivot_offset = size / 2.0
	
	if auto_play:
		play_open_animation()



func play_open_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(false)
	

	match animation_style:
		AnimationStyle.SCALE_IN:
			_animate_scale_in()
		AnimationStyle.BOUNCE:
			_animate_bounce()
		AnimationStyle.DROP:
			_animate_drop()
	
	await tween.finished
	is_animating = false




# 01
# Scale-In animation: panel starts small and expands with fade in
func _animate_scale_in() -> void:
	# Reset initial state
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	
	# Animate fade in and scale up in parallel
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, animation_duration).set_ease(animation_easing)
	
	# Scale up
	tween.tween_property(self, "scale", Vector2.ONE, animation_duration).set_ease(animation_easing)
	
	tween.set_parallel(false)

# 02
# Bounce animation: overshoots and then settles back
func _animate_bounce() -> void:
	# Reset initial state
	modulate.a = 0.0
	scale = Vector2(0.4, 0.4)
	
	# Fade in first
	tween.tween_property(self, "modulate:a", 1.0, animation_duration * 0.3).set_ease(Tween.EASE_OUT)
	
	# Bounce scale animation: scale up beyond 1.0 then back to 1.0
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), animation_duration * 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, animation_duration * 0.3).set_ease(Tween.EASE_IN)

#03
# Drop animation: falls from above with impact
func _animate_drop() -> void:
	# Calculate start position (above current position)
	var start_position = initial_position - Vector2(0, 300)
	
	# Reset initial state
	modulate.a = 1.0
	scale = Vector2.ONE
	position = start_position
	
	# Drop down quickly
	tween.tween_property(self, "position", initial_position, animation_duration).set_ease(Tween.EASE_IN)
	
	# Impact effect: slight scale pulse on landing
	tween.tween_property(self, "scale", Vector2(1.05, 0.95), animation_duration * 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, animation_duration * 0.1).set_ease(Tween.EASE_IN)



# Close the popup with reverse animation
func play_close_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, animation_duration * 0.5).set_ease(Tween.EASE_IN)
	
	# Scale down
	tween.tween_property(self, "scale", Vector2(0.7, 0.7), animation_duration * 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	is_animating = false
	queue_free()


func is_playing() -> bool:
	return is_animating


func stop_animation() -> void:
	if tween:
		tween.kill()
	is_animating = false
