extends State

func enter():
	player.target_animation = "run"
	player.update_collision_shapes()

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	
	var input_direction = player.get_input_direction()
	var speed = abs(player.velocity.x)
	
	# Проверка условия для торможения
	if (input_direction != 0 and 
		sign(player.velocity.x) != input_direction and 
		speed > player.min_skid_speed and 
		player.is_on_floor()):
		state_machine.change_state("skid")
		return
	
	if input_direction != 0:
		player.last_direction = input_direction
		
		var target_speed = input_direction * player.max_speed
		
		if sign(player.velocity.x) != 0 and sign(player.velocity.x) != input_direction:
			player.velocity.x = move_toward(player.velocity.x, target_speed, player.braking_deceleration * delta)
		else:
			if abs(player.velocity.x) < player.max_speed or sign(player.velocity.x) != input_direction:
				player.velocity.x = move_toward(player.velocity.x, target_speed, player.acceleration * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta)
		if abs(player.velocity.x) < 10:
			state_machine.change_state("idle")
			return
	
	# Переход в roll только при НАЖАТИИ look_down и достаточной скорости
	if speed > 100 and Input.is_action_just_pressed("look_down") and player.is_on_floor():
		state_machine.change_state("roll")
		return
	
	if not player.is_on_floor():
		# Если персонаж в воздухе, меняем анимацию на "fall"
		player.target_animation = "fall"
		player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta * 0.5)
		return
	
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_force
		player.jump_time_remaining = player.max_jump_time
		state_machine.change_state("jump")
		return
		
	# Переход в crouch только при УДЕРЖАНИИ look_down и низкой скорости
	if Input.is_action_pressed("look_down") and abs(player.velocity.x) < 50:
		state_machine.change_state("crouch")
		return
 
	if Input.is_action_just_pressed("boost") and player.has_method("can_use_boost") and player.can_use_boost():
		player.apply_boost()

	player.sprite.flip_h = player.last_direction < 0
	player.update_collision_shapes()
