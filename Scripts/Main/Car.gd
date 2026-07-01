extends Node2D
class_name CarController

@export var car: Sprite2D

var follow: PathFollow2D
var moving := false

var path_length: float = 0.0
var car_speed: float = 0.0
var current_speed: float = 0.0
@export var TRAVEL_TIME := 1.0
@export var winConfeti: GPUParticles2D
@export var smoke: GPUParticles2D




func _process(delta: float) -> void:
	update_car(delta)


func start(path_follow: PathFollow2D, actual_size_ofImage: Vector2) -> void:
	moving = false
	visible = false

	follow = path_follow
	if follow == null:
		return

	follow.loop = false
	follow.rotates = true
	follow.progress = 0.0

	await get_tree().process_frame

	path_length = follow.get_parent().curve.get_baked_length()

	var start_pos := follow.global_position

	follow.progress = min(10.0, path_length)

	await get_tree().process_frame

	var next_pos := follow.global_position

	# Back to start
	follow.progress = 0.0

	await get_tree().process_frame

	car.global_position = start_pos
	

	if start_pos.distance_to(next_pos) > 0.01:
		car.global_rotation = (next_pos - start_pos).angle() + deg_to_rad(90)
	else:
		car.global_rotation = follow.global_rotation + deg_to_rad(90)

	car.scale = Vector2.ONE * 0.2

	smoke.emitting=false
	smoke.visible=false
	
	if path_length <= 10:
		car_speed = 1500
	elif path_length <= 30:
		car_speed = 1800
	elif path_length <= 60:
		car_speed = 2000
	else:
		car_speed = 2400

	current_speed = car_speed * 0.25

	visible = true
	smoke.restart()
	smoke.emitting = true
	smoke.visible = true
	await get_tree().create_timer(1.8).timeout
	# smoke.restart()
	smoke.emitting = true
	smoke.visible = true
	moving=true


func stop() -> void:
	moving = false


func update_car(delta: float) -> void:
	if not moving or follow == null:
		return

	current_speed = move_toward(
		current_speed,
		car_speed,
		car_speed * 6.0 * delta
	)

	follow.progress += current_speed * delta

	if follow.progress >= path_length:
		follow.progress = path_length

	car.global_position = follow.global_position
	car.global_rotation = follow.global_rotation + deg_to_rad(90)
	  
	if follow.progress >= path_length:

		moving = false
		
		#visible = false
		#GameManager.instance.level_generator.game_win()

		follow.progress = path_length
		winConfeti.global_position=car.global_position
		winConfeti.emitting=true
		moving = false
		
		# cam.enabled = false
		await get_tree().create_timer(1.0).timeout
		visible = false
		smoke.emitting=false
		smoke.visible=false
		GameManager.instance.level_generator.game_win()
