extends StaticBody2D

var wait_time
var time_left

	
func _process(_delta):
	# Opacity from 0 to 1 whe spawning
	if not $SpawnTime.is_stopped():
		wait_time = $SpawnTime.get_wait_time()
		modulate.a = (wait_time - $SpawnTime.get_time_left()) / wait_time
	
	# Opacity from 1->0->1 each blink tick based on time left
	if not BlinkTime.is_stopped():
		wait_time = BlinkTime.get_wait_time()
		time_left = BlinkTime.get_time_left()
		if time_left > wait_time / 2:
			modulate.a = 1 + 2 * time_left - 2 * wait_time
		else:
			modulate.a = 1 - time_left * 2


func get_CollisionShape2D():
	return $CollisionShape2D

func get_MeshInstance2D():
	return $MeshInstance2D
