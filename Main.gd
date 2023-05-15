extends Node2D

@export var object_scene: PackedScene

var wanted_color
var score = 0
var pl_is_oob
var oobt_is_playing
var vp_size


func _ready():
	$Enemy.set_physics_process(false)
	DeathTimer.timeout.connect(_on_DeathTimer_timeout)
	BlinkTimer.timeout.connect(_on_BlinkTimer_timeout)
	$HUD/ScoreLabel.hide()
	$Player.initialize(Enum.BeingState.DEAD)

func _physics_process(delta):
	if vp_size != Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y):
		vp_size = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y)
	
	$Enemy.set_target($Player)
	
	# If player is out of bounds, he will lose after the timer's timeout
	if $Player.is_dead:
		return
	pl_is_oob = $Player.is_out_of_bounds(vp_size)
	oobt_is_playing = not $OOBTimer.is_stopped()
	if pl_is_oob:
		if not oobt_is_playing:
			$Sound/AlertSoundOOB.play()
			$OOBTimer.start()
		background_beat()
	elif not pl_is_oob and oobt_is_playing:
		$Background.color = Color(0.29411765933037, 0.29411765933037, 0.29411765933037)
		$Sound/AlertSoundOOB.stop()
		$OOBTimer.stop()
	
func _process(delta):
	if $Background.size != vp_size:
		$Background.set_size(vp_size, false)
	if $HUD.size != vp_size:
		$HUD.set_size(vp_size, false)


func init_new_round():
	BlinkTime.stop()
	if not get_tree().get_nodes_in_group("objects").is_empty():
		get_tree().call_group("objects", "queue_free")
	init_round_essentials()
	spawn_objects_range()
	$HUD.move_to_front()
	DeathTimer.paused = false
	BlinkTimer.paused = false
	DeathTimer.start()
	set_BlinkTimer_wtime()
	BlinkTimer.start()
	spawn_enemy()

func game_over():
	$Enemy.hide()
	$Enemy.set_physics_process(false)
	$Background.color = Color(0.29411765933037, 0.29411765933037, 0.29411765933037)
	$Sound/GameOverSound.play()
	DeathTimer.paused = true
	BlinkTimer.paused = true
	if not get_tree().get_nodes_in_group("objects").is_empty():
		get_tree().call_group("objects", "queue_free")
	$Player.initialize(Enum.BeingState.DEAD)
	$HUD/Text.text = "Game Over!"
	$HUD/Text.show()
	$HUD/StartGame.show()

func _on_start_game_pressed():
	score = 0
	$HUD/ScoreLabel.text = "Score: %s" % score
	$HUD/ScoreLabel.show()
	$HUD/Text.hide()
	$HUD/StartGame.hide()
	$Player.initialize(Enum.BeingState.ALIVE)
	init_new_round()

func def_queue_free(node):
	get_tree().call_group(node, "queue_free")

func init_round_essentials():
	wanted_color = get_rand_colored_grad()
	$Player/MeshInstance2D.texture.get_gradient().set_color(0, wanted_color.get_color(0))
	instantiate_object(wanted_color)

func get_acceptable_pos(val):
	# Repeatedly find the new position while the object is too close to other entities
	# val -> farthest point on the object from the object's center (It doesn't have to be)
	var rand_pos
	while(true):
		rand_pos = Vector2(randi_range(val, get_viewport_rect().size.x - val), 
			randi_range(val, get_viewport_rect().size.y - val))
		if not is_near_player(val, rand_pos) and not is_near_other_obj(val, rand_pos) and not is_near_score_label(val, rand_pos):
			return rand_pos

func spawn_enemy():
	# 16 represents an offset off the screen so that the enemy doesn't spawn half way visible
	if $EnemyPath.curve.get_point_position(1) != Vector2(vp_size.x + 16, -16):
		$EnemyPath.curve.set_point_position(1, Vector2(vp_size.x + 16, -16))
	if $EnemyPath.curve.get_point_position(2) != Vector2(vp_size.x + 16, vp_size.y + 16):
		$EnemyPath.curve.set_point_position(2, Vector2(vp_size.x + 16, vp_size.y + 16))
	if $EnemyPath.curve.get_point_position(3) != Vector2(-16, vp_size.y + 16):
		$EnemyPath.curve.set_point_position(3, Vector2(-16, vp_size.y + 16))
	
	$EnemyPath/EnemySpawnLocation.progress_ratio = randi()
	$Enemy.global_position = $EnemyPath/EnemySpawnLocation.global_position
	$Enemy.show()
	if not $Enemy.is_physics_processing():
		$Enemy.set_physics_process(true)

