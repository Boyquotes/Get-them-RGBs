extends Area2D

signal touched

@export var player_speed = 3
var is_dead = true


func _physics_process(_delta):
	var tmp_position = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		tmp_position.y -= 1
	if Input.is_action_pressed("move_down"):
		tmp_position.y += 1
	if Input.is_action_pressed("move_left"):
		tmp_position.x -= 1
	if Input.is_action_pressed("move_right"):
		tmp_position.x += 1
	
	if tmp_position != Vector2.ZERO:
		tmp_position = tmp_position.normalized()
	position += tmp_position * player_speed


func initialize(state):
	if state == Enum.BeingState.ALIVE:
		is_dead = false
	else:
		is_dead = true
	position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)
	$MeshInstance2D.texture.get_gradient().set_color(0, Color(Color.WHITE))

func is_out_of_bounds(vp_size) -> bool:
	if position.x < 0 or position.x > vp_size.x or position.y < 0 or position.y > vp_size.y:
		return true
	return false
