extends RigidBody2D

var target

func _physics_process(delta):
	# Moves the enemy towards the player
	look_at(target.global_position)
	var dir = (target.global_position - global_position).normalized()
	global_position += dir * 10 * delta * get_enemy_speed(global_position, target.global_position)


func set_target(new_tg):
	target = new_tg

func get_enemy_speed(obj1_pos, obj2_pos):
	return dist_between(obj1_pos, obj2_pos) / 5;

func dist_between(obj1_pos, obj2_pos) -> float:
	return sqrt(pow(obj1_pos.x - obj2_pos.x, 2) + pow(obj1_pos.y - obj2_pos.y, 2))