func spawn_objects_range():
	var tmp = vp_size.x + vp_size.y
	for i in range(randi_range(tmp / 100, tmp / 25)):
		instantiate_object(get_rand_colored_grad())

func instantiate_object(gradient):
	var obj = object_scene.instantiate()
	obj.get_MeshInstance2D().texture.diffuse_texture.set_gradient(gradient)
	obj.position = get_acceptable_pos(obj.get_CollisionShape2D().shape.radius)
	add_child(obj)

func is_near_player(obj_length, rand_obj_pos):
	# Distance between the coordinates compared to the addition of 
	# player' diagonal/radius and object' diagonal/radius
	if (sqrt(pow(rand_obj_pos.x - $Player.position.x, 2) + 
		pow(rand_obj_pos.y - $Player.position.y, 2)) > 
		($Player/CollisionShape2D.shape.radius + obj_length) * 2):
		return false
	return true

func is_near_other_obj(obj_length, rand_obj_pos):
	# Distance between the coordinates compared to the addition of objects's diagonals/radii
	for obj in get_tree().get_nodes_in_group("objects"):
		if (sqrt(pow(obj.position.x - rand_obj_pos.x, 2) + 
			pow(obj.position.y - rand_obj_pos.y, 2)) <=
			(obj.get_CollisionShape2D().shape.radius + obj_length ) * 2):
			return true
	return false

func is_near_score_label(obj_length, rand_obj_pos):
	# Distance between the coordinates compared to the addition of objects's diagonals/radii
	if (sqrt(pow(rand_obj_pos.x - $HUD/ScoreLabel.position.x, 2) + 
		pow(rand_obj_pos.y - $HUD/ScoreLabel.position.y, 2)) > 
		(sqrt(pow($HUD/ScoreLabel.size.x / 2, 2) + pow($HUD/ScoreLabel.size.y / 2, 2)) + 
		obj_length) * 2):
		return false
	return true

func get_rand_color():
	return Color(randf_range(0, 1), randf_range(0, 1), randf_range(0, 1))

func get_rand_color_1():
	return Color(randf_range(0, 1), randf_range(0, 1), randf_range(0, 1), 1)

func get_rand_colored_grad():
	var tmp_color = get_rand_color_1()
	var gradient = Gradient.new()
	gradient.set_offset(1, 20.0)
	gradient.set_color(0, tmp_color)
	gradient.set_color(1, tmp_color)
	
	return gradient

func _on_player_body_entered(body):
	if body.is_in_group("objects"):
		var gradient = body.get_MeshInstance2D().texture.diffuse_texture.gradient
		var color_is_correct = wanted_color.get_color(1) == gradient.get_color(1)
		
		if color_is_correct:
			$Sound/CorrTouchSound.play()
			score += 1
			$HUD/ScoreLabel.text = "Score: %s" % score
			init_new_round()
		else:
			game_over()
	elif body.is_in_group("enemies"):
		game_over()

func background_beat():
	$Background.color.v = $OOBTimer.get_time_left() / $OOBTimer.get_wait_time()
		
func get_color(val):
	match val:
		0: return Color(255, 0, 0, 1)
		1: return Color(0, 255, 0, 1)
		2: return Color(0, 0, 255, 1)

func get_color_shade(val):
	match val:
		0: return Color(Color.RED, 1)
		1: return Color(Color.GREEN, 1)
		2: return Color(Color.BLUE, 1)
	
func _on_DeathTimer_timeout():
	game_over()

func _on_BlinkTimer_timeout():
	$Sound/AlertSound.play()
	set_BlinkTimer_wtime()
	set_BlinkTime_wtime()
	BlinkTime.start()

func set_BlinkTimer_wtime():
	BlinkTimer.wait_time = max(0.145, DeathTimer.get_time_left() / 10)


func set_BlinkTime_wtime():
	BlinkTime.wait_time = max(0.145, BlinkTimer.get_wait_time() / 2)

func _on_oob_timer_timeout():
	if $Sound/AlertSoundOOB.is_playing():
		$Sound/AlertSoundOOB.stop()
	game_over()
